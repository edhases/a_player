import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:drift/drift.dart' as drift; // Для Value
import '../../data/datasources/app_database.dart'; // Імпорт вашої БД

class MusicFinder {
  final AppDatabase _db;

  MusicFinder(this._db);

  /// Сканує пристрій (або вибрані папки) та оновлює БД
  Future<void> scanAndSaveToDb() async {
    // 1. Перевірка дозволів (на всяк випадок)
    if (!await Permission.audio.isGranted && !await Permission.storage.isGranted) {
      print("Permissions not granted");
      return;
    }

    // В ідеалі тут ми використовуємо SAF або скануємо відомі папки.
    // Для спрощення на цьому етапі - скануємо стандартну папку Music
    // Або можна викликати FilePicker, щоб користувач вибрав папку.

    // Тимчасове рішення для тесту: сканування /storage/emulated/0/Music
    // Увага: На Android 11+ прямий доступ обмежений, краще використовувати pickDirectory
    // Але якщо права надані через PermissionGate (Manage External Storage або Audio), спробуємо знайти.

    final Directory dir = Directory('/storage/emulated/0/Music');
    if (await dir.exists()) {
      await _scanDirectory(dir);
    } else {
      print("Music directory not found default path");
    }
  }

  // Метод для виклику з UI для вибору папки
  Future<void> pickFolderAndScan() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await _scanDirectory(Directory(selectedDirectory));
    }
  }

  Future<void> _scanDirectory(Directory dir) async {
    final List<FileSystemEntity> entities = dir.listSync(recursive: true);

    for (var entity in entities) {
      if (entity is File && _isAudioFile(entity.path)) {
        await _processFile(entity);
      }
    }
  }

  bool _isAudioFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp3', 'flac', 'm4a', 'wav', 'ogg'].contains(ext);
  }

  Future<void> _processFile(File file) async {
    Metadata? metadata;
    try {
      // Використовуємо metadata_god для зчитування тегів
      // Переконайтесь, що ініціалізували його в main.dart: await MetadataGod.initialize();
      metadata = await MetadataGod.getMetadata(file.path);
    } catch (e) {
      print("Error reading metadata for ${file.path}: $e");
    }

    // Створюємо запис для БД
    final trackCompanion = TracksCompanion(
      path: drift.Value(file.path),
      title: drift.Value(metadata?.title ?? file.path.split('/').last),
      artist: drift.Value(metadata?.artist ?? 'Unknown Artist'),
      album: drift.Value(metadata?.album ?? 'Unknown Album'),
      duration: drift.Value(metadata?.durationMs?.toInt() ?? 0),
      folderPath: drift.Value(file.parent.path),
      // Увага: тут ми обробляємо картинку. Якщо є картинка - зберігати поки не будемо в БД як BLOB,
      // бо це уповільнить. Зазвичай зберігають шлях до кешованого файлу.
      // Для Етапу 2 поки залишимо artworkUri пустим або null.
      artworkUri: drift.Value(null),
    );

    // Вставка в БД (Drift) з ігноруванням дублікатів (якщо path unique)
    try {
      await _db.into(_db.tracks).insertOnConflictUpdate(trackCompanion);
      print("Added: ${file.path}");
    } catch (e) {
      print("DB Insert Error: $e");
    }
  }
}
