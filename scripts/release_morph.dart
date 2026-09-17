import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:crypto/crypto.dart';
import 'package:dart_style/dart_style.dart';

final _dartFormatter = DartFormatter(
  languageVersion: DartFormatter.latestLanguageVersion,
);

void main(List<String> args) async {
  final options = MorphOptions.parse(args);
  if (options.showHelp) {
    stdout.write(MorphOptions.usage);
    return;
  }

  final root = Directory(options.root);
  if (!root.existsSync()) {
    stderr.writeln('Error: root does not exist: ${options.root}');
    exitCode = 1;
    return;
  }

  final stats = MorphStats();
  final manifest = MorphManifest(
    root: root.absolute.path,
    seed: options.seed,
    intensity: options.intensity.name,
    anchorsPerFile: options.anchorsPerFile,
    touchesPerFunction: options.touchesPerFunction,
    reshapeLevel: options.reshapeLevel,
    reshapeProfile: options.reshapeProfile.name,
    variantEnabled: options.variantEnabled,
    touchEnabled: options.touchEnabled,
    dryRun: options.dryRun,
  );

  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.dart'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final pendingWrites = <_PendingWrite>[];
  final effectiveTouchEnabled = options.touchEnabled && options.variantEnabled;
  if (options.touchEnabled && !options.variantEnabled) {
    stderr.writeln(
      'Warning: --no-variant also disables touch injection because '
      'ReleaseVariant is required.',
    );
  }

  for (final file in files) {
    final relativePath = _relativePath(file.path);
    final logicalPath = _logicalPath(root, file);
    final pathSkipReason = _skipReasonForPath(logicalPath);
    if (pathSkipReason != null) {
      stats.skipped++;
      manifest.skipped.add(
        MorphSkippedFile(path: relativePath, reason: pathSkipReason),
      );
      continue;
    }

    final source = await file.readAsString();
    final unit = _parseUnitOrThrow(source, relativePath);
    if (unit.directives.any((directive) => directive is PartOfDirective)) {
      stats.skipped++;
      manifest.skipped.add(
        MorphSkippedFile(path: relativePath, reason: 'part-of-library'),
      );
      continue;
    }

    final beforeHash = _sha256(source);
    final result = morphDartSource(
      source,
      seed: '${options.seed}:$logicalPath',
      path: logicalPath,
      intensity: options.intensity,
      anchorsPerFile: options.anchorsPerFile,
      touchEnabled: effectiveTouchEnabled,
      touchesPerFunction: options.touchesPerFunction,
      reshapeLevel: options.reshapeLevel,
      reshapeProfile: options.reshapeProfile,
    );

    if (result.changed) {
      _parseUnitOrThrow(result.content, '$relativePath (morphed)');
      stats.changed++;
      final afterHash = _sha256(result.content);
      manifest.changed.add(
        MorphFileChange(
          path: relativePath,
          beforeSha256: beforeHash,
          afterSha256: afterHash,
          topLevelCount: result.topLevelCount,
          morphedTypeCount: result.morphedTypeCount,
          anchorCount: result.anchorCount,
          touchCount: result.touchCount,
          touchHelperCount: result.touchHelperCount,
          reshapeHelperCount: result.reshapeHelperCount,
          reshapeLevelUsed: result.reshapeLevelUsed,
          touchesUsed: result.touchesUsed,
          methodGateCount: result.methodGateCount,
          dataMorphCount: result.dataMorphCount,
        ),
      );
      if (options.dryRun) {
        stdout.writeln('DRY changed: $relativePath');
      } else {
        pendingWrites.add(
          _PendingWrite(
            file: file,
            content: result.content,
            label: relativePath,
          ),
        );
      }
    } else {
      stats.unchanged++;
      manifest.unchanged.add(relativePath);
    }
  }

  final totalTouches = manifest.changed.fold<int>(
    0,
    (sum, item) => sum + item.touchCount,
  );
  if (options.variantEnabled && totalTouches > 0) {
    final variantFile = File('${root.path}/release_variant.dart');
    final before = variantFile.existsSync()
        ? await variantFile.readAsString()
        : '';
    final generated = _buildReleaseVariantSource(options.seed);
    _parseUnitOrThrow(generated.content, _relativePath(variantFile.path));
    final changed = before != generated.content;
    manifest.variant = GeneratedVariantChange(
      path: _relativePath(variantFile.path),
      changed: changed,
      beforeSha256: _sha256(before),
      afterSha256: _sha256(generated.content),
      wrapperCount: generated.wrapperCount,
    );
    if (changed) {
      if (options.dryRun) {
        stdout.writeln('DRY generated: ${_relativePath(variantFile.path)}');
      } else {
        pendingWrites.add(
          _PendingWrite(
            file: variantFile,
            content: generated.content,
            label: _relativePath(variantFile.path),
          ),
        );
      }
    }
  }

  // No source file is written until every transformed unit has parsed cleanly.
  for (final pending in pendingWrites) {
    await pending.file.writeAsString(pending.content);
    stdout.writeln('changed: ${pending.label}');
  }

  if (options.manifestPath != null) {
    final manifestFile = File(options.manifestPath!);
    manifestFile.createSync(recursive: true);
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
    );
    stdout.writeln('manifest: ${manifestFile.path}');
  }

  stdout.writeln(
    'release_morph complete: changed=${stats.changed}, '
    'unchanged=${stats.unchanged}, skipped=${stats.skipped}, '
    'dryRun=${options.dryRun}, intensity=${options.intensity.name}',
  );
}

MorphResult morphDartSource(
  String source, {
  required String seed,
  required String path,
  required MorphIntensity intensity,
  required int anchorsPerFile,
  required bool touchEnabled,
  required int touchesPerFunction,
  required int reshapeLevel,
  required ReshapeProfile reshapeProfile,
}) {
  final sourceWithoutAnchors = _stripMorphTouchHelpers(
    _stripMorphTouches(_stripMorphAnchors(source)),
  );
  final unit = _parseUnitOrThrow(sourceWithoutAnchors, path);
  if (unit.declarations.length < 2 &&
      unit.declarations.whereType<ClassDeclaration>().isEmpty &&
      unit.declarations.whereType<MixinDeclaration>().isEmpty &&
      anchorsPerFile == 0) {
    return MorphResult(
      sourceWithoutAnchors,
      changed: sourceWithoutAnchors != source,
    );
  }

  final morpher = _SourceMorpher(
    source: sourceWithoutAnchors,
    seed: seed,
    path: path,
    intensity: intensity,
    anchorsPerFile: _canInjectAnchors(unit) ? anchorsPerFile : 0,
    touchEnabled:
        touchEnabled &&
        touchesPerFunction > 0 &&
        _canInjectTouches(path, unit, intensity),
    touchesPerFunction: touchesPerFunction,
    reshapeLevel: reshapeLevel,
    reshapeProfile: reshapeProfile,
  );
  final result = morpher.morph(unit);
  final formattedContent = result.changed
      ? _dartFormatter.format(result.content, uri: path)
      : result.content;
  return MorphResult(
    formattedContent,
    changed: formattedContent != source,
    topLevelCount: result.topLevelCount,
    morphedTypeCount: result.morphedTypeCount,
    anchorCount: result.anchorCount,
    touchCount: result.touchCount,
    touchHelperCount: result.touchHelperCount,
    reshapeHelperCount: result.reshapeHelperCount,
    reshapeLevelUsed: result.reshapeLevelUsed,
    touchesUsed: result.touchesUsed,
    methodGateCount: result.methodGateCount,
    dataMorphCount: result.dataMorphCount,
  );
}

