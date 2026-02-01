import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/music_finder.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/utils/localization.dart';
import '../settings_section_header.dart';

/// Секція налаштувань бібліотеки музики
///
/// Включає:
/// - Сканування бібліотеки
/// - Очищення бібліотеки
/// - Збереження метаданих у файл
class LibrarySection extends StatelessWidget {
  const LibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final musicFinder = GetIt.I<MusicFinder>();
    final settingsService = GetIt.I<SettingsService>();
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: loc.library),

        // Scan Library
        ValueListenableBuilder<bool>(
          valueListenable: musicFinder.isScanning,
          builder: (context, isScanning, child) {
            return ListTile(
              leading: Icon(
                Icons.refresh,
                color: isScanning ? colorScheme.primary : null,
              ),
              title: Text(loc.scanLibrary),
              subtitle: ValueListenableBuilder<String>(
                valueListenable: musicFinder.scanStatus,
                builder: (context, status, _) {
                  return Text(
                    isScanning
                        ? (status.isNotEmpty ? status : loc.scanning)
                        : loc.scanDesc,
                  );
                },
              ),
              trailing: isScanning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: isScanning
                  ? null
                  : () async {
                      await musicFinder.scanAllMusic();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc.scanComplete),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
            );
          },
        ),

        // Clear Library
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: Text(loc.clearLibrary),
          subtitle: Text(loc.clearDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showClearLibraryDialog(context, musicFinder, loc),
        ),

        // Save Metadata to File
        _SaveMetadataSwitch(settingsService: settingsService),

        const Divider(),
      ],
    );
  }

  Future<void> _showClearLibraryDialog(
    BuildContext context,
    MusicFinder musicFinder,
    AppLocalizations loc,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.clearTitle),
        content: Text(loc.clearConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(loc.clear),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await musicFinder.clearLibrary();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.cleared),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

/// Окремий StatefulWidget для перемикача збереження метаданих
class _SaveMetadataSwitch extends StatefulWidget {
  final SettingsService settingsService;

  const _SaveMetadataSwitch({required this.settingsService});

  @override
  State<_SaveMetadataSwitch> createState() => _SaveMetadataSwitchState();
}

class _SaveMetadataSwitchState extends State<_SaveMetadataSwitch> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);

    return SwitchListTile(
      secondary: const Icon(Icons.save_alt),
      title: Text(loc.translate('save_metadata_to_file')),
      subtitle: Text(loc.translate('save_metadata_to_file_desc')),
      value: widget.settingsService.loadSaveMetadataToFile(),
      onChanged: (val) {
        widget.settingsService.saveSaveMetadataToFile(val);
        setState(() {});
      },
    );
  }
}
