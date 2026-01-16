import 'dart:async';
import 'package:flutter/foundation.dart';
import 'audio_handler.dart';

class SleepTimerService {
  final MyAudioHandler _audioHandler;
  Timer? _timer;
  final ValueNotifier<Duration?> remainingTime = ValueNotifier(null);

  SleepTimerService(this._audioHandler);

  bool get isActive => _timer != null && _timer!.isActive;

  void startTimer(Duration duration) {
    cancelTimer();
    debugPrint('[SleepTimer] Started for $duration');

    // Update remaining time periodically for UI
    remainingTime.value = duration;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newRemaining = remainingTime.value! - const Duration(seconds: 1);
      if (newRemaining <= Duration.zero) {
        _onTimerFinished();
      } else {
        remainingTime.value = newRemaining;
      }
    });
  }

  void cancelTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
      remainingTime.value = null;
      debugPrint('[SleepTimer] Cancelled');
    }
  }

  Future<void> _onTimerFinished() async {
    cancelTimer();
    debugPrint('[SleepTimer] Finished. Stopping playback.');
    await _audioHandler.pause(); // Or stop() depending on preference
  }
}