class MorphOptions {
  const MorphOptions({
    required this.root,
    required this.seed,
    required this.intensity,
    required this.anchorsPerFile,
    required this.touchesPerFunction,
    required this.reshapeLevel,
    required this.reshapeProfile,
    required this.variantEnabled,
    required this.touchEnabled,
    required this.dryRun,
    required this.includeMain,
    required this.manifestPath,
    required this.showHelp,
  });

  static const usage = '''
Usage: dart run scripts/release_morph.dart [options]

Deterministically reshuffles safe Dart declaration order before release builds.
It is intended to be run after scripts/generate_all.dart --release.

Options:
  --root <path>         Dart source root to process. Defaults to lib.
  --seed <value>        Stable seed used for deterministic morph output.
  --intensity <mode>    light, standard, or deep. Defaults to standard.
  --anchors <count>     Entry-point anchor functions per file. Defaults: light=0, standard=0, deep=32.
  --touches <count>     Touch call sites per instrumented function. Defaults: light=0, standard=0, deep=3.
  --reshape <level>     Touch helper wrapper/dispatch depth. Defaults: light=0, standard=0, deep=1.
  --reshape-profile <mode>
                         Reshape distribution: flat, tiered, cold-heavy. Defaults to flat.
  --no-anchors          Disable anchor injection.
  --no-variant          Disable generated startup variant dispatch.
  --no-touch            Disable method-level ReleaseVariant.touch injection.
  --manifest <path>     Write JSON manifest with changed files and hashes.
  --include-main        Retained for compatibility; lib/main.dart is included.
  --dry-run             Print changed files without writing.
  --help, -h            Show this help.
''';

  final String root;
  final String seed;
  final MorphIntensity intensity;
  final int anchorsPerFile;
  final int touchesPerFunction;
  final int reshapeLevel;
  final ReshapeProfile reshapeProfile;
  final bool variantEnabled;
  final bool touchEnabled;
  final bool dryRun;
  final bool includeMain;
  final String? manifestPath;
  final bool showHelp;

  static MorphOptions parse(List<String> args) {
    var root = 'lib';
    var seed = 'siren-release';
    var intensity = MorphIntensity.standard;
    int? anchorsPerFile;
    int? touchesPerFunction;
    int? reshapeLevel;
    var reshapeProfile = ReshapeProfile.flat;
    var variantEnabled = true;
    var touchEnabled = true;
    var dryRun = false;
    var includeMain = true;
    String? manifestPath;
    var showHelp = false;

    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--root':
          root = _readValue(args, ++i, '--root');
        case '--seed':
          seed = _readValue(args, ++i, '--seed');
        case '--intensity':
          intensity = MorphIntensity.parse(
            _readValue(args, ++i, '--intensity'),
          );
        case '--anchors':
          anchorsPerFile = int.parse(_readValue(args, ++i, '--anchors'));
          if (anchorsPerFile < 0) {
            throw ArgumentError('--anchors must be >= 0');
          }
        case '--touches':
          touchesPerFunction = int.parse(_readValue(args, ++i, '--touches'));
          if (touchesPerFunction < 0) {
            throw ArgumentError('--touches must be >= 0');
          }
        case '--reshape':
          reshapeLevel = int.parse(_readValue(args, ++i, '--reshape'));
          if (reshapeLevel < 0) {
            throw ArgumentError('--reshape must be >= 0');
          }
        case '--reshape-profile':
          reshapeProfile = ReshapeProfile.parse(
            _readValue(args, ++i, '--reshape-profile'),
          );
        case '--no-anchors':
          anchorsPerFile = 0;
        case '--no-variant':
          variantEnabled = false;
        case '--no-touch':
          touchEnabled = false;
          touchesPerFunction = 0;
        case '--manifest':
          manifestPath = _readValue(args, ++i, '--manifest');
        case '--include-main':
          includeMain = true;
        case '--dry-run':
          dryRun = true;
        case '--help':
        case '-h':
          showHelp = true;
        default:
          throw ArgumentError('Unknown option: $arg');
      }
    }

    return MorphOptions(
      root: root,
      seed: seed,
      intensity: intensity,
      anchorsPerFile: anchorsPerFile ?? intensity.defaultAnchorsPerFile,
      touchesPerFunction:
          touchesPerFunction ?? intensity.defaultTouchesPerFunction,
      reshapeLevel: reshapeLevel ?? intensity.defaultReshapeLevel,
      reshapeProfile: reshapeProfile,
      variantEnabled: variantEnabled,
      touchEnabled: touchEnabled,
      dryRun: dryRun,
      includeMain: includeMain,
      manifestPath: manifestPath,
      showHelp: showHelp,
    );
  }

  static String _readValue(List<String> args, int index, String flag) {
    if (index >= args.length) {
      throw ArgumentError('Missing value for $flag');
    }
    return args[index];
  }
}

enum MorphIntensity {
  light,
  standard,
  deep;

  int get defaultAnchorsPerFile => switch (this) {
    MorphIntensity.light => 0,
    MorphIntensity.standard => 0,
    MorphIntensity.deep => 32,
  };

  int get defaultTouchesPerFunction => switch (this) {
    MorphIntensity.light => 0,
    MorphIntensity.standard => 0,
    MorphIntensity.deep => 3,
  };

  int get defaultReshapeLevel => switch (this) {
    MorphIntensity.light => 0,
    MorphIntensity.standard => 0,
    MorphIntensity.deep => 1,
  };

  static MorphIntensity parse(String value) {
    for (final item in MorphIntensity.values) {
      if (item.name == value) return item;
    }
    throw ArgumentError('Unknown intensity: $value');
  }
}

enum ReshapeProfile {
  flat,
  tiered,
  coldHeavy;

  static ReshapeProfile parse(String value) {
    final normalized = value.replaceAll('_', '-');
    for (final item in ReshapeProfile.values) {
      if (item.name == value || _kebabName(item.name) == normalized) {
        return item;
      }
    }
    throw ArgumentError('Unknown reshape profile: $value');
  }
}

class MorphStats {
  int changed = 0;
  int unchanged = 0;
  int skipped = 0;
}

class _PendingWrite {
  const _PendingWrite({
    required this.file,
    required this.content,
    required this.label,
  });

  final File file;
  final String content;
  final String label;
}

class MorphResult {
  const MorphResult(
    this.content, {
    required this.changed,
    this.topLevelCount = 0,
    this.morphedTypeCount = 0,
    this.anchorCount = 0,
    this.touchCount = 0,
    this.touchHelperCount = 0,
    this.reshapeHelperCount = 0,
    this.reshapeLevelUsed = 0,
    this.touchesUsed = 0,
    this.methodGateCount = 0,
    this.dataMorphCount = 0,
  });

