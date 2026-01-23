import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../data/datasources/app_database.dart'; // Drift DB
import 'package:drift/drift.dart' as drift; // Alias if needed
import '../../core/utils/localization.dart';
import '../../core/services/audio_handler.dart';
import '../widgets/compact_song_tile.dart';
import '../../domain/entities/youtube_song.dart';

class LastPlayedScreen extends StatelessWidget {
  const LastPlayedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = GetIt.I<AppDatabase>();
    final loc = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Colors.black, // Dark theme background
      appBar: AppBar(
        title: Text(loc.lastPlayedTitle,
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<PlaybackLogEntry>>(
        // Example query: Join with YouTubeTracks to get metadata
        future: (db.select(db.playbackLog).join([
          drift.innerJoin(db.youTubeTracks,
              db.youTubeTracks.videoId.equalsExp(db.playbackLog.videoId))
        ])
              ..orderBy([
                drift.OrderingTerm(
                    expression: db.playbackLog.playedAt,
                    mode: drift.OrderingMode.desc)
              ])
              ..limit(100))
            .get()
            .then((rows) => rows.map((row) {
                  final entry = row.readTable(db.playbackLog);
                  return entry;
                }) // We actually need to map to something useful, but for now lets just get the entries or safer, read both
                    .toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // We need to fetch metadata for these items.
          // Actually the join above returns TypedResult.
          // Let's rewrite the query execution inside builder logic or helper to return full objects.
          return FutureBuilder<List<YouTubeSong>>(
            future: _getHistoryWithMetadata(db),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final song = history[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: CompactSongTile(
                      song: song,
                      onTap: () =>
                          GetIt.I<MyAudioHandler>().playYouTubeSong(song),
                      onMenuTap: () => _showContextMenu(context, song),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<YouTubeSong>> _getHistoryWithMetadata(AppDatabase db) async {
    final query = db.select(db.playbackLog).join([
      drift.innerJoin(db.youTubeTracks,
          db.youTubeTracks.videoId.equalsExp(db.playbackLog.videoId))
    ])
      ..orderBy([
        drift.OrderingTerm(
            expression: db.playbackLog.playedAt, mode: drift.OrderingMode.desc)
      ])
      ..limit(100);

    final rows = await query.get();
    return rows.map((row) {
      final track = row.readTable(db.youTubeTracks);
      return YouTubeSong(
          videoId: track.videoId,
          title: track.title,
          artist: track.artist,
          thumbnailUrl: track.thumbnailUrl,
          duration: track.duration,
          category: "Song");
    }).toList();
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
