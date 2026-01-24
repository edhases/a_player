import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audio_service/audio_service.dart';
import '../blocs/lyrics/lyrics_bloc.dart';
import '../../core/models/lyrics_model.dart';
import '../../core/utils/localization.dart';

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
          return const Center(child: CircularProgressIndicator());
        } else if (state is LyricsNotFound) {
          final loc = AppLocalizations.of(context);
          return Center(
            child: Text(
              loc.noLyricsFound,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
            ),
          );
        } else if (state is LyricsError) {
          final loc = AppLocalizations.of(context);
          return Center(
            child: Text(
              loc.errorLoadingLyrics,
              style: TextStyle(color: Colors.red.withValues(alpha: 0.6)),
            ),
          );
        } else if (state is LyricsLoaded) {
          final lyrics = state.lyrics;
          if (lyrics.isSynced) {
            return _buildSyncedLyrics(lyrics.parsedSyncedLyrics);
          } else {
            return _buildPlainLyrics(lyrics.plainLyrics);
          }
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildPlainLyrics(String text) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildSyncedLyrics(List<LyricsLine> lines) {
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
        padding: EdgeInsets.symmetric(
            vertical: MediaQuery.of(context).size.height / 2.5, horizontal: 24),
        itemCount: lines.length,
        itemExtent:
            60.0, // Fixed height - must match _scrollToCenter calculation
        itemBuilder: (context, index) {
          final isCurrent = index == _currentIndex;
          return Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                color: isCurrent
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.5),
                fontSize: isCurrent ? 24 : 18,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
              ),
              child: Text(
                lines[index].text,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}
