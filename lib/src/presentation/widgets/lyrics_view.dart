import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import '../blocs/lyrics/lyrics_bloc.dart';
import '../../core/models/lyrics_model.dart';
import '../../core/utils/localization.dart';
import '../../core/theme/app_theme.dart';

class LyricsView extends StatefulWidget {
  final MediaItem mediaItem;

  const LyricsView({super.key, required this.mediaItem});

  @override
  State<LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<LyricsView> {
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _positionSubscription;
  int _currentIndex = -1;
  bool _isUserScrolling = false;
  Timer? _scrollResumeTimer;

  @override
  void initState() {
    super.initState();
    // Trigger fetch on init
    context.read<LyricsBloc>().add(FetchLyrics(widget.mediaItem));

    // Listen to position for syncing
    _setupPositionListener();
  }

  @override
  void didUpdateWidget(LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch lyrics when track changes
    if (oldWidget.mediaItem.id != widget.mediaItem.id) {
      context.read<LyricsBloc>().add(FetchLyrics(widget.mediaItem));
      _currentIndex = -1;
    }
  }

  void _setupPositionListener() {
    // Combine position stream with state to ensure we have latest data
    _positionSubscription = AudioService.position.listen((position) {
      if (!mounted) return;
      _updateSync(position);
    });
  }

  void _updateSync(Duration position) {
    if (_isUserScrolling) return;

    final state = context.read<LyricsBloc>().state;
    if (state is LyricsLoaded && state.lyrics.isSynced) {
      final lines = state.lyrics.parsedSyncedLyrics;

      // Find current line
      int newIndex = -1;
      for (int i = 0; i < lines.length; i++) {
        if (position >= lines[i].time) {
          newIndex = i;
        } else {
          break; // Since lines are ordered
        }
      }

      if (newIndex != _currentIndex) {
        setState(() {
          _currentIndex = newIndex;
        });
        _scrollToCenter(newIndex);
      }
    }
  }

  void _scrollToCenter(int index) {
    if (index < 0 || !_scrollController.hasClients) return;

    // Item height must match itemExtent in ListView
    const itemHeight = 60.0;

    // The ListView has top padding of (screenHeight / 2.5)
    final topPadding = MediaQuery.of(context).size.height / 2.5;

    // Position current line as the 2nd visible line
    // This shows: 1) previous line, 2) current line (highlighted), 3+) upcoming lines
    final itemPosition = index * itemHeight;

    // Scroll offset: position item one row from top (show previous line above)
    final targetOffset = itemPosition - itemHeight + topPadding;

    // Clamp to valid scroll range
    final maxScroll = _scrollController.position.maxScrollExtent;
    final offset = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _scrollController.dispose();
    _scrollResumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LyricsBloc, LyricsState>(
      builder: (context, state) {
        if (state is LyricsLoading) {
          // Show music note icon while loading instead of spinner
          final colors = context.appColors;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note,
                  size: 64,
                  color: colors.textMuted.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).loadingLyrics,
                  style: TextStyle(
                    color: colors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        } else if (state is LyricsNotFound) {
          final loc = AppLocalizations.of(context);
          final colors = context.appColors;
          return Center(
            child: Text(
              loc.noLyricsFound,
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        } else if (state is LyricsError) {
          final loc = AppLocalizations.of(context);
          final colors = context.appColors;
          return Center(
            child: Text(
              loc.errorLoadingLyrics,
              style: TextStyle(color: colors.error),
            ),
          );
        } else if (state is LyricsLoaded) {
          final lyrics = state.lyrics;
          if (lyrics.isSynced) {
            final lines = lyrics.parsedSyncedLyrics;
            if (lines.isNotEmpty) {
              return _buildSyncedLyrics(lines, lyrics.source);
            }
          }

          if (lyrics.plainLyrics.isNotEmpty) {
            return _buildPlainLyrics(lyrics.plainLyrics, lyrics.source);
          }

          return Center(
            child: Text(
              AppLocalizations.of(context).noLyricsFound,
              style: TextStyle(color: context.appColors.textSecondary),
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPlainLyrics(String text, String source) {
    final colors = context.appColors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Source: $source',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSyncedLyrics(List<LyricsLine> lines, String source) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification &&
            notification.dragDetails != null) {
          _isUserScrolling = true;
          _scrollResumeTimer?.cancel();
        } else if (notification is ScrollEndNotification) {
          _scrollResumeTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) _isUserScrolling = false;
          });
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        // Add padding to allows top items to be in center
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).size.height / 2.5,
          bottom: MediaQuery.of(context).size.height / 2.5,
          left: 24,
          right: 24,
        ),
        itemCount: lines.length + 1, // +1 for source
        itemBuilder: (context, index) {
          if (index == lines.length) {
            final colors = context.appColors;
            return Container(
              height: 60.0,
              alignment: Alignment.center,
              child: Text(
                'Source: $source',
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            );
          }
          final isCurrent = index == _currentIndex;
          final colors = context.appColors;
          final lineText = lines[index].text;

          // Show placeholder for empty lines
          final displayText = lineText.trim().isEmpty ? '♪' : lineText;

          return Center(
            child: SizedBox(
              height: 60.0,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isCurrent
                      ? colors.textPrimary
                      : (lineText.trim().isEmpty
                          ? colors.textMuted.withOpacity(0.4)
                          : colors.textSecondary),
                  fontSize: isCurrent ? 24 : 18,
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
                child: Text(
                  displayText,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
