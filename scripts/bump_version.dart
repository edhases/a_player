import 'dart:io';

void main() async {
  final now = DateTime.now();
  final dateStr =
      "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";

  final pubspecFile = File('pubspec.yaml');
  if (!await pubspecFile.exists()) {
    print('Error: pubspec.yaml not found');
    return;
  }

  final lines = await pubspecFile.readAsLines();
  final newLines = <String>[];
  bool updated = false;

  for (final line in lines) {
    if (line.startsWith('version:')) {
      // Format: version: 22.9.20260126+20260126
      // We keep the major.minor part but update the patch and build number to the current date
      final parts = line.split(':');
      if (parts.length > 1) {
        final newVersion = '1.0.$dateStr+$dateStr';
        newLines.add('version: $newVersion');
        print('Updated version to: $newVersion');
        updated = true;
      } else {
        newLines.add(line);
      }
    } else {
      newLines.add(line);
    }
  }

  if (updated) {
    await pubspecFile.writeAsString('${newLines.join('\n')}\n');
  } else {
    print('Warning: version line not found in pubspec.yaml');
  }
}
