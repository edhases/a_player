import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';

import '../../../core/theme/app_theme.dart';

import '../../../core/services/audio_handler.dart';
import '../../../core/utils/localization.dart';
import '../../blocs/player/player_bloc.dart';
import '../../blocs/queue/queue_bloc.dart';
import '../common_artwork.dart';

/// Bottom sheet showing the current playback queue.
class QueueSheet extends StatelessWidget {
  const QueueSheet({super.key});

  static void show(BuildContext context) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.sheetBackground,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const QueueSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BlocBuilder<QueueBloc, QueueState>(
      builder: (context, state) {
        final currentQueue = state.queue;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                AppLocalizations.of(context).currentQueue,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: ReorderableListView.builder(
                buildDefaultDragHandles: false,
                proxyDecorator: (child, index, animation) {
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colors.sheetBackground,
                        boxShadow: [
                          BoxShadow(
                            color: colors.overlay,
                            blurRadius: 8,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: child,
                    ),
                  );
                },
                onReorder: (oldIndex, newIndex) {
                  context.read<QueueBloc>().add(QueueReorder(oldIndex, newIndex));
                },
                itemCount: currentQueue.length,
                itemBuilder: (context, index) {
                  final item = currentQueue[index];
                  final currentItem = context.read<PlayerBloc>().state.mediaItem;
                  final isCurrent = currentItem?.id == item.id;

                  return ListTile(
                    key: ValueKey(item.id),
                    leading: _QueueItemArtwork(item: item),
                    title: Text(
                      item.title,
                      style: TextStyle(
                        color: isCurrent
                            ? Theme.of(context).colorScheme.primary
                            : colors.textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      item.artist ?? '',
                      style: TextStyle(color: colors.textSecondary),
                    ),
                    trailing: ReorderableDragStartListener(
                      index: index,
                      child: Icon(Icons.drag_handle, color: colors.textMuted),
                    ),
                    onTap: () {
                      GetIt.I<MyAudioHandler>().skipToQueueItem(index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _QueueItemArtwork extends StatelessWidget {
  final MediaItem item;

  const _QueueItemArtwork({required this.item});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CommonArtwork(
        mediaStoreId: item.extras?['mediaStoreId'] as int?,
        path: item.id,
        url: item.artUri?.toString(),
        size: 40,
        radius: 4,
      ),
    );
  }
}
