import 'package:flutter/foundation.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';

class TrackListProvider extends ChangeNotifier {
  final AppDatabase _database;
  final String folderPath;

  TrackListProvider(this._database, this.folderPath) {
    _fetchTracks();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Track> _tracks = [];
  List<Track> get tracks => _tracks;

  Future<void> _fetchTracks() async {
    _isLoading = true;
    notifyListeners();

    try {
      final query = _database.select(_database.tracks)
        ..where((t) => t.folderPath.equals(folderPath));
      _tracks = await query.get();
    } catch (e) {
      debugPrint('Error fetching tracks: $e');
    }

    _isLoading = false;
    notifyListeners();
  }
}
