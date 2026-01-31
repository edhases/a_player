import 'package:flutter/material.dart';

import '../../../core/services/sleep_timer_service.dart';
import '../../../core/utils/localization.dart';
import '../../../core/theme/app_theme.dart';

/// Dialog for setting a sleep timer.
class SleepTimerDialog extends StatelessWidget {
  final SleepTimerService sleepTimer;

  const SleepTimerDialog({super.key, required this.sleepTimer});

  static void show(BuildContext context, SleepTimerService sleepTimer) {
    final loc = AppLocalizations.of(context);
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ValueListenableBuilder<Duration?>(
        valueListenable: sleepTimer.remainingTime,
        builder: (context, remaining, child) {
          return _SleepTimerContent(
            sleepTimer: sleepTimer,
            loc: loc,
            remaining: remaining,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return ValueListenableBuilder<Duration?>(
      valueListenable: sleepTimer.remainingTime,
      builder: (context, remaining, child) {
        return _SleepTimerContent(
          sleepTimer: sleepTimer,
          loc: loc,
          remaining: remaining,
        );
      },
    );
  }
}

class _SleepTimerContent extends StatefulWidget {
  final SleepTimerService sleepTimer;
  final AppLocalizations loc;
  final Duration? remaining;

  const _SleepTimerContent({
    required this.sleepTimer,
    required this.loc,
    required this.remaining,
  });

  @override
  State<_SleepTimerContent> createState() => _SleepTimerContentState();
}

class _SleepTimerContentState extends State<_SleepTimerContent> {
  double _selectedMinutes = 30.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            widget.remaining != null
                ? '${widget.loc.sleepTimer}: ${_formatDuration(widget.remaining!)}'
                : widget.loc.setSleepTimer,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (widget.remaining != null)
          ListTile(
            title: Text(
              widget.loc.stopTimer,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            leading: Icon(Icons.timer_off, color: Theme.of(context).colorScheme.error),
            onTap: () {
              widget.sleepTimer.cancelTimer();
              Navigator.pop(context);
            },
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Text(
                  '${_selectedMinutes.round()} ${widget.loc.minutesSuffix}',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Slider(
                  value: _selectedMinutes,
                  min: 1,
                  max: 120,
                  divisions: 119,
                  activeColor: Theme.of(context).colorScheme.primary,
                  inactiveColor: colors.divider,
                  onChanged: (value) {
                    setState(() {
                      _selectedMinutes = value;
                    });
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  widget.sleepTimer.startTimer(
                    Duration(minutes: _selectedMinutes.round()),
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  widget.loc.startTimer,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
