import 'dart:io';

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      !const {'--check', '--apply', '--restore'}.contains(args.single)) {
    stderr.writeln(
      'Usage: dart run scripts/obfuscate_api_data.dart '
      '--check|--apply|--restore',
    );
    exitCode = 64;
    return;
  }

  for (final script in const [
    'scripts/obfuscate_api.dart',
    'scripts/obfuscate_model.dart',
  ]) {
    final result = await Process.run(Platform.resolvedExecutable, [
      'run',
      script,
      args.single,
    ]);
    stdout.write(result.stdout);
    stderr.write(result.stderr);
    if (result.exitCode != 0) {
      exitCode = result.exitCode;
      return;
    }
  }
}
