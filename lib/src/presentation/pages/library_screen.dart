import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:get_it/get_it.dart';
import 'package:file_picker/file_picker.dart';

import '../widgets/common_artwork.dart';
import 'detail_screen.dart';
import '../../core/utils/localization.dart';
import 'folder_screen.dart';
import '../../core/services/audio_handler.dart';
import '../blocs/library/library_bloc.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    // Trigger load data if needed, but Bloc provider in main adds it initially?
    // In main we didn't add LibraryLoadData(), so let's check.
    // In LibraryBloc constructor: add(LibraryLoadData()); -> Yes we did.

    return BlocConsumer<LibraryBloc, LibraryState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.errorMessage!)),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: DropdownButtonHideUnderline(
              child: DropdownButton<LibraryViewMode>(
                value: state.viewMode,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                dropdownColor: Theme.of(context).cardColor,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                onChanged: (LibraryViewMode? newValue) {
                  if (newValue != null) {
                    context
                        .read<LibraryBloc>()
                        .add(LibraryViewModeChanged(newValue));
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
              if (state.viewMode == LibraryViewMode.radio)
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () => _showAddRadioDialog(context),
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LibraryState state) {
    if (state.status == LibraryStatus.loading &&
        state.folders.isEmpty &&
        state.albums.isEmpty &&
        state.artists.isEmpty &&
        state.radioStations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (state.viewMode) {
      case LibraryViewMode.folders:
        return _buildFoldersList(context, state);
      case LibraryViewMode.albums:
        return _buildAlbumsGrid(context, state);
      case LibraryViewMode.artists:
        return _buildArtistsList(context, state);
      case LibraryViewMode.radio:
        return _buildRadioList(context, state);
    }
  }

  Widget _buildRadioList(BuildContext context, LibraryState state) {
    final stations = state.radioStations;

    if (stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.radio, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context).noRadioStations),
            TextButton(
              onPressed: () => _showAddRadioDialog(context),
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
            onPressed: () {
              context
                  .read<LibraryBloc>()
                  .add(LibraryDeleteRadioStation(station.id));
            },
          ),
          onTap: () {
            GetIt.I<MyAudioHandler>().playRadioStation(station);
          },
        );
      },
    );
  }

  Future<void> _pickImage(TextEditingController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
      );

      if (result != null && result.files.single.path != null) {
        controller.text = result.files.single.path!;
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAddRadioDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final imageController = TextEditingController();
    final loc = AppLocalizations.of(context);
    final bloc = context.read<LibraryBloc>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.addRadioStation),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: loc.stationName),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlController,
                decoration: InputDecoration(labelText: loc.streamUrl),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: imageController,
                      decoration: InputDecoration(
                        labelText: loc.imageUrlOptional,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.image),
                    tooltip: loc.pickImage,
                    onPressed: () => _pickImage(imageController),
                  ),
                ],
              ),
            ],
          ),
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
                // LibraryBloc event LibraryAddRadioStation needs to be updated?
                // Let's check LibraryBloc.
                // Assuming LibraryAddRadioStation only takes name and url for now.
                // I might need to update the BLoC event too.
                // For now I'll just keep it as is if BLoC is not updated.
                // Wait, if I want to support image, I must update the BLoC event.
                bloc.add(LibraryAddRadioStation(
                    nameController.text,
                    urlController.text,
                    imageController.text.isEmpty
                        ? null
                        : imageController.text));
                Navigator.pop(context);
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  Widget _buildFoldersList(BuildContext context, LibraryState state) {
    final allFolders = state.folders;

    if (allFolders.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noFolders));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: allFolders.length,
      itemBuilder: (context, index) {
        final folderPath = allFolders[index];
        final folderName = p.basename(folderPath);
        final isExcluded = state.excludedFolders.contains(folderPath);

        return ListTile(
          leading: Icon(
            isExcluded ? Icons.folder_off : Icons.folder,
            color: isExcluded ? Colors.grey : Theme.of(context).primaryColor,
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
                context
                    .read<LibraryBloc>()
                    .add(LibraryToggleExcludedFolder(folderPath));
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
  }

  Widget _buildAlbumsGrid(BuildContext context, LibraryState state) {
    final albums = state.albums;
    if (albums.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noAlbums));
    }

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
  }

  Widget _buildArtistsList(BuildContext context, LibraryState state) {
    final artists = state.artists;
    if (artists.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context).noArtists));
    }

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
  }
}
