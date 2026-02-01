import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:file_picker/file_picker.dart';

import '../widgets/compact_quick_pick_tile.dart';
import '../widgets/paged_song_list.dart';
import '../widgets/youtube_song_menu.dart';

import '../../domain/entities/home_section.dart';
import '../../core/services/smart_play_service.dart';
import '../../domain/entities/youtube_song.dart';
import '../../core/utils/localization.dart';
import '../../data/datasources/app_database.dart';
import '../../core/services/audio_handler.dart';
import '../blocs/home/home_bloc.dart';
import '../../core/theme/app_theme.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  final SmartPlayService _smartPlayService = GetIt.I<SmartPlayService>();

  Future<void> _pickImage(TextEditingController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);

      if (result != null && result.files.single.path != null) {
        controller.text = result.files.single.path!;
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showAddRadioDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final imageController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.addRadio),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: loc.name),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              final image = imageController.text.trim();

              if (name.isEmpty || url.isEmpty) {
                return;
              }

              Navigator.pop(ctx);

              await GetIt.I<AppDatabase>().addRadioStation(
                name,
                url,
                imageUrl: image.isEmpty ? null : image,
              );

              if (context.mounted) {
                context.read<HomeBloc>().add(HomeRefreshFeed());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${loc.addedToFavorites} $name')),
                );
              }
            },
            child: Text(loc.add),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          context.read<HomeBloc>().add(HomeRefreshFeed());
        },
        child: BlocBuilder<HomeBloc, HomeState>(
          builder: (context, state) {
            // Correct approach: Build the whole CustomScrollView inside BlocBuilder
            // OR use Sliver list logic properly.

            return CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: false,
                  snap: true,
                  title: Text(AppLocalizations.of(context).madeForYou),
                  centerTitle: false,
                  automaticallyImplyLeading: false,
                  backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                  elevation: 0,
                ),
                if (state.status == HomeStatus.loading &&
                    state.sections.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (state.status == HomeStatus.failure &&
                    state.sections.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 48,
                            color: context.appColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Oops!',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Could not load your feed.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              context.read<HomeBloc>().add(HomeRefreshFeed());
                            },
                            child: Text(AppLocalizations.of(context).retry),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (state.sections.isEmpty &&
                    state.status == HomeStatus.success)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(AppLocalizations.of(context).noMatchFound),
                    ),
                  )
                else
                  ...state.sections.expand(_buildSectionSlivers),
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _onSongTap(YouTubeSong song) async {
    // Handle Radio Tracks
    if (song.videoId.startsWith('radio:')) {
      final idStr = song.videoId.substring(6);
      final id = int.tryParse(idStr);
      if (id != null) {
        // Play radio
        // We need to fetch the full object or just construct it?
        // AudioHandler needs RadioStation object.
        // Fetch from DB is safest.
        final db = GetIt.I<AppDatabase>();
        // getAllRadioStations returns List. We need single.
        // Simpler: Just make a temporary RadioStation object if we have data,
        // OR fetch it. Since we only have partial data in YouTubeSong (title, art),
        // let's fetch to be safe for StreamURL.
        final stations = await db.getAllRadioStations();
        final station = stations.where((s) => s.id == id).firstOrNull;

        if (station != null) {
          final audioHandler = GetIt.I<MyAudioHandler>();
          await audioHandler.playRadioStation(station);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing ${station.name}...'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      }
      return;
    }

    // Handle Local Tracks
    if (song.videoId.startsWith('local:')) {
      final path = song.videoId.substring(6); // Remove 'local:' prefix
      try {
        final db = GetIt.I<AppDatabase>();
        final track = await (db.select(
          db.tracks,
        )..where((t) => t.path.equals(path)))
            .getSingleOrNull();

        if (track != null) {
          final audioHandler = GetIt.I<MyAudioHandler>();
          await audioHandler.playLocalTrack(track);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Playing ${track.title}...'),
                duration: const Duration(seconds: 1),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error playing local track from home: $e');
      }
      return;
    }

    // Handle YouTube Tracks
    await _smartPlayService.handleSongTap(context, song);
  }

  Future<void> _showSongContextMenu(
    BuildContext context,
    YouTubeSong song,
  ) async {
    if (song.videoId.startsWith('radio:')) {
      final idStr = song.videoId.substring(6);
      final id = int.tryParse(idStr);
      if (id != null) {
        _showRadioContextMenu(context, id, song);
      }
      return;
    }
    await YouTubeSongMenu.show(context, song);
  }

  void _showRadioContextMenu(
    BuildContext context,
    int stationId,
    YouTubeSong song,
  ) {
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.radio),
                title: Text(song.title),
                subtitle: Text(song.artist), // URL usually
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: Text(loc.edit),
                onTap: () {
                  Navigator.pop(context);
                  _showEditRadioDialog(context, stationId, song);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(
                  loc.delete,
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(loc.delete),
                      content: Text('${loc.delete} ${song.title}?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(loc.cancel),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(
                            loc.delete,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    await GetIt.I<AppDatabase>().deleteRadioStation(stationId);
                    if (context.mounted) {
                      context.read<HomeBloc>().add(HomeRefreshFeed());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${song.title} deleted')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditRadioDialog(BuildContext context, int id, YouTubeSong song) {
    final loc = AppLocalizations.of(context);
    final nameController = TextEditingController(text: song.title);
    final urlController = TextEditingController(text: song.artist);
    final imageController = TextEditingController(text: song.thumbnailUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(loc.edit),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: loc.name),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: urlController,
                decoration: InputDecoration(labelText: loc.streamUrl),
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
            onPressed: () => Navigator.pop(ctx),
            child: Text(loc.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final url = urlController.text.trim();
              final image = imageController.text.trim();

              if (name.isEmpty || url.isEmpty) {
                return;
              }

              Navigator.pop(ctx);

              final companion = RadioStationsCompanion(
                id: drift.Value(id),
                name: drift.Value(name),
                streamUrl: drift.Value(url),
                imageUrl: drift.Value(image.isEmpty ? null : image),
              );

              await GetIt.I<AppDatabase>().updateRadioStation(companion);

              if (context.mounted) {
                context.read<HomeBloc>().add(HomeRefreshFeed());
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Updated $name')));
              }
            },
            child: Text(loc.save),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSectionSlivers(HomeSection section) {
    if (section.songs.isEmpty) return [];

    final slivers = <Widget>[];

    final rawTitle = section.title;
    final sectionKey =
        'home_section_${rawTitle.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}'
            .replaceAll(RegExp(r'[^a-z0-9_]+'), '');

    // Localize Title
    String title = section.title;
    final loc = AppLocalizations.of(context);
    // Локалізація назв секцій
    switch (title) {
      case 'liked_songs':
        title = loc.likedSongs;
      case 'your_local_music':
        title = loc.yourLocalMusic;
      case 'radio_stations':
        title = loc.radio;
    }
    // else, assume it's "Made For You" or other dynamic title, or simple string.

    // Section Header
    slivers.add(
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  key: ValueKey(sectionKey),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (section.title == 'radio_stations')
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: loc.addRadio,
                  onPressed: () => _showAddRadioDialog(context),
                ),
            ],
          ),
        ),
      ),
    );

    // Section Content
    if (section.type == SectionType.vertical ||
        section.type == SectionType.grid ||
        section.type == SectionType.horizontal) {
      if (section.songs.isNotEmpty) {
        slivers.add(
          SliverToBoxAdapter(
            child: PagedSongList(
              songs: section.songs,
              itemsPerPage: 5,
              onSongTap: _onSongTap,
              onPlayTap: _onSongTap,
              onMenuTap: (song) => _showSongContextMenu(context, song),
            ),
          ),
        );
      }
    } else {
      slivers.add(
        SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            return CompactQuickPickTile(
              song: section.songs[index],
              onTap: () => _onSongTap(section.songs[index]),
              onPlayTap: () => _onSongTap(section.songs[index]),
              onMenuTap: () =>
                  _showSongContextMenu(context, section.songs[index]),
            );
          }, childCount: section.songs.length),
        ),
      );
    }

    return slivers;
  }
}
