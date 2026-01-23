import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/datasources/app_database.dart';
import '../../../core/services/settings_service.dart';

part 'library_event.dart';
part 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final AppDatabase _db;
  final SettingsService _settings;
  StreamSubscription? _radioSubscription;

  LibraryBloc({
    required AppDatabase db,
    required SettingsService settings,
  })  : _db = db,
        _settings = settings,
        super(const LibraryState()) {
    on<LibraryViewModeChanged>(_onViewModeChanged);
    on<LibraryLoadData>(_onLoadData);
    on<LibraryToggleExcludedFolder>(_onToggleExcludedFolder);
    on<LibraryDeleteRadioStation>(_onDeleteRadioStation);
    on<LibraryAddRadioStation>(_onAddRadioStation);

    // Initial load
    add(LibraryLoadData());
  }

  void _onViewModeChanged(
      LibraryViewModeChanged event, Emitter<LibraryState> emit) {
    emit(state.copyWith(viewMode: event.viewMode));
    // Could trigger data reload if needed, but we load all upfront or lazy load
    // For simplicity, let's load all or just rely on LoadData for updates.
  }

  Future<void> _onLoadData(
      LibraryLoadData event, Emitter<LibraryState> emit) async {
    // Only set loading if initial
    if (state.status == LibraryStatus.initial) {
      emit(state.copyWith(status: LibraryStatus.loading));
    }

    try {
      final excludedFolders = _settings.loadExcludedFolders();

      final folders = await _db.getAllFolders();
      final albums = await _db.getAllAlbums();
      final artists = await _db.getAllArtists();
      // Radio stations likely come from stream, but we can fetch once here too
      // OR subscribe.

      // Let's subscribe to radio stations separately?
      // For now, let's just fetch them or rely on stream if we implement stream subscription (recommended for reactive).
      if (_radioSubscription == null) {
        _radioSubscription = _db.watchRadioStations().listen((stations) {
          // We might need a separate event for stream update,
          // but since this is Bloc internal, we can't emit from here easily without adding event
          // Or we assume this Bloc handles static lists mostly, and radio is small.
          // However, to be reactive, we should enable list update.
          // Let's skip stream for now to match other tabs paradigm, or re-fetch on view mode change?
          // Actually, radio adds/deletes need UI update.
          // Let's just fetch here.
        });
      }
      final radioStations = await _db
          .getAllRadioStations(); // Need to implement getAll if not exists, or take first element of stream.

      emit(state.copyWith(
        status: LibraryStatus.success,
        folders: folders,
        albums: albums,
        artists: artists,
        radioStations: radioStations,
        excludedFolders: excludedFolders,
      ));
    } catch (e) {
      emit(state.copyWith(
          status: LibraryStatus.failure, errorMessage: e.toString()));
    }
  }

  Future<void> _onToggleExcludedFolder(
      LibraryToggleExcludedFolder event, Emitter<LibraryState> emit) async {
    try {
      if (state.excludedFolders.contains(event.folderPath)) {
        await _settings.removeExcludedFolder(event.folderPath);
      } else {
        await _settings.addExcludedFolder(event.folderPath);
      }
      add(LibraryLoadData()); // Reload settings
    } catch (e) {
      // handle error
    }
  }

  Future<void> _onDeleteRadioStation(
      LibraryDeleteRadioStation event, Emitter<LibraryState> emit) async {
    await _db.deleteRadioStation(event.id);
    add(LibraryLoadData()); // Reload
  }

  Future<void> _onAddRadioStation(
      LibraryAddRadioStation event, Emitter<LibraryState> emit) async {
    await _db.addRadioStation(event.name, event.url);
    add(LibraryLoadData()); // Reload
  }

  @override
  Future<void> close() {
    _radioSubscription?.cancel();
    return super.close();
  }
}
