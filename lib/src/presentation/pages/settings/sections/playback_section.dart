import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization.dart';
import '../../../blocs/settings/settings_bloc.dart';
import '../../../blocs/settings/settings_state.dart';
import '../settings_section_header.dart';
import '../../equalizer_screen.dart';

/// Секція налаштувань відтворення
///
/// Включає:
/// - Еквалайзер
class PlaybackSection extends StatelessWidget {
  const PlaybackSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: loc.playback),
        BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListTile(
              leading: const Icon(Icons.equalizer),
              title: Text(loc.equalizer),
              subtitle: Text(loc.adjustEqualizer),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EqualizerScreen()),
                );
              },
            );
          },
        ),
        const Divider(),
      ],
    );
  }
}
