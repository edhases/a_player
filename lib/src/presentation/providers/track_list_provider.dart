import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:oxide_player/src/data/datasources/app_database.dart';

class TrackListProvider extends ChangeNotifier {
  final AppDatabase _database;
  final String folderPath;
  late StreamSubscription _tracksSubscription;

  TrackListProvider(this._database, this.folderPath) {
    _watchTracks();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  List<Track> _tracks = [];
  List<Track> get tracks => _tracks;

  void _watchTracks() {
    _isLoading = true;
    notifyListeners();

    final query = _database.select(_database.tracks)
      ..where((t) => t.folderPath.equals(folderPath));
    _tracksSubscription = query.watch().listen((tracks) {
      _tracks = tracks;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error watching tracks: $e');
      _isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _tracksSubscription.cancel();
    super.dispose();
  }
}