  final String content;
  final bool changed;
  final int topLevelCount;
  final int morphedTypeCount;
  final int anchorCount;
  final int touchCount;
  final int touchHelperCount;
  final int reshapeHelperCount;
  final int reshapeLevelUsed;
  final int touchesUsed;
  final int methodGateCount;
  final int dataMorphCount;
}

class MorphManifest {
  MorphManifest({
    required this.root,
    required this.seed,
    required this.intensity,
    required this.anchorsPerFile,
    required this.touchesPerFunction,
    required this.reshapeLevel,
    required this.reshapeProfile,
    required this.variantEnabled,
    required this.touchEnabled,
    required this.dryRun,
  });

  final String root;
  final String seed;
  final String intensity;
  final int anchorsPerFile;
  final int touchesPerFunction;
  final int reshapeLevel;
  final String reshapeProfile;
  final bool variantEnabled;
  final bool touchEnabled;
  final bool dryRun;
  final List<MorphFileChange> changed = [];
  final List<String> unchanged = [];
  final List<MorphSkippedFile> skipped = [];
  GeneratedVariantChange? variant;

  Map<String, Object> toJson() => {
    'root': root,
    'seed': seed,
    'intensity': intensity,
    'anchorsPerFile': anchorsPerFile,
    'touchesPerFunction': touchesPerFunction,
    'reshapeLevel': reshapeLevel,
    'reshapeProfile': reshapeProfile,
    'variantEnabled': variantEnabled,
    'touchEnabled': touchEnabled,
    if (variant != null) 'variant': variant!.toJson(),
    'anchorCount': changed.fold<int>(0, (sum, item) => sum + item.anchorCount),
    'touchCount': changed.fold<int>(0, (sum, item) => sum + item.touchCount),
    'touchHelperCount': changed.fold<int>(
      0,
      (sum, item) => sum + item.touchHelperCount,
    ),
    'reshapeHelperCount': changed.fold<int>(
      0,
      (sum, item) => sum + item.reshapeHelperCount,
    ),
    'methodGateCount': changed.fold<int>(
      0,
      (sum, item) => sum + item.methodGateCount,
    ),
    'dataMorphCount': changed.fold<int>(
      0,
      (sum, item) => sum + item.dataMorphCount,
    ),
    'dryRun': dryRun,
    'changedCount': changed.length,
    'unchangedCount': unchanged.length,
    'skippedCount': skipped.length,
    'changed': changed.map((item) => item.toJson()).toList(),
    'unchanged': unchanged,
    'skipped': skipped.map((item) => item.toJson()).toList(),
  };
}

class MorphSkippedFile {
  const MorphSkippedFile({required this.path, required this.reason});

  final String path;
  final String reason;

  Map<String, String> toJson() => {'path': path, 'reason': reason};
}

class MorphFileChange {
  const MorphFileChange({
    required this.path,
    required this.beforeSha256,
    required this.afterSha256,
    required this.topLevelCount,
    required this.morphedTypeCount,
    required this.anchorCount,
    required this.touchCount,
    required this.touchHelperCount,
    required this.reshapeHelperCount,
    required this.reshapeLevelUsed,
    required this.touchesUsed,
    required this.methodGateCount,
    required this.dataMorphCount,
  });

  final String path;
  final String beforeSha256;
  final String afterSha256;
  final int topLevelCount;
  final int morphedTypeCount;
  final int anchorCount;
  final int touchCount;
  final int touchHelperCount;
  final int reshapeHelperCount;
  final int reshapeLevelUsed;
  final int touchesUsed;
  final int methodGateCount;
  final int dataMorphCount;

  Map<String, Object> toJson() => {
    'path': path,
    'beforeSha256': beforeSha256,
    'afterSha256': afterSha256,
    'topLevelCount': topLevelCount,
    'morphedTypeCount': morphedTypeCount,
    'anchorCount': anchorCount,
    'touchCount': touchCount,
    'touchHelperCount': touchHelperCount,
    'reshapeHelperCount': reshapeHelperCount,
    'reshapeLevelUsed': reshapeLevelUsed,
    'touchesUsed': touchesUsed,
    'methodGateCount': methodGateCount,
    'dataMorphCount': dataMorphCount,
  };
}

class GeneratedVariantChange {
  const GeneratedVariantChange({
    required this.path,
    required this.changed,
    required this.beforeSha256,
    required this.afterSha256,
    required this.wrapperCount,
  });

  final String path;
  final bool changed;
  final String beforeSha256;
  final String afterSha256;
  final int wrapperCount;

  Map<String, Object> toJson() => {
    'path': path,
    'changed': changed,
    'beforeSha256': beforeSha256,
    'afterSha256': afterSha256,
    'wrapperCount': wrapperCount,
  };
}

class _VariantSource {
  const _VariantSource({required this.content, required this.wrapperCount});

  final String content;
  final int wrapperCount;
}

_VariantSource _buildReleaseVariantSource(String seed) {
  final localSeed = '$seed:release-variant';
  final fileKey = _hexDigest(localSeed).substring(0, 10);
  final wrapperCount = 5 + (_hashSeed('$localSeed:wrappers') % 5);
  final wrappers = List.generate(wrapperCount, (index) {
    final name = '_rv${fileKey}Wrap$index';
    final mask = 1 << (index % 9);
    final saltA = _hashSeed('$localSeed:wrapper:$index:a') | 1;
    final saltB = _hashSeed('$localSeed:wrapper:$index:b') | 1;
    return '''
  @pragma('vm:entry-point')
  @pragma('vm:never-inline')
  static int $name(int state) {
    var mixed = _rv${fileKey}Mix(state ^ $saltA, $saltB);
    if ((mixed & $mask) == 0) {
      mixed = _rv${fileKey}Mix(mixed, $saltB);
    } else {
      mixed = (mixed ^ $saltB) & 0x3fffffff;
    }
    return _rv${fileKey}Mix(mixed, $saltA);
  }
''';
  }).join('\n');

  final bootSalt = _hashSeed('$localSeed:boot') | 1;
  final dataSalt = _hashSeed('$localSeed:data') | 1;
  final serviceSalt = _hashSeed('$localSeed:service') | 1;
  final touchWrapper =
      '_rv${fileKey}Wrap${_hashSeed('$localSeed:touch-wrapper') % wrapperCount}';

  final content =
      '''
// GENERATED RELEASE MORPH VARIANT. DO NOT EDIT.

class ReleaseVariant {
  ReleaseVariant._();

  static int _sink = $bootSalt;

  @pragma('vm:entry-point')
  @pragma('vm:never-inline')
  static int touch(int salt) {
    var mixed = _rv${fileKey}Mix(_sink, salt ^ $serviceSalt);
    if ((mixed & ${1 << (_hashSeed('$localSeed:touch-mask') % 8)}) == 0) {
      mixed = $touchWrapper(mixed);
    } else {
      mixed = _rv${fileKey}Mix(mixed, $bootSalt);
    }
    _sink = (mixed ^ $dataSalt) & 0x3fffffff;
    return _sink;
  }

$wrappers
  static int _rv${fileKey}Mix(int left, int right) {
    var value = (left ^ right ^ $dataSalt) & 0x3fffffff;
    value = ((value << ${5 + (_hashSeed('$localSeed:shift') % 5)}) ^ (value >> 3) ^ $serviceSalt) & 0x3fffffff;
    return value;
  }
}
''';

  return _VariantSource(content: content, wrapperCount: wrapperCount);
}

