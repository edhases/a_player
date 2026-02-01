import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization.dart';
import '../../../blocs/settings/settings_bloc.dart';
import '../../../blocs/settings/settings_event.dart';
import '../../../blocs/settings/settings_state.dart';
import '../settings_section_header.dart';

/// Секція налаштувань мови
///
/// Включає:
/// - Вибір мови інтерфейсу
class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: loc.language),
        BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return ListTile(
              leading: const Icon(Icons.language),
              title: Text(_getLanguageName(state.locale.languageCode)),
              subtitle: Text(loc.language),
              trailing: DropdownButton<String>(
                key: const Key('settings_language_dropdown'),
                value: state.locale.languageCode,
                items: const [
                  DropdownMenuItem(value: 'en', child: Text('English')),
                  DropdownMenuItem(value: 'uk', child: Text('Українська')),
                  DropdownMenuItem(value: 'de', child: Text('Deutsch')),
                  DropdownMenuItem(value: 'pl', child: Text('Polski')),
                  DropdownMenuItem(value: 'es', child: Text('Español')),
                  DropdownMenuItem(value: 'ja', child: Text('日本語')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    context
                        .read<SettingsBloc>()
                        .add(ChangeLocale(Locale(value)));
                  }
                },
                underline: const SizedBox(),
              ),
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'uk':
        return 'Українська';
      case 'de':
        return 'Deutsch';
      case 'pl':
        return 'Polski';
      case 'es':
        return 'Español';
      case 'ja':
        return '日本語';
      default:
        return 'English';
    }
  }
}
