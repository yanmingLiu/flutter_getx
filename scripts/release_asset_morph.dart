import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

const _pngSignature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
const _pngMarkerType = 'rmOr';
const _webpMarkerType = 'RMOR';
const _svgMarkerPrefix = 'SIREN RELEASE MORPH:';

Future<void> main(List<String> args) async {
  final options = AssetMorphOptions.parse(args);
  if (options.showHelp) {
    stdout.write(AssetMorphOptions.usage);
    return;
  }

  final root = Directory(options.root);
  if (!root.existsSync()) {
    stderr.writeln('Error: asset root does not exist: ${options.root}');
    exitCode = 1;
    return;
  }

  final files =
      root
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => _supportedExtensions.contains(_extension(file.path)))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));
  final pending = <_PendingAssetWrite>[];
  final changes = <AssetMorphChange>[];

  for (final file in files) {
    final path = _relativePath(file.path);
    final extension = _extension(file.path);
    final marker = sha256
        .convert(utf8.encode('${options.seed}:$path'))
        .toString();
    final before = await file.readAsBytes();
    final after = morphAssetBytes(before, extension, marker, path);

    // A second pass must be byte-identical and also re-validates the container.
    final secondPass = morphAssetBytes(after, extension, marker, path);
    if (!_bytesEqual(after, secondPass)) {
      throw StateError('Asset morph is not idempotent: $path');
    }

    final beforeMd5 = md5.convert(before).toString();
    final afterMd5 = md5.convert(after).toString();
    final changed = beforeMd5 != afterMd5;
    changes.add(
      AssetMorphChange(
        path: path,
        format: extension.substring(1),
        marker: marker,
        beforeMd5: beforeMd5,
        afterMd5: afterMd5,
        changed: changed,
      ),
    );
    if (changed) {
      pending.add(_PendingAssetWrite(file: file, bytes: after, path: path));
      stdout.writeln('${options.dryRun ? 'DRY ' : ''}changed: $path');
    } else {
      stdout.writeln('unchanged: $path');
    }
  }

  if (!options.dryRun) {
    for (final item in pending) {
      await item.file.writeAsBytes(item.bytes, flush: true);
      final written = await item.file.readAsBytes();
      if (!_bytesEqual(written, item.bytes)) {
        throw FileSystemException('Asset verification failed', item.path);
      }
    }
  }

  if (options.manifestPath != null) {
    final manifestFile = File(options.manifestPath!);
    manifestFile.createSync(recursive: true);
    manifestFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert({
        'root': root.absolute.path,
        'seed': options.seed,
        'dryRun': options.dryRun,
        'fileCount': changes.length,
        'changedCount': changes.where((item) => item.changed).length,
        'unchangedCount': changes.where((item) => !item.changed).length,
        'files': changes.map((item) => item.toJson()).toList(),
      }),
    );
    stdout.writeln('manifest: ${manifestFile.path}');
  }

  stdout.writeln(
    'release_asset_morph complete: files=${changes.length}, '
    'changed=${changes.where((item) => item.changed).length}, '
    'dryRun=${options.dryRun}',
  );
}

class AssetMorphOptions {
  const AssetMorphOptions({
    required this.root,
    required this.seed,
    required this.manifestPath,
    required this.dryRun,
    required this.showHelp,
  });

  static const usage = '''
Usage: dart run scripts/release_asset_morph.dart [options]

Changes image MD5 values without changing file names or decoded pixels.

Options:
  --root <path>         Image root to process. Defaults to assets/images.
  --seed <value>        Stable seed used for deterministic release markers.
  --manifest <path>     Write a JSON manifest with before/after MD5 values.
  --dry-run             Validate and report without writing image files.
  --help, -h            Show this help.
''';

  final String root;
  final String seed;
  final String? manifestPath;
  final bool dryRun;
  final bool showHelp;