class _SourceMorpher {
  _SourceMorpher({
    required this.source,
    required this.seed,
    required this.path,
    required this.intensity,
    required this.anchorsPerFile,
    required this.touchEnabled,
    required this.touchesPerFunction,
    required this.reshapeLevel,
    required this.reshapeProfile,
  });

  final String source;
  final String seed;
  final String path;
  final MorphIntensity intensity;
  final int anchorsPerFile;
  final bool touchEnabled;
  final int touchesPerFunction;
  final int reshapeLevel;
  final ReshapeProfile reshapeProfile;
  int _touchCount = 0;
  int _reshapeHelperCount = 0;
  int _methodGateCount = 0;
  int _dataMorphCount = 0;
  final List<String> _touchHelpers = [];

  int get _effectiveReshapeLevel =>
      _reshapeLevelForPath(path, reshapeLevel, reshapeProfile);

  int get _effectiveTouchesPerFunction =>
      _touchesForPath(path, touchesPerFunction, reshapeProfile);

  MorphResult morph(CompilationUnit unit) {
    final declarations = unit.declarations
        .map((node) => _TopLevelDeclaration.fromNode(source, node))
        .toList();

    if (declarations.isEmpty) {
      return MorphResult(source, changed: false);
    }

    final prefixEnd = unit.directives.isNotEmpty
        ? unit.directives.first.offset
        : declarations.first.offset;
    final prefix = source.substring(0, prefixEnd).trimRight();

    var morphedTypeCount = 0;
    final morphedDeclarations = <_TopLevelDeclaration>[];
    for (final declaration in declarations) {
      final morphed = _morphDeclaration(declaration);
      if (morphed.content != declaration.content) {
        morphedTypeCount++;
      }
      morphedDeclarations.add(morphed);
    }

    if (intensity != MorphIntensity.light) {
      _sortStable(
        morphedDeclarations,
        '$seed:top-level',
        (item) => item.sortKey,
      );
    }

    final anchors = _generateAnchors();
    if (_touchHelpers.isNotEmpty) {
      _touchHelpers.sort();
      morphedDeclarations.add(
        _TopLevelDeclaration.synthetic(
          content:
              '// BEGIN RELEASE MORPH TOUCH HELPERS\n'
              '${_touchHelpers.join('\n\n')}\n'
              '// END RELEASE MORPH TOUCH HELPERS',
        ),
      );
    }
    if (anchors.isNotEmpty) {
      morphedDeclarations.add(
        _TopLevelDeclaration.synthetic(
          content:
              '// BEGIN RELEASE MORPH ANCHORS\n'
              '${anchors.join('\n\n')}\n'
              '// END RELEASE MORPH ANCHORS',
        ),
      );
    }

    final buffer = StringBuffer();
    if (prefix.isNotEmpty) {
      buffer.writeln(prefix);
      buffer.writeln();
    }

    final directives = _directivesFor(
      unit,
      includeTouchImport: _touchCount > 0,
      path: path,
    );
    if (directives.isNotEmpty) {
      buffer.writeln(directives.join('\n'));
      buffer.writeln();
    }

    for (var i = 0; i < morphedDeclarations.length; i++) {
      buffer.write(morphedDeclarations[i].content.trimRight());
      buffer.writeln();
      if (i < morphedDeclarations.length - 1) {
        buffer.writeln();
      }
    }

    final content = buffer.toString();
    return MorphResult(
      content,
      changed: content != source,
      topLevelCount: declarations.length,
      morphedTypeCount: morphedTypeCount,
      anchorCount: anchors.length,
      touchCount: _touchCount,
      touchHelperCount: _touchHelpers.length,
      reshapeHelperCount: _reshapeHelperCount,
      reshapeLevelUsed: _effectiveReshapeLevel,
      touchesUsed: _effectiveTouchesPerFunction,
      methodGateCount: _methodGateCount,
      dataMorphCount: _dataMorphCount,
    );
  }

  _TopLevelDeclaration _morphDeclaration(_TopLevelDeclaration declaration) {
    final node = declaration.node;
    if (node is ClassDeclaration) {
      return declaration.copyWith(content: _morphClass(node, declaration));
    }
    if (node is MixinDeclaration) {
      return declaration.copyWith(content: _morphMixin(node, declaration));
    }
    if (node is ExtensionDeclaration) {
      return declaration.copyWith(content: _morphExtension(node, declaration));
    }
    if (node is FunctionDeclaration) {
      return declaration.copyWith(
        content: _morphFunction(node, declaration.content),
      );
    }
    return declaration;
  }

  String _morphFunction(FunctionDeclaration node, String content) {
    if (!_shouldInstrumentFunction(node.name.lexeme)) return content;
    return _injectTouch(
      content,
      absoluteOffset: node.offset,
      body: node.functionExpression.body,
      localSeed: '$seed:function:${node.name.lexeme}',
    );
  }

  String _morphClass(ClassDeclaration node, _TopLevelDeclaration declaration) {
    final body = node.body;
    if (body is! BlockClassBody) return declaration.content;
    final name = node.namePart.typeName.lexeme;
    final header = source.substring(declaration.offset, body.leftBracket.end);
    final members = body.members
        .map(
          (member) => _MemberDeclaration.fromNode(
            source,
            member,
            instrument: _instrumentMember(member, '$seed:class:$name'),
          ),
        )
        .toList();
    return _writeTypeBody(header, members, '$seed:class:$name');
  }

  String _morphMixin(MixinDeclaration node, _TopLevelDeclaration declaration) {
    final body = node.body;
    if (body is! BlockClassBody) return declaration.content;
    final header = source.substring(declaration.offset, body.leftBracket.end);
    final members = body.members
        .map(
          (member) => _MemberDeclaration.fromNode(
            source,
            member,
            instrument: _instrumentMember(
              member,
              '$seed:mixin:${node.name.lexeme}',
            ),
          ),
        )
        .toList();
    return _writeTypeBody(header, members, '$seed:mixin:${node.name.lexeme}');
  }

  String _morphExtension(
    ExtensionDeclaration node,
    _TopLevelDeclaration declaration,
  ) {
    final body = node.body;
    if (body is! BlockClassBody) return declaration.content;
    final header = source.substring(declaration.offset, body.leftBracket.end);
    final name = node.name?.lexeme ?? declaration.offset.toString();
    final members = body.members
        .map(
          (member) => _MemberDeclaration.fromNode(
            source,
            member,
            instrument: _instrumentMember(member, '$seed:extension:$name'),
          ),
        )
        .toList();
    return _writeTypeBody(header, members, '$seed:extension:$name');
  }

