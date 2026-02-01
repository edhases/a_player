import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/metadata_matching_service.dart';
import '../../../../core/utils/localization.dart';
import '../settings_section_header.dart';

/// Секція фільтрів бібліотеки
///
/// Включає:
/// - Мінімальна тривалість треків
/// - Максимальна тривалість треків
/// - Виключені папки
/// - Відповідність метаданих
class FiltersSection extends StatelessWidget {
  final VoidCallback? onExcludedFoldersPressed;
  final void Function(Stream<String>)? onTagScanPressed;

  const FiltersSection({
    super.key,
    this.onExcludedFoldersPressed,
    this.onTagScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final settingsService = GetIt.I<SettingsService>();
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: loc.filters),

        // Min Duration Slider
        _MinDurationSlider(settingsService: settingsService),

        // Max Duration Slider
        _MaxDurationSlider(settingsService: settingsService),

        // Excluded Folders
        ListTile(
          title: Text(loc.excludedFolders),
          subtitle: Text(loc.translate('folders_hidden',
              args: {'count': settingsService.loadExcludedFolders().length})),
          trailing: const Icon(Icons.chevron_right),
          onTap: onExcludedFoldersPressed,
        ),

        // Match Metadata
        ListTile(
          leading: const Icon(Icons.auto_fix_high),
          title: Text(loc.matchMetadata),
          subtitle: Text(loc.matchMetadataDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            if (!GetIt.I.isRegistered<MetadataMatchingService>()) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(loc.serviceNotAvailable)),
              );
              return;
            }
            final service = GetIt.I<MetadataMatchingService>();
            onTagScanPressed?.call(service.scanEntireLibrary());
          },
        ),

        const Divider(),
      ],
    );
  }
}

class _MinDurationSlider extends StatefulWidget {
  final SettingsService settingsService;

  const _MinDurationSlider({required this.settingsService});

  @override
  State<_MinDurationSlider> createState() => _MinDurationSliderState();
}

class _MinDurationSliderState extends State<_MinDurationSlider> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final min = widget.settingsService.loadMinTrackDuration();

    return Column(
      children: [
        ListTile(
          title: Text(loc.skipShortTracks),
          subtitle:
              Text(loc.translate('skip_short_tracks_desc', args: {'min': min})),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: min.toDouble(),
            min: 0,
            max: 120,
            divisions: 24,
            label: '$min s',
            onChanged: (val) {
              widget.settingsService.saveMinTrackDuration(val.toInt());
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}

class _MaxDurationSlider extends StatefulWidget {
  final SettingsService settingsService;

  const _MaxDurationSlider({required this.settingsService});

  @override
  State<_MaxDurationSlider> createState() => _MaxDurationSliderState();
}

class _MaxDurationSliderState extends State<_MaxDurationSlider> {
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final max = widget.settingsService.loadMaxTrackDuration();

    return Column(
      children: [
        ListTile(
          title: Text(loc.skipLongTracks),
          subtitle: Text(max == 0
              ? loc.noLimit
              : loc.translate('skip_long_tracks_desc',
                  args: {'max': max ~/ 60})),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Slider(
            value: max.toDouble(),
            min: 0,
            max: 3600, // 1 hour max for slider
            divisions: 60,
            label: max == 0 ? loc.off : '${max ~/ 60}m',
            onChanged: (val) {
              widget.settingsService.saveMaxTrackDuration(val.toInt());
              setState(() {});
            },
          ),
        ),
      ],
    );
  }
}
