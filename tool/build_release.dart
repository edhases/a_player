import 'dart:io';

void main(List<String> args) async {
  final now = DateTime.now();
  final year = now.year;
  final month = now.month.toString().padLeft(2, '0');
  final day = now.day.toString().padLeft(2, '0');

  final versionDate = '$year$month$day';
  final buildNumber = (now.millisecondsSinceEpoch ~/ 1000)
      .toString(); // simple epoch-based build number

  print('🚀 Starting Release Build...');
  print('📦 Version: $versionDate');
  print('🔢 Build Number: $buildNumber');

  final process = await Process.start(
    Platform.isWindows ? 'flutter.bat' : 'flutter',
    [
      'build',
      'apk',
      '--release',
      '--build-name=$versionDate',
      '--build-number=$buildNumber',
    ],
    mode: ProcessStartMode.inheritStdio,
  );

  final exitCode = await process.exitCode;

  if (exitCode == 0) {
    print('✅ Build successful!');
    print('📂 Output: build/app/outputs/flutter-apk/app-release.apk');
  } else {
    print('❌ Build failed with exit code $exitCode');
    exit(exitCode);
  }
}
