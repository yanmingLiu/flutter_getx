import 'dart:convert';
import 'dart:io';

const _mapPath = 'scripts/config/api_map.json';
const _allowlistPath = 'scripts/config/api_allowlist.json';
const _targetPath = 'lib/api/api_path.dart';
const _excludedConstants = <String>{'draftGenerate'};

void main(List<String> args) {
  final mode = _parseMode(args);
  final file = File(_targetPath);
  if (!file.existsSync()) {
    stderr.writeln(
      '⚠️  API path source not found, skipping obfuscation: $_targetPath',
    );
    return;
  }

  final mapping = _readStringMap(_mapPath);
  final allowlist = _readStringList(_allowlistPath).toSet();
  _validateMapping(mapping);

  final reverse = {for (final entry in mapping.entries) entry.value: entry.key};
  final obfuscated = mapping.keys.toSet();
  final source = file.readAsStringSync();
  final protected = _protectExcludedConstants(source);
  final pathPattern = RegExp(r'''(['"])(/[^'"\r\n]+)\1''');
  final unknown = <String>{};
  var replacements = 0;

  final transformedOutput = protected.source.replaceAllMapped(pathPattern, (
    match,
  ) {
    final quote = match.group(1)!;
    final path = match.group(2)!;
    final segments = path.split('/');
    for (var index = 0; index < segments.length; index++) {
      final segment = segments[index];
      if (mode == _Mode.restore) {
        final replacement = mapping[segment];
        if (replacement != null) {
          segments[index] = replacement;
          replacements++;
        }
        continue;
      }
      if (segment.isEmpty ||
          segment.startsWith('{') ||
          obfuscated.contains(segment) ||
          allowlist.contains(segment)) {
        continue;
      }
      final replacement = reverse[segment];
      if (replacement == null) {
        unknown.add(segment);
      } else {
        segments[index] = replacement;
        replacements++;
      }
    }
    return '$quote${segments.join('/')}$quote';
  });
  final output = protected.restore(transformedOutput);

  // Only segments explicitly configured in api_map.json or api_allowlist.json
  // participate in obfuscation. New server endpoints remain unchanged so they
  // do not block an otherwise valid release build.
  if (mode != _Mode.restore && unknown.isNotEmpty) {
    final ignored = unknown.toList()..sort();
    stderr.writeln(
      '❌ Ignored unmapped API path segments (not configured in JSON): $ignored',
    );
  }
  if (mode != _Mode.check && output != source) {
    file.writeAsStringSync(output);
  }
  final action = switch (mode) {
    _Mode.check => 'Checked',
    _Mode.apply => 'Applied',
    _Mode.restore => 'Restored',
  };
  stdout.writeln('$action API path obfuscation: $replacements replacement(s)');
}

_ProtectedSource _protectExcludedConstants(String source) {
  final values = <String>[];
  var protectedSource = source;
  for (final name in _excludedConstants) {
    final pattern = RegExp(
      "(static\\s+(?:const\\s+)?String\\s+$name\\s*=\\s*)(['\"])([^'\"\\r\\n]+)\\2(\\s*;)",
    );
    protectedSource = protectedSource.replaceAllMapped(pattern, (match) {
      final index = values.length;
      values.add(match.group(0)!);
      return '__API_OBFUSCATION_EXCLUDED_${index}__';
    });
  }
  return _ProtectedSource(protectedSource, values);
}

class _ProtectedSource {
  const _ProtectedSource(this.source, this.values);

  final String source;
  final List<String> values;

  String restore(String output) {
    var restored = output;
    for (var index = 0; index < values.length; index++) {
      restored = restored.replaceAll(
        '__API_OBFUSCATION_EXCLUDED_${index}__',
        values[index],
      );
    }
    return restored;
  }
}

enum _Mode { check, apply, restore }

_Mode _parseMode(List<String> args) {
  if (args.length != 1 ||
      !const {'--check', '--apply', '--restore'}.contains(args.single)) {
    stderr.writeln(
      'Usage: dart run scripts/obfuscate_api.dart '
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

List<String> _readStringList(String path) {
  final decoded = jsonDecode(File(path).readAsStringSync());
  if (decoded is! List) {
    throw FormatException('$path must contain a JSON array');
  }
  return decoded.map((value) => value.toString()).toList();
}

void _validateMapping(Map<String, String> mapping) {
  if (mapping.keys.toSet().length != mapping.length ||
      mapping.values.toSet().length != mapping.length) {
    throw const FormatException('API map keys and values must be unique');
  }
}
