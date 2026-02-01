import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/localization.dart';
import '../../../blocs/settings/settings_bloc.dart';
import '../../../blocs/settings/settings_event.dart';
import '../../../blocs/settings/settings_state.dart';
import '../settings_section_header.dart';

/// Секція налаштувань зовнішнього вигляду
///
/// Включає:
/// - Вибір теми (system/light/dark)
/// - AMOLED режим
/// - Розмір шрифту
/// - Колір акценту
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: loc.translate('appearance')),
        BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return Column(
              children: [
                // Theme Mode
                ListTile(
                  leading: const Icon(Icons.palette),
                  title: Text(loc.translate('theme')),
                  subtitle: Text(_getThemeName(state.themeMode, loc)),
                  trailing: DropdownButton<ThemeMode>(
                    key: const Key('settings_theme_dropdown'),
                    value: state.themeMode,
                    items: [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text(loc.translate('theme_system')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text(loc.translate('theme_light')),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text(loc.translate('theme_dark')),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        context.read<SettingsBloc>().add(ChangeThemeMode(val));
                      }
                    },
                    underline: const SizedBox(),
                  ),
                ),

                // AMOLED Mode
                if (state.themeMode == ThemeMode.dark ||
                    state.themeMode == ThemeMode.system)
                  SwitchListTile(
                    title: Text(loc.translate('amoled_mode')),
                    subtitle: Text(loc.translate('amoled_mode_desc')),
                    value: state.amoledMode,
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ChangeAmoledMode(val));
                    },
                    secondary: const Icon(Icons.brightness_2),
                  ),

                // Font Size
                ListTile(
                  leading: const Icon(Icons.format_size),
                  title: Text(
                      '${loc.translate('font_size')} (${(state.fontScale * 100).toInt()}%)'),
                  subtitle: Slider(
                    value: state.fontScale,
                    min: 0.8,
                    max: 1.4,
                    divisions: 6,
                    label: '${(state.fontScale * 100).toInt()}%',
                    onChanged: (val) {
                      context.read<SettingsBloc>().add(ChangeFontScale(val));
                    },
                  ),
                ),

                // Accent Color
                ListTile(
                  leading: const Icon(Icons.color_lens),
                  title: Text(loc.translate('accent_color')),
                  subtitle: SizedBox(
                    height: 50,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildColorOption(context, null, state.accentColor),
                        _buildColorOption(
                            context, Colors.blue.toARGB32(), state.accentColor),
                        _buildColorOption(
                            context, Colors.red.toARGB32(), state.accentColor),
                        _buildColorOption(context, Colors.green.toARGB32(),
                            state.accentColor),
                        _buildColorOption(context, Colors.orange.toARGB32(),
                            state.accentColor),
                        _buildColorOption(context, Colors.purple.toARGB32(),
                            state.accentColor),
                        _buildColorOption(
                            context, Colors.teal.toARGB32(), state.accentColor),
                        _buildColorOption(
                            context, Colors.pink.toARGB32(), state.accentColor),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        const Divider(),
      ],
    );
  }

  String _getThemeName(ThemeMode mode, AppLocalizations loc) {
    switch (mode) {
      case ThemeMode.system:
        return loc.translate('theme_system');
      case ThemeMode.light:
        return loc.translate('theme_light');
      case ThemeMode.dark:
        return loc.translate('theme_dark');
    }
  }

  Widget _buildColorOption(
      BuildContext context, int? colorValue, int? selectedColor) {
    final isSelected = colorValue == selectedColor;
    final displayColor = colorValue != null
        ? Color(colorValue)
        : Theme.of(context).colorScheme.primary;
    final loc = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Tooltip(
        message: colorValue == null ? loc.translate('dynamic_color') : '',
        child: InkWell(
          onTap: () {
            context.read<SettingsBloc>().add(ChangeAccentColor(colorValue));
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: displayColor,
              shape: BoxShape.circle,
              border:
                  isSelected ? Border.all(color: Colors.white, width: 3) : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                          color: displayColor.withAlpha(128), blurRadius: 8)
                    ]
                  : null,
            ),
            child: colorValue == null
                ? const Icon(Icons.auto_awesome, color: Colors.white, size: 20)
                : null,
          ),
        ),
      ),
    );
  }
}