  static AssetMorphOptions parse(List<String> args) {
    var root = 'assets/images';
    var seed = 'siren-release';
    String? manifestPath;
    var dryRun = false;
    var showHelp = false;

    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--root':
          root = _readValue(args, ++i, '--root');
        case '--seed':
          seed = _readValue(args, ++i, '--seed');
        case '--manifest':
          manifestPath = _readValue(args, ++i, '--manifest');
        case '--dry-run':
          dryRun = true;
        case '--help':
        case '-h':
          showHelp = true;
        default:
          throw ArgumentError('Unknown option: ${args[i]}');
      }
    }
    if (seed.isEmpty) throw ArgumentError('--seed must not be empty');
    return AssetMorphOptions(
      root: root,
      seed: seed,
      manifestPath: manifestPath,
      dryRun: dryRun,
      showHelp: showHelp,
    );
  }

  static String _readValue(List<String> args, int index, String flag) {
    if (index >= args.length || args[index].isEmpty) {
      throw ArgumentError('Missing value for $flag');
    }
    return args[index];
  }
}

class AssetMorphChange {
  const AssetMorphChange({
    required this.path,
    required this.format,
    required this.marker,
    required this.beforeMd5,
    required this.afterMd5,
    required this.changed,
  });

  final String path;
  final String format;
  final String marker;
  final String beforeMd5;
  final String afterMd5;
  final bool changed;

  Map<String, Object> toJson() => {
    'path': path,
    'format': format,
    'marker': marker,
    'beforeMd5': beforeMd5,
    'afterMd5': afterMd5,
    'changed': changed,
  };
}

class _PendingAssetWrite {
  const _PendingAssetWrite({
    required this.file,
    required this.bytes,
    required this.path,
  });

  final File file;
  final Uint8List bytes;
  final String path;
}

const _supportedExtensions = {'.png', '.webp', '.svg'};

Uint8List morphAssetBytes(
  List<int> bytes,
  String extension,
  String marker,
  String path,
) {
  return switch (extension) {
    '.png' => _morphPng(bytes, marker, path),
    '.webp' => _morphWebp(bytes, marker, path),
    '.svg' => _morphSvg(bytes, marker, path),
    _ => throw UnsupportedError('Unsupported image format: $path'),
  };
}

Uint8List _morphPng(List<int> input, String marker, String path) {
  final bytes = Uint8List.fromList(input);
  if (bytes.length < _pngSignature.length ||
      !_bytesEqual(bytes.sublist(0, 8), _pngSignature)) {
    throw FormatException('Invalid PNG signature: $path');
  }

  final output = BytesBuilder(copy: false)..add(_pngSignature);
  var offset = 8;
  var foundIend = false;
  while (offset < bytes.length) {
    if (offset + 12 > bytes.length) {
      throw FormatException('Truncated PNG chunk header: $path');
    }
    final length = _readUint32Be(bytes, offset);
    final end = offset + 12 + length;
    if (end > bytes.length) {
      throw FormatException('Truncated PNG chunk data: $path');
    }
    final typeBytes = bytes.sublist(offset + 4, offset + 8);
    final type = ascii.decode(typeBytes);
    final data = bytes.sublist(offset + 8, offset + 8 + length);
    final expectedCrc = _readUint32Be(bytes, offset + 8 + length);
    final actualCrc = _crc32([...typeBytes, ...data]);
    if (expectedCrc != actualCrc) {
      throw FormatException('Invalid PNG CRC in $type chunk: $path');
    }
    if (type == 'IEND') {
      output.add(_pngChunk(_pngMarkerType, utf8.encode(marker)));
      output.add(bytes.sublist(offset, end));
      foundIend = true;
      offset = end;
      break;
    }
    if (type != _pngMarkerType) output.add(bytes.sublist(offset, end));
    offset = end;
  }
  if (!foundIend || offset != bytes.length) {
    throw FormatException('Invalid PNG ending: $path');
  }
  return output.takeBytes();
}

Uint8List _pngChunk(String type, List<int> data) {
  final typeBytes = ascii.encode(type);
  final output = BytesBuilder(copy: false)
    ..add(_uint32Be(data.length))
    ..add(typeBytes)
    ..add(data)
    ..add(_uint32Be(_crc32([...typeBytes, ...data])));
  return output.takeBytes();
}