  String _writeTypeBody(
    String header,
    List<_MemberDeclaration> members,
    String localSeed,
  ) {
    final staticMethods = members
        .where((member) => member.isStatic && member.kind == _MemberKind.method)
        .toList();
    final instanceMethods = members
        .where(
          (member) => !member.isStatic && member.kind == _MemberKind.method,
        )
        .toList();
    _sortStable(
      staticMethods,
      '$localSeed:static-methods',
      (item) => item.sortKey,
    );
    _sortStable(
      instanceMethods,
      '$localSeed:instance-methods',
      (item) => item.sortKey,
    );

    var staticMethodIndex = 0;
    var instanceMethodIndex = 0;
    final ordered = members.map((member) {
      if (member.kind != _MemberKind.method) return member;
      if (member.isStatic) return staticMethods[staticMethodIndex++];
      return instanceMethods[instanceMethodIndex++];
    }).toList();

    final buffer = StringBuffer()..writeln(header.trimRight());
    for (var i = 0; i < ordered.length; i++) {
      final member = ordered[i].content.trimRight();
      if (member.isNotEmpty) {
        buffer.writeln(_indent(member));
      }
      if (i < ordered.length - 1) {
        buffer.writeln();
      }
    }
    buffer.write('}');
    return buffer.toString();
  }

  List<String> _generateAnchors() {
    if (anchorsPerFile == 0) return const [];

    final fileKey = _hexDigest(seed).substring(0, 12);
    return List.generate(anchorsPerFile, (index) {
      final localSeed = '$seed:anchor:$index';
      final name = '_rm${fileKey}Anchor$index';
      final saltA = _hashSeed('$localSeed:a') | 1;
      final saltB = _hashSeed('$localSeed:b') | 1;
      final saltC = _hashSeed('$localSeed:c') | 1;
      final token = _hexDigest(localSeed);
      final previousCall = index == 0
          ? 'mixed ^= $saltC;'
          : 'mixed ^= _rm${fileKey}Anchor${index - 1}(mixed);';

      return '''
@pragma('vm:entry-point')
int $name(int input) {
  const token = '$token';
  var mixed = (input ^ $saltA) & 0x3fffffff;
  for (var i = 0; i < token.length; i += ${index % 5 + 3}) {
    mixed = ((mixed << 5) ^ (mixed >> 2) ^ token.codeUnitAt(i) ^ $saltB) & 0x3fffffff;
  }
  if ((mixed & ${1 << (index % 8)}) == 0) {
    $previousCall
  } else {
    mixed = (mixed + $saltC) & 0x3fffffff;
  }
  return mixed;
}''';
    });
  }

  String? Function(String content) _instrumentMember(
    ClassMember member,
    String ownerSeed,
  ) {
    if (!touchEnabled || member is! MethodDeclaration) return (_) => null;
    if (!_shouldInstrumentFunction(member.name.lexeme)) return (_) => null;
    if (member.isGetter || member.isSetter) return (_) => null;

    return (content) => _injectTouch(
      content,
      absoluteOffset: member.offset,
      body: member.body,
      localSeed: '$ownerSeed:method:${member.name.lexeme}',
    );
  }

  String _injectTouch(
    String content, {
    required int absoluteOffset,
    required FunctionBody body,
    required String localSeed,
  }) {
    if (!touchEnabled || body is! BlockFunctionBody) return content;

    final insertAt = body.block.leftBracket.end - absoluteOffset;
    if (insertAt <= 0 || insertAt >= content.length) return content;

    final statements = _touchStatements(localSeed);
    if (statements.isEmpty) return content;

    return '${content.substring(0, insertAt)}\n'
        '    // BEGIN RELEASE MORPH TOUCH\n'
        '$statements'
        '    // END RELEASE MORPH TOUCH\n'
        '${content.substring(insertAt)}';
  }

  String _touchStatements(String localSeed) {
    final effectiveTouches = _effectiveTouchesPerFunction;
    if (effectiveTouches <= 0) return '';

    final helpers = List.generate(
      effectiveTouches,
      (index) => _addTouchHelper('$localSeed:touch:$index'),
    );
    final mask = 1 << (_hashSeed('$localSeed:mask') % 8);

    if (_shouldUseMethodGate()) {
      final gate = _addMethodGate(localSeed, helpers, mask);
      _touchCount += helpers.length;
      return '    $gate();\n';
    }

    final buffer = StringBuffer();

    buffer.writeln('    ${helpers.first}();');
    _touchCount++;

    if (helpers.length >= 2) {
      buffer.writeln('    if ((${helpers[1]}() & $mask) == 0) {');
      buffer.writeln('      ${helpers.last}();');
      buffer.writeln('    }');
      _touchCount += 2;
    }

    for (var i = 2; i < helpers.length - 1; i++) {
      buffer.writeln('    ${helpers[i]}();');
      _touchCount++;
    }

    return buffer.toString();
  }

  bool _shouldUseMethodGate() {
    return _effectiveReshapeLevel >= 2 ||
        (reshapeProfile == ReshapeProfile.coldHeavy && _isColdMorphPath(path));
  }

  String _addMethodGate(String localSeed, List<String> helpers, int mask) {
    final fileKey = _hexDigest(seed).substring(0, 10);
    final gateKey = _hexDigest('$localSeed:gate').substring(0, 12);
    final name = '_rth${fileKey}Gate$gateKey';
    final saltA = _hashSeed('$localSeed:gate:a') | 1;
    final saltB = _hashSeed('$localSeed:gate:b') | 1;
    final token = _hexDigest('$localSeed:gate:token').substring(0, 16);
    final helperLines = StringBuffer();

    if (helpers.length >= 2) {
      helperLines.writeln('  if ((value & $mask) == 0) {');
      helperLines.writeln(
        '    value = (value ^ ${helpers[1]}()) & 0x3fffffff;',
      );
      helperLines.writeln('  } else {');
      helperLines.writeln(
        '    value = (value + ${helpers.last}() + $saltA) & 0x3fffffff;',
      );
      helperLines.writeln('  }');
    }

    for (var i = 2; i < helpers.length - 1; i++) {
      final salt = _hashSeed('$localSeed:gate:step:$i') | 1;
      helperLines.writeln(
        '  value = ((value << ${(i % 4) + 2}) ^ ${helpers[i]}() ^ $salt) & 0x3fffffff;',
      );
    }

    _touchHelpers.add('''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  const token = '$token';
  var value = (${helpers.first}() ^ token.codeUnitAt(0) ^ $saltB) & 0x3fffffff;
$helperLines  for (var i = 1; i < token.length; i += 5) {
    value = (value + token.codeUnitAt(i)) & 0x3fffffff;
  }
  return value;
}''');
    _methodGateCount++;
    _dataMorphCount++;
    return name;
  }

