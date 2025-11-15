import 'dart:io';

import 'package:path/path.dart' as p;

void main() async {
  print('generting pigeon code...');

  final rootDir = Platform.script.resolve('../').toFilePath();
  // 获取当前目录
  print('rootDir: $rootDir');

  try {
    // 执行pigeon命令生成代码
    final result = await Process.run(
      'dart',
      ['run', 'pigeon', '--input', p.join(rootDir, 'pigeons', 'messages.dart')],
      workingDirectory: rootDir,
      runInShell: true,
    );
    if (result.exitCode == 0) {
      print('\n✅ pigeon code generated successfully!');
    } else {
      print('\n❌ pigeon code generation failed!');
      print('${result.stderr}');
      print('${result.stdout}');
      exit(1);
    }

    // 确保iOS目录存在
    final iosDir = Directory(
      p.join(rootDir, 'packages', 'flutter_tts_ios', 'ios', 'Classes'),
    );
    if (!iosDir.existsSync()) {
      print('iOS dir not exists: ${iosDir.path}');
      return;
    }

    // 为iOS单独生成Swift代码（由于pigeon可能不直接支持同时为多个平台生成Swift）
    // 这里通过手动复制生成的Swift文件到iOS目录
    final macosSwiftFile = File(
      p.join(
        rootDir,
        'packages',
        'flutter_tts_macos',
        'macos',
        'Classes',
        'message.g.swift',
      ),
    );
    await macosSwiftFile.copy(p.join(iosDir.path, 'message.g.swift'));

    print('\n✅ done generating pigeon code!');
  } catch (e) {
    print('\n❌ error when generating pigeon code: $e');
    print(
      'please ensure pigeon dependency is installed: dart pub add pigeon --dev',
    );
    exit(1);
  }
}
