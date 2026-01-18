import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:path/path.dart' as p;
import '../../data/datasources/app_database.dart';
import '../../core/services/settings_service.dart';
import '../widgets/common_artwork.dart';
import 'detail_screen.dart';
import '../../core/utils/localization.dart';
import 'folder_screen.dart';
import '../../core/services/audio_handler.dart';

enum LibraryViewMode { folders, albums, artists, radio }

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  LibraryViewMode _viewMode = LibraryViewMode.folders;
  final _db = GetIt.I<AppDatabase>();
  final _settings = GetIt.I<SettingsService>();

  // Cache for excluded folders to update UI immediately
  List<String> _excludedFolders = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _excludedFolders = _settings.loadExcludedFolders();
      // Default view mode could be saved in settings too if desired
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: DropdownButtonHideUnderline(
          child: DropdownButton<LibraryViewMode>(
            value: _viewMode,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            dropdownColor: Theme.of(context).cardColor,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            onChanged: (LibraryViewMode? newValue) {
              if (newValue != null) {
                setState(() {
                  _viewMode = newValue;
                });
              }
            },
            items: [
              DropdownMenuItem(
                value: LibraryViewMode.folders,
                child: Text(loc.folders),
              ),
              DropdownMenuItem(
                value: LibraryViewMode.albums,
                child: Text(loc.albums),
              ),
              DropdownMenuItem(
                value: LibraryViewMode.artists,
                child: Text(loc.artists),
              ),
              DropdownMenuItem(
                value: LibraryViewMode.radio,
                child: Text(loc.radio),
              ),
            ],
          ),
        ),
        actions: [
          if (_viewMode == LibraryViewMode.radio)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _showAddRadioDialog,
            ),
          // Add extra actions if needed specific to view
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_viewMode) {
      case LibraryViewMode.folders:
        return _buildFoldersList();
      case LibraryViewMode.albums:
        return _buildAlbumsGrid();
      case LibraryViewMode.artists:
        return _buildArtistsList();
      case LibraryViewMode.radio:
        return _buildRadioList();
    }
  }

  Widget _buildRadioList() {
    return StreamBuilder<List<RadioStation>>(
      stream: _db.watchRadioStations(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // Handle error gracefully, or just empty list
        final stations = snapshot.data ?? [];

        if (stations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.radio, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context).noRadioStations),
                TextButton(
                  onPressed: _showAddRadioDialog,
                  child: Text(AppLocalizations.of(context).addRadioStation),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: stations.length,
          itemBuilder: (context, index) {
            final station = stations[index];
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.radio)),
              title: Text(station.name),
              subtitle: Text(station.streamUrl,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _db.deleteRadioStation(station.id),
              ),
              onTap: () {
                // Play logic will be added via AudioHandler
                GetIt.I<MyAudioHandler>().playRadioStation(station);
              },
            );
          },
        );
      },
    );
  }

  void _showAddRadioDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addRadioStation),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(labelText: loc.stationName),
              textCapitalization: TextCapitalization.sentences,
            ),
            TextField(
              controller: urlController,
              decoration: InputDecoration(labelText: loc.streamUrl),
              keyboardType: TextInputType.url,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  urlController.text.isNotEmpty) {
                _db.addRadioStation(nameController.text, urlController.text);
                Navigator.pop(context);
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersList() {
    return FutureBuilder<List<String>>(
      future: _db.getAllFolders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
              child: Text(AppLocalizations.of(context)
                  .translate('error', args: {'error': snapshot.error})));
        }

        final allFolders = snapshot.data ?? [];

        // Filter visually or show excluded status?
        // User wants to "exclude folder". Usually that means HIDING it from "Tracks" tab.
        // But in "Folders" view, we might still want to see it but marked as hidden, or maybe show a "Hidden Folders" section?
        // For now, let's show all folders but mark excluded ones, or allow toggling.
        // Or strictly follow request: "button to disable folder... so it doesn't fall into general tracks".
        // This implies we CAN see it here to disable it.

        if (allFolders.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context).noFolders));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: allFolders.length,
          itemBuilder: (context, index) {
            final folderPath = allFolders[index];
            final folderName = p.basename(folderPath);
            final isExcluded = _excludedFolders.contains(folderPath);

            return ListTile(
              leading: Icon(
                isExcluded ? Icons.folder_off : Icons.folder,
                color:
                    isExcluded ? Colors.grey : Theme.of(context).primaryColor,
                size: 32,
              ),
              title: Text(
                folderName,
                style: TextStyle(
                  color: isExcluded ? Colors.grey : null,
                  decoration: isExcluded ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                folderPath,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10),
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  if (value == 'toggle') {
                    if (isExcluded) {
                      await _settings.removeExcludedFolder(folderPath);
                    } else {
                      await _settings.addExcludedFolder(folderPath);
                    }
                    _loadSettings(); // Reload local state
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'toggle',
                    child: Text(isExcluded
                        ? AppLocalizations.of(context).includeInLibrary
                        : AppLocalizations.of(context).excludeFromLibrary),
                  ),
                ],
              ),
              onTap: () {
                // Navigate to folder details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FolderScreen(path: folderPath),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildAlbumsGrid() {
    return FutureBuilder<List<AlbumWithArtwork>>(
        future: _db.getAllAlbums(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final albums = snapshot.data ?? [];
          if (albums.isEmpty)
            return Center(child: Text(AppLocalizations.of(context).noAlbums));

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 10,
            ),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              final heroTag = 'album_art_${album.title}';

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        type: DetailScreenType.album,
                        title: album.title,
                      ),
                    ),
                  );
                },
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.0,
                        child: Hero(
                          tag: heroTag,
                          child: CommonArtwork(
                            mediaStoreId: album.mediaStoreId,
                            path: album.artworkPath,
                            size: 120,
                            radius: 4,
                            placeholderIcon: Icons.album,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.title,
                              style: Theme.of(context).textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              album.artist ??
                                  AppLocalizations.of(context).unknownArtist,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        });
  }

  Widget _buildArtistsList() {
    return FutureBuilder<List<Artist>>(
        future: _db.getAllArtists(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final artists = snapshot.data ?? [];
          if (artists.isEmpty)
            return Center(child: Text(AppLocalizations.of(context).noArtists));

          return ListView.builder(
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(artist.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        type: DetailScreenType.artist,
                        title: artist.name,
                      ),
                    ),
                  );
                },
              );
            },
          );
        });
  }
}
