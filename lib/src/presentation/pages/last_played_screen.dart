import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/recommendation_service.dart';
import '../../core/utils/localization.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/compact_song_tile.dart';
import '../../domain/entities/youtube_song.dart';
import 'package:isar/isar.dart';
import '../../data/models/listen_history.dart';

class LastPlayedScreen extends StatelessWidget {
  const LastPlayedScreen({super.key});

  @override
  @override
  Widget build(BuildContext context) {
    final recommendationService = GetIt.I<RecommendationService>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      appBar: AppBar(
        title: Text(loc.lastPlayedTitle,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<ListenHistory>>(
        future: recommendationService.isar?.listenHistorys
            .where()
            .sortByTimestampDesc()
            .limit(100)
            .findAll(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final history = snapshot.data ?? [];

          if (history.isEmpty) {
            return Center(
                child: Text(loc.noHistory,
                    style: const TextStyle(color: Colors.white)));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              final song = YouTubeSong(
                  videoId: item.videoId,
                  title: item.title,
                  artist: item.artist,
                  thumbnailUrl: item.thumbnailUrl,
                  category: "Song");

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: CompactSongTile(
                  song: song,
                  onTap: () => GetIt.I<MyAudioHandler>().playYouTubeSong(song),
                  onMenuTap: () => _showContextMenu(context, song),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, YouTubeSong song) {
    final audioHandler = GetIt.I<MyAudioHandler>();
    final loc = AppLocalizations.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.queue_music, color: Colors.white),
            title: Text(loc.addToQueue,
                style: const TextStyle(color: Colors.white)),
            onTap: () {
              audioHandler.addYouTubeToQueue(song);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${loc.queueAdded}: ${song.title}')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.play_arrow, color: Colors.white),
            title:
                Text(loc.playNow, style: const TextStyle(color: Colors.white)),
            onTap: () {
              audioHandler.playYouTubeSong(song);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