Uint8List _morphWebp(List<int> input, String marker, String path) {
  final bytes = Uint8List.fromList(input);
  if (bytes.length < 12 ||
      ascii.decode(bytes.sublist(0, 4)) != 'RIFF' ||
      ascii.decode(bytes.sublist(8, 12)) != 'WEBP') {
    throw FormatException('Invalid WebP signature: $path');
  }
  final declaredSize = _readUint32Le(bytes, 4) + 8;
  if (declaredSize != bytes.length) {
    throw FormatException('Invalid WebP RIFF size: $path');
  }

  final chunks = BytesBuilder(copy: false);
  var offset = 12;
  while (offset < bytes.length) {
    if (offset + 8 > bytes.length) {
      throw FormatException('Truncated WebP chunk header: $path');
    }
    final type = ascii.decode(bytes.sublist(offset, offset + 4));
    final length = _readUint32Le(bytes, offset + 4);
    final end = offset + 8 + length;
    final paddedEnd = end + (length.isOdd ? 1 : 0);
    if (paddedEnd > bytes.length) {
      throw FormatException('Truncated WebP chunk data: $path');
    }
    if (type != _webpMarkerType) chunks.add(bytes.sublist(offset, paddedEnd));
    offset = paddedEnd;
  }

  chunks.add(_webpChunk(_webpMarkerType, utf8.encode(marker)));
  final body = chunks.takeBytes();
  final riffSize = 4 + body.length;
  if (riffSize > 0xffffffff) throw StateError('WebP is too large: $path');
  return Uint8List.fromList([
    ...ascii.encode('RIFF'),
    ..._uint32Le(riffSize),
    ...ascii.encode('WEBP'),
    ...body,
  ]);
}

Uint8List _webpChunk(String type, List<int> data) {
  return Uint8List.fromList([
    ...ascii.encode(type),
    ..._uint32Le(data.length),
    ...data,
    if (data.length.isOdd) 0,
  ]);
}

Uint8List _morphSvg(List<int> input, String marker, String path) {
  String source;
  try {
    source = utf8.decode(input);
  } on FormatException {
    throw FormatException('SVG is not valid UTF-8: $path');
  }
  source = source.replaceAll(
    RegExp(r'<!-- SIREN RELEASE MORPH:[0-9a-f]+ -->\s*'),
    '',
  );
  final closingTag = RegExp(r'</svg\s*>', caseSensitive: false);
  final match = closingTag.firstMatch(source);
  if (match == null) throw FormatException('SVG closing tag not found: $path');
  final comment = '<!-- $_svgMarkerPrefix$marker -->\n';
  final output = source.replaceRange(match.start, match.start, comment);
  return Uint8List.fromList(utf8.encode(output));
}

int _readUint32Be(List<int> bytes, int offset) {
  return (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
}

int _readUint32Le(List<int> bytes, int offset) {
  return bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);
}

Uint8List _uint32Be(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.big);
  return data.buffer.asUint8List();
}

Uint8List _uint32Le(int value) {
  final data = ByteData(4)..setUint32(0, value, Endian.little);
  return data.buffer.asUint8List();
}

int _crc32(List<int> bytes) {
  var crc = 0xffffffff;
  for (final byte in bytes) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc & 1) != 0 ? 0xedb88320 ^ (crc >> 1) : crc >> 1;
    }
  }
  return (crc ^ 0xffffffff) & 0xffffffff;
}

bool _bytesEqual(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var i = 0; i < left.length; i++) {
    if (left[i] != right[i]) return false;
  }
  return true;
}

String _extension(String path) {
  final slash = path.lastIndexOf(Platform.pathSeparator);
  final dot = path.lastIndexOf('.');
  if (dot <= slash) return '';
  return path.substring(dot).toLowerCase();
}

String _relativePath(String path) {
  final normalized = File(path).absolute.path.replaceAll('\\', '/');
  final cwd = Directory.current.absolute.path.replaceAll('\\', '/');
  return normalized.startsWith('$cwd/')
      ? normalized.substring(cwd.length + 1)
      : normalized;
}
