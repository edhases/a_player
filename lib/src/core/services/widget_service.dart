import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:audio_service/audio_service.dart';
import 'package:get_it/get_it.dart';
import 'audio_handler.dart';

@pragma('vm:entry-point')
Future<void> _widgetBackgroundCallback(Uri? uri) async {
  debugPrint('[WidgetService] Callback triggered: $uri');
  if (uri == null) return;

  if (uri.scheme == 'homeWidget') {
    // Only proceed if GetIt is initialized (app is running/background)
    // If app is terminated and this spawns a fresh isolate, GetIt needs setup.
    // For MVP, we assume app is running or we just log.
    try {
      if (!GetIt.I.isRegistered<MyAudioHandler>()) {
        debugPrint('[WidgetService] AudioHandler not ready found in GetIt');
        return;
      }

      final handler = GetIt.I<MyAudioHandler>();

      switch (uri.host) {
        case 'ACTION_TOGGLE':
          if (handler.playbackState.value.playing) {
            await handler.pause();
          } else {
            await handler.play();
          }
          break;
        case 'ACTION_NEXT':
          await handler.skipToNext();
          break;
        case 'ACTION_PREV':
          await handler.skipToPrevious();
          break;
      }
    } catch (e) {
      debugPrint('[WidgetService] Error in background callback: $e');
    }
  }
}

class WidgetService {
  static const String _appGroupId =
      'com.oxideplayer.app.group'; // Optional/Placeholder
  static const String _androidWidgetName = 'HomeWidgetProvider';

  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(_appGroupId);
      await HomeWidget.registerInteractivityCallback(_widgetBackgroundCallback);
      debugPrint('[WidgetService] Initialized');
    } catch (e) {
      debugPrint('[WidgetService] Init error: $e');
    }
  }

  Future<void> updateWidget(MediaItem? item) async {
    if (item == null) return;
    try {
      await HomeWidget.saveWidgetData<String>('title', item.title);
      await HomeWidget.saveWidgetData<String>(
          'artist', item.artist ?? 'Unknown');

      // For images, we need to save the file or download url and pass logical path
      // HomeWidget handles renderFlutterWidget or just primitive data.
      // In our native code we just read strings. We haven't implemented image loading in native yet!
      // (Native code sets layout, but doesn't load image from URL independently)
      // For MVP, update text is sufficient.

      await HomeWidget.updateWidget(
        name: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('[WidgetService] updateWidget error: $e');
    }
  }

  Future<void> updatePlaybackState(bool isPlaying) async {
    try {
      await HomeWidget.saveWidgetData<bool>('isPlaying', isPlaying);
      await HomeWidget.updateWidget(
        name: _androidWidgetName,
      );
    } catch (e) {
      debugPrint('[WidgetService] updatePlaybackState error: $e');
    }
  }
}