  String _addTouchHelper(String localSeed) {
    final fileKey = _hexDigest(seed).substring(0, 10);
    final helperKey = _hexDigest(localSeed).substring(0, 12);
    final name = '_rth${fileKey}Touch$helperKey';
    final saltA = _hashSeed('$localSeed:a') | 1;
    final saltB = _hashSeed('$localSeed:b') | 1;
    final saltC = _hashSeed('$localSeed:c') | 1;
    final mask = 1 << (_hashSeed('$localSeed:mask') % 8);

    final effectiveReshapeLevel = _effectiveReshapeLevel;
    if (effectiveReshapeLevel > 0) {
      final entryA = _addTouchBridge('$localSeed:bridge:a', saltA, 0);
      final entryB = _addTouchBridge('$localSeed:bridge:b', saltB, 1);
      final entryC = _addTouchBridge('$localSeed:bridge:c', saltC, 2);
      final template = _hashSeed('$localSeed:template') % 4;
      final token = _hexDigest('$localSeed:template:token').substring(0, 18);
      final body = switch (template) {
        0 =>
          '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  var value = $entryA($saltA);
  if ((value & $mask) == 0) {
    value = $entryB(value ^ $saltB);
  } else {
    value = $entryC((value + $saltC) & 0x3fffffff);
  }
  return value;
}''',
        1 =>
          '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  final left = $entryA($saltA);
  final right = $entryB(left ^ $saltB);
  var value = (left + right + $saltC) & 0x3fffffff;
  if (((left ^ right) & $mask) != 0) {
    value = $entryC(value);
  }
  return value;
}''',
        2 =>
          '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  const token = '$token';
  var value = $entryA($saltA ^ token.codeUnitAt(0));
  for (var i = 1; i < token.length; i += 6) {
    value = (value ^ token.codeUnitAt(i) ^ $saltB) & 0x3fffffff;
  }
  return (value & $mask) == 0 ? $entryB(value) : $entryC(value ^ $saltC);
}''',
        _ =>
          '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  var value = $entryA($saltA);
  switch (value & 3) {
    case 0:
      value = $entryB(value ^ $saltB);
      break;
    case 1:
      value = $entryC((value + $saltC) & 0x3fffffff);
      break;
    default:
      value = (value ^ $entryB($saltB) ^ $entryC($saltC)) & 0x3fffffff;
  }
  return value;
}''',
      };
      _touchHelpers.add(body);
      _dataMorphCount++;
      return name;
    }

    final template = _hashSeed('$localSeed:direct-template') % 3;
    final body = switch (template) {
      0 =>
        '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  var value = ReleaseVariant.touch($saltA);
  if ((value & $mask) == 0) {
    value = ReleaseVariant.touch(value ^ $saltB);
  } else {
    value = ReleaseVariant.touch((value + $saltC) & 0x3fffffff);
  }
  return value;
}''',
      1 =>
        '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  final left = ReleaseVariant.touch($saltA);
  final right = ReleaseVariant.touch(left ^ $saltB);
  if (((left + right) & $mask) == 0) {
    return (right ^ $saltC) & 0x3fffffff;
  }
  return ReleaseVariant.touch((left + right + $saltC) & 0x3fffffff);
}''',
      _ =>
        '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $name() {
  var value = ReleaseVariant.touch($saltA);
  switch (value & 3) {
    case 0:
      value = ReleaseVariant.touch(value ^ $saltB);
      break;
    case 1:
      value = (value + $saltC) & 0x3fffffff;
      break;
    default:
      value = ReleaseVariant.touch((value ^ $saltB ^ $saltC) & 0x3fffffff);
  }
  return value;
}''',
    };
    _touchHelpers.add(body);
    return name;
  }

  String _addTouchBridge(String localSeed, int salt, int slot) {
    final fileKey = _hexDigest(seed).substring(0, 10);
    final bridgeKey = _hexDigest(localSeed).substring(0, 12);
    final leafName = '_rth${fileKey}Leaf$bridgeKey';
    final branchMask = 1 << (_hashSeed('$localSeed:mask') % 8);
    final saltA = _hashSeed('$localSeed:a') | 1;
    final saltB = _hashSeed('$localSeed:b') | 1;
    final saltC = _hashSeed('$localSeed:c') | 1;
    final shift = 3 + ((_hashSeed('$localSeed:shift') + slot) % 5);
    final leafTemplate = _hashSeed('$localSeed:leaf-template') % 3;
    final token = _hexDigest('$localSeed:leaf:token').substring(0, 20);
    final leafBody = switch (leafTemplate) {
      0 =>
        '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $leafName(int input) {
  var value = ReleaseVariant.touch((input ^ $saltA ^ $salt) & 0x3fffffff);
  if ((value & $branchMask) == 0) {
    value = ReleaseVariant.touch((value + $saltB) & 0x3fffffff);
  } else {
    value = ((value << $shift) ^ (value >> 2) ^ $saltC) & 0x3fffffff;
  }
  return value;
}''',
      1 =>
        '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $leafName(int input) {
  const token = '$token';
  var value = ReleaseVariant.touch((input + $saltA + token.codeUnitAt(0)) & 0x3fffffff);
  for (var i = ${slot + 1}; i < token.length; i += 7) {
    value = (value ^ token.codeUnitAt(i) ^ $saltB) & 0x3fffffff;
  }
  return ReleaseVariant.touch((value + $saltC) & 0x3fffffff);
}''',
      _ =>
        '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $leafName(int input) {
  final first = ReleaseVariant.touch((input ^ $saltA) & 0x3fffffff);
  final second = (first & $branchMask) == 0
      ? ReleaseVariant.touch(first ^ $saltB)
      : ((first << $shift) ^ $saltC) & 0x3fffffff;
  return (first + second + $salt) & 0x3fffffff;
}''',
    };
    _touchHelpers.add(leafBody);
    _reshapeHelperCount++;
    _dataMorphCount++;

    final effectiveReshapeLevel = _effectiveReshapeLevel;
    if (effectiveReshapeLevel == 1) {
      return leafName;
    }

    var target = leafName;
    for (var depth = 1; depth < effectiveReshapeLevel; depth++) {
      final layerKey = _hexDigest('$localSeed:layer:$depth').substring(0, 12);
      final layerName = '_rth${fileKey}Wrap$layerKey';
      final layerSaltA = _hashSeed('$localSeed:layer:$depth:a') | 1;
      final layerSaltB = _hashSeed('$localSeed:layer:$depth:b') | 1;
      final layerMask = 1 << (_hashSeed('$localSeed:layer:$depth:m') % 8);
      final previous = target;
      final wrapTemplate = _hashSeed('$localSeed:layer:$depth:t') % 2;
      final wrapBody = switch (wrapTemplate) {
        0 =>
          '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $layerName(int input) {
  var mixed = (input + $layerSaltA) & 0x3fffffff;
  if ((mixed & $layerMask) == 0) {
    mixed = (mixed ^ $layerSaltB) & 0x3fffffff;
  }
  return $previous(mixed);
}''',
        _ =>
          '''
@pragma('vm:never-inline')
@pragma('vm:entry-point')
int $layerName(int input) {
  var mixed = (input ^ $layerSaltA) & 0x3fffffff;
  switch (mixed & 3) {
    case 0:
      mixed = (mixed + $layerSaltB) & 0x3fffffff;
      break;
    case 1:
      mixed = (mixed ^ $layerSaltB) & 0x3fffffff;
      break;
    default:
      mixed = ((mixed << 3) ^ $layerSaltA) & 0x3fffffff;
  }
  return $previous(mixed);
}''',
      };
      _touchHelpers.add(wrapBody);
      _reshapeHelperCount++;
      _dataMorphCount++;
      target = layerName;
    }

    return target;
  }
}

class _TopLevelDeclaration {
  const _TopLevelDeclaration({
    required this.offset,
    required this.content,
    required this.sortKey,
    required this.node,
  });

  final int offset;
  final String content;
  final String sortKey;
  final CompilationUnitMember? node;

  static _TopLevelDeclaration fromNode(
    String source,
    CompilationUnitMember node,
  ) {
    return _TopLevelDeclaration(
      offset: node.offset,
      content: source.substring(node.offset, node.end),
      sortKey: _topLevelSortKey(node),
      node: node,
    );
  }

  _TopLevelDeclaration copyWith({required String content}) {
    return _TopLevelDeclaration(
      offset: offset,
      content: content,
      sortKey: sortKey,
      node: node,
    );
  }

  static _TopLevelDeclaration synthetic({required String content}) {
    return _TopLevelDeclaration(
      offset: -1,
      content: content,
      sortKey: content,
      node: null,
    );
  }
}

class _MemberDeclaration {
  const _MemberDeclaration({
    required this.content,
    required this.sortKey,
    required this.kind,
    required this.isStatic,
  });

  final String content;
  final String sortKey;
  final _MemberKind kind;
  final bool isStatic;

  static _MemberDeclaration fromNode(
    String source,
    ClassMember node, {
    required String? Function(String content) instrument,
  }) {
    final content = _sourceForNode(source, node.offset, node.end);
    final instrumented = instrument(content) ?? content;
    return _MemberDeclaration(
      content: _dedentFollowingLines(
        instrumented,
        _columnAtOffset(source, node.offset),
      ),
      sortKey: _memberSortKey(node),
      kind: _memberKindOf(node),
      isStatic: switch (node) {
        FieldDeclaration(:final isStatic) => isStatic,
        MethodDeclaration(:final isStatic) => isStatic,
        _ => false,
      },
    );
  }
}

enum _MemberKind { constructor, field, method, other }

_MemberKind _memberKindOf(ClassMember node) {
  if (node is ConstructorDeclaration) {
    return _MemberKind.constructor;
  }
  if (node is FieldDeclaration) {
    return _MemberKind.field;
  }
  if (node is MethodDeclaration) {
    return _MemberKind.method;
  }
  return _MemberKind.other;
}

String _topLevelSortKey(CompilationUnitMember node) {
  if (node is ClassDeclaration) {
    return 'class:${node.namePart.typeName.lexeme}';
  }
  if (node is ClassTypeAlias) {
    return 'class-alias:${node.name.lexeme}';
  }
  if (node is MixinDeclaration) {
    return 'mixin:${node.name.lexeme}';
  }
  if (node is EnumDeclaration) {
    return 'enum:${node.namePart.typeName.lexeme}';
  }
  if (node is ExtensionDeclaration) {
    return 'extension:${node.name?.lexeme ?? node.toSource()}';
  }
  if (node is FunctionDeclaration) {
    return 'function:${node.name.lexeme}';
  }
  if (node is TopLevelVariableDeclaration) {
    final names = node.variables.variables
        .map((variable) => variable.name.lexeme)
        .join(',');
    return 'top-vars:$names';
  }
  if (node is FunctionTypeAlias) {
    return 'function-type-alias:${node.name.lexeme}';
  }
  if (node is GenericTypeAlias) {
    return 'generic-type-alias:${node.name.lexeme}';
  }
  return '${node.runtimeType}:${node.toSource()}';
}

String _memberSortKey(ClassMember node) {
  if (node is ConstructorDeclaration) {
    final name = node.name?.lexeme ?? '';
    return 'constructor:${node.typeName?.name ?? ''}:$name';
  }
  if (node is FieldDeclaration) {
    final names = node.fields.variables
        .map((variable) => variable.name.lexeme)
        .join(',');
    return '${node.isStatic ? 'static' : 'instance'}-fields:$names';
  }
  if (node is MethodDeclaration) {
    final methodKind = node.isGetter
        ? 'getter'
        : node.isSetter
        ? 'setter'
        : node.isOperator
        ? 'operator'
        : 'method';
    return '${node.isStatic ? 'static' : 'instance'}-$methodKind:${node.name.lexeme}';
  }
  return '${node.runtimeType}:${node.toSource()}';
}

String? _skipReasonForPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized == 'lib/release_variant.dart') return 'release-variant';
  if (normalized.endsWith('.g.dart')) return 'generated-suffix';
  if (normalized.endsWith('.freezed.dart')) return 'generated-suffix';
  if (normalized.startsWith('lib/gen/')) return 'generated-directory';
  if (normalized.startsWith('lib/generated/')) return 'generated-directory';
  return null;
}

bool _canInjectAnchors(CompilationUnit unit) {
  return !unit.directives.any((directive) => directive is PartOfDirective);
}

bool _canInjectTouches(
  String path,
  CompilationUnit unit,
  MorphIntensity intensity,
) {
  if (intensity != MorphIntensity.deep) return false;
  if (unit.directives.any((directive) => directive is PartOfDirective)) {
    return false;
  }
  return true;
}

int _reshapeLevelForPath(String path, int baseLevel, ReshapeProfile profile) {
  if (baseLevel <= 0 || profile == ReshapeProfile.flat) {
    return baseLevel;
  }

  final isUiPath = _isUiMorphPath(path);
  final isColdPath = _isColdMorphPath(path);

  return switch (profile) {
    ReshapeProfile.flat => baseLevel,
    ReshapeProfile.tiered =>
      isUiPath ? _clampNonNegative(baseLevel - 1) : baseLevel,
    ReshapeProfile.coldHeavy =>
      isColdPath
          ? baseLevel + 1
          : (isUiPath ? _clampNonNegative(baseLevel - 1) : baseLevel),
  };
}

int _touchesForPath(String path, int baseTouches, ReshapeProfile profile) {
  if (baseTouches <= 0 || profile == ReshapeProfile.flat) {
    return baseTouches;
  }

  final isUiPath = _isUiMorphPath(path);
  final isColdPath = _isColdMorphPath(path);
  return switch (profile) {
    ReshapeProfile.flat => baseTouches,
    ReshapeProfile.tiered =>
      isUiPath ? _clampNonNegative(baseTouches - 1) : baseTouches,
    ReshapeProfile.coldHeavy =>
      isColdPath
          ? baseTouches + 1
          : (isUiPath ? _clampNonNegative(baseTouches - 1) : baseTouches),
  };
}

bool _isUiMorphPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.startsWith('lib/screens/') ||
      normalized.startsWith('lib/widgets/') ||
      normalized.startsWith('lib/ad/ui/') ||
      normalized.startsWith('lib/theme/') ||
      normalized.startsWith('lib/router/');
}

bool _isColdMorphPath(String path) {
  final normalized = path.replaceAll('\\', '/');
  if (normalized.startsWith('lib/api/') ||
      normalized.startsWith('lib/data/') ||
      normalized.startsWith('lib/tools/')) {
    return true;
  }
  return normalized.startsWith('lib/ad/analytics/') ||
      normalized.startsWith('lib/ad/config/') ||
      normalized.startsWith('lib/ad/controller/') ||
      normalized.startsWith('lib/ad/core/') ||
      normalized.startsWith('lib/ad/privacy/') ||
      normalized.startsWith('lib/ad/sdk/') ||
      normalized.startsWith('lib/ad/service/');
}

int _clampNonNegative(int value) => value < 0 ? 0 : value;

bool _shouldInstrumentFunction(String name) {
  return name != 'build' &&
      name != 'initState' &&
      name != 'dispose' &&
      name != 'didChangeDependencies' &&
      name != 'didUpdateWidget' &&
      name != 'reassemble' &&
      name != 'deactivate' &&
      name != 'activate' &&
      name != 'debugFillProperties' &&
      name != 'toString' &&
      name != 'hashCode' &&
      name != 'operator' &&
      name != '==' &&
      !name.startsWith('_rm') &&
      !name.startsWith('_rv');
}

String _kebabName(String value) {
  final buffer = StringBuffer();
  for (var i = 0; i < value.length; i++) {
    final code = value.codeUnitAt(i);
    final isUpper = code >= 65 && code <= 90;
    if (isUpper && i > 0) {
      buffer.write('-');
    }
    buffer.write(String.fromCharCode(isUpper ? code + 32 : code));
  }
  return buffer.toString();
}

List<String> _directivesFor(
  CompilationUnit unit, {
  required bool includeTouchImport,
  required String path,
}) {
  final touchUri = _releaseVariantImportUri(path);
  final touchImport = "import '$touchUri';";
  final sourceDirectives = unit.directives.where((directive) {
    if (directive is! ImportDirective) return true;
    return !_isReleaseVariantImport(directive.uri.stringValue);
  }).toList();

  final directives = <String>[];
  var inserted = false;
  for (final directive in sourceDirectives) {
    if (includeTouchImport &&
        !inserted &&
        (directive is ExportDirective || directive is PartDirective)) {
      directives.add(touchImport);
      inserted = true;
    }
    directives.add(directive.toSource());
  }
  if (includeTouchImport && !inserted) {
    directives.add(touchImport);
  }
  return directives;
}

bool _isReleaseVariantImport(String? uri) {
  if (uri == null) return false;
  return uri == 'release_variant.dart' || uri.endsWith('/release_variant.dart');
}

String _releaseVariantImportUri(String path) {
  final segments = path.replaceAll('\\', '/').split('/');
  final libIndex = segments.lastIndexOf('lib');
  final directoryDepth = libIndex == -1
      ? segments.length - 1
      : segments.length - libIndex - 2;
  return '${List.filled(directoryDepth, '../').join()}release_variant.dart';
}

String _stripMorphAnchors(String source) {
  return source.replaceAll(
    RegExp(
      r'\n?// BEGIN RELEASE MORPH ANCHORS\n[\s\S]*?// END RELEASE MORPH ANCHORS\n?',
      multiLine: true,
    ),
    '\n',
  );
}

String _stripMorphTouches(String source) {
  return source.replaceAll(
    RegExp(
      r'\n\s*// BEGIN RELEASE MORPH TOUCH\n[\s\S]*?\n\s*// END RELEASE MORPH TOUCH',
      multiLine: true,
    ),
    '',
  );
}

String _stripMorphTouchHelpers(String source) {
  return source.replaceAll(
    RegExp(
      r'\n?// BEGIN RELEASE MORPH TOUCH HELPERS\n[\s\S]*?// END RELEASE MORPH TOUCH HELPERS\n?',
      multiLine: true,
    ),
    '\n',
  );
}

String _relativePath(String path) {
  final cwd = Directory.current.path;
  final normalized = path.replaceAll('\\', '/');
  final normalizedCwd = cwd.replaceAll('\\', '/');
  if (normalized.startsWith('$normalizedCwd/')) {
    return normalized.substring(normalizedCwd.length + 1);
  }
  return normalized;
}

String _logicalPath(Directory root, File file) {
  final rootPath = root.absolute.path.replaceAll('\\', '/');
  final filePath = file.absolute.path.replaceAll('\\', '/');
  if (!filePath.startsWith('$rootPath/')) {
    throw StateError('File is outside morph root: ${file.path}');
  }
  return 'lib/${filePath.substring(rootPath.length + 1)}';
}

CompilationUnit _parseUnitOrThrow(String source, String path) {
  final result = parseString(
    content: source,
    featureSet: FeatureSet.latestLanguageVersion(),
    throwIfDiagnostics: false,
  );
  final errors = result.errors.where((error) {
    // analyzer exposes parse error severity through this deprecated bridge.
    // ignore: deprecated_member_use
    return error.errorCode.errorSeverity.name == 'ERROR';
  }).toList();
  if (errors.isNotEmpty) {
    final details = errors.take(3).map((error) => error.message).join('; ');
    throw FormatException('Dart parse failed for $path: $details');
  }
  return result.unit;
}

String _indent(String content) {
  return content
      .split('\n')
      .map((line) => line.trim().isEmpty ? '' : '  $line')
      .join('\n');
}

int _columnAtOffset(String source, int offset) {
  final lineStart = source.lastIndexOf('\n', offset - 1);
  return offset - lineStart - 1;
}

String _dedentFollowingLines(String content, int spaces) {
  if (spaces <= 0 || !content.contains('\n')) return content;
  final indentation = List.filled(spaces, ' ').join();
  final lines = content.split('\n');
  for (var i = 1; i < lines.length; i++) {
    if (lines[i].startsWith(indentation)) {
      lines[i] = lines[i].substring(spaces);
    }
  }
  return lines.join('\n');
}

String _sourceForNode(String source, int offset, int end) {
  var effectiveEnd = end;
  final lineEnd = source.indexOf('\n', end);
  final trailing = source.substring(
    end,
    lineEnd == -1 ? source.length : lineEnd,
  );
  if (trailing.trimLeft().startsWith('//')) {
    effectiveEnd = lineEnd == -1 ? source.length : lineEnd;
  }
  return source.substring(offset, effectiveEnd);
}

void _sortStable<T>(List<T> items, String seed, String Function(T item) keyOf) {
  if (items.length < 2) return;
  items.sort((a, b) {
    final aSourceKey = keyOf(a);
    final bSourceKey = keyOf(b);
    final aHash = _hexDigest('$seed:$aSourceKey');
    final bHash = _hexDigest('$seed:$bSourceKey');
    final hashCompare = aHash.compareTo(bHash);
    if (hashCompare != 0) return hashCompare;
    return aSourceKey.compareTo(bSourceKey);
  });
}

int _hashSeed(String seed) {
  var hash = 0x811c9dc5;
  for (final codeUnit in seed.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

String _sha256(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}

String _hexDigest(String value) {
  return sha256.convert(utf8.encode(value)).toString();
}
