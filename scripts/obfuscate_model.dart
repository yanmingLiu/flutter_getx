import 'dart:convert';
import 'dart:io';

const _mapPath = 'scripts/config/data_map.json';
const _directories = <String>['lib/models'];
const _excludedClasses = <String>{'SideStory', 'UgcGenerateBatchResultDTO'};

void main(List<String> args) {
  final mode = _parseMode(args);
  final files = _dartFiles().toList(growable: false);
  if (files.isEmpty) {
    stderr.writeln(
      '⚠️  Model sources not found, skipping obfuscation: '
      '${_directories.join(', ')}',
    );
    return;
  }

  final mapping = _readStringMap(_mapPath);
  _validateMapping(mapping);
  final reverse = {for (final entry in mapping.entries) entry.value: entry.key};
  final replacementsMap = mode == _Mode.restore ? mapping : reverse;
  var replacements = 0;
  var changedFiles = 0;

  for (final file in files) {
    final source = file.readAsStringSync();
    final protected = _protectExcludedClasses(source);
    var output = protected.source;
    for (final entry in replacementsMap.entries) {
      final key = RegExp.escape(entry.key);
      final replacement = entry.value;
      output = output.replaceAllMapped(RegExp("(['\"])$key\\1(\\s*:)"), (
        match,
      ) {
        replacements++;
        return '${match.group(1)}$replacement${match.group(1)}${match.group(2)}';
      });
      output = output.replaceAllMapped(
        RegExp("(\\[\\s*['\"])$key(['\"]\\s*\\])"),
        (match) {
          replacements++;
          return '${match.group(1)}$replacement${match.group(2)}';
        },
      );
      output = output.replaceAllMapped(
        RegExp("(name\\s*:\\s*['\"])$key(['\"])"),
        (match) {
          replacements++;
          return '${match.group(1)}$replacement${match.group(2)}';
        },
      );
    }
    output = protected.restore(output);
    if (output != source) {
      changedFiles++;
      if (mode != _Mode.check) file.writeAsStringSync(output);
    }
  }
  if (replacements == 0) {
    stderr.writeln(
      '⚠️  No model fields matched the obfuscation map; continuing without '
      'model changes.',
    );
  }
  final action = switch (mode) {
    _Mode.check => 'Checked',
    _Mode.apply => 'Applied',
    _Mode.restore => 'Restored',
  };
  stdout.writeln(
    '$action model field obfuscation: '
    '$replacements replacement(s) in $changedFiles file(s)',
  );
}

_ProtectedSource _protectExcludedClasses(String source) {
  final values = <String>[];
  var output = source;
  for (final className in _excludedClasses) {
    final declaration = RegExp('class\\s+$className\\b').firstMatch(output);
    if (declaration == null) continue;
    final openingBrace = output.indexOf('{', declaration.end);
    if (openingBrace < 0) continue;

    var depth = 0;
    var closingBrace = -1;
    for (var index = openingBrace; index < output.length; index++) {
      if (output.codeUnitAt(index) == 123) depth++;
      if (output.codeUnitAt(index) == 125 && --depth == 0) {
        closingBrace = index;
        break;
      }
    }
    if (closingBrace < 0) continue;

    final value = output.substring(declaration.start, closingBrace + 1);
    final placeholder = '__MODEL_OBFUSCATION_EXCLUDED_${values.length}__';
    values.add(value);
    output = output.replaceRange(
      declaration.start,
      closingBrace + 1,
      placeholder,
    );
  }
  return _ProtectedSource(output, values);
}

class _ProtectedSource {
  const _ProtectedSource(this.source, this.values);

  final String source;
  final List<String> values;

  String restore(String output) {
    var restored = output;
    for (var index = 0; index < values.length; index++) {
      restored = restored.replaceAll(
        '__MODEL_OBFUSCATION_EXCLUDED_${index}__',
        values[index],
      );
    }
    return restored;
  }
}

Iterable<File> _dartFiles() sync* {
  for (final path in _directories) {
    final directory = Directory(path);
    if (!directory.existsSync()) continue;
    yield* directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'));
  }
}

enum _Mode { check, apply, restore }

_Mode _parseMode(List<String> args) {
  if (args.length != 1 ||
      !const {'--check', '--apply', '--restore'}.contains(args.single)) {
    stderr.writeln(
      'Usage: dart run scripts/obfuscate_model.dart '
      '--check|--apply|--restore',
    );
    exit(64);
  }
  return switch (args.single) {
    '--check' => _Mode.check,
    '--apply' => _Mode.apply,
    '--restore' => _Mode.restore,
    _ => throw StateError('Unsupported mode'),
  };
}

Map<String, String> _readStringMap(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! Map) {
    throw FormatException('$path must contain a JSON object');
  }
  return decoded.map(
    (key, value) => MapEntry(key.toString(), value.toString()),
  );
}

void _validateMapping(Map<String, String> mapping) {
  if (mapping.keys.toSet().length != mapping.length ||
      mapping.values.toSet().length != mapping.length) {
    throw const FormatException('Data map keys and values must be unique');
  }
}
