part of 'library_bloc.dart';

sealed class LibraryEvent extends Equatable {
  const LibraryEvent();

  @override
  List<Object?> get props => [];
}

class LibraryViewModeChanged extends LibraryEvent {
  final LibraryViewMode viewMode;
  const LibraryViewModeChanged(this.viewMode);

  @override
  List<Object> get props => [viewMode];
}

class LibraryLoadData extends LibraryEvent {}

class LibraryToggleExcludedFolder extends LibraryEvent {
  final String folderPath;
  const LibraryToggleExcludedFolder(this.folderPath);

  @override
  List<Object> get props => [folderPath];
}

class LibraryDeleteRadioStation extends LibraryEvent {
  final int id;
  const LibraryDeleteRadioStation(this.id);

  @override
  List<Object> get props => [id];
}

class LibraryAddRadioStation extends LibraryEvent {
  final String name;
  final String url;
  const LibraryAddRadioStation(this.name, this.url);

  @override
  List<Object> get props => [name, url];
}
