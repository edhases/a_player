import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';

import '../../core/services/music_finder.dart';
import '../../core/services/settings_service.dart'; // Add SettingsService
import '../../core/services/google_auth_service.dart';
import '../../core/services/localization_service.dart';
import '../../core/utils/localization.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../core/services/cache_service.dart';
import 'webview_login_screen.dart';
import 'cached_tracks_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _cacheUsage = 0;

  @override
  void initState() {
    super.initState();
    _loadCacheUsage();
  }

  Future<void> _loadCacheUsage() async {
    if (GetIt.I.isRegistered<CacheService>()) {
      final usage = await GetIt.I<CacheService>().getCacheUsage();
      if (mounted) {
        setState(() {
          _cacheUsage = usage;
        });
      }
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final musicFinder = GetIt.I<MusicFinder>();
    final settingsService = GetIt.I<SettingsService>();
    final authService = GetIt.I<GoogleAuthService>();
    final localizationService = Provider.of<LocalizationService>(context);
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.settings),
      ),
      body: ListView(
        children: [
          // Library Section
          _buildSectionHeader(context, loc.library),
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
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(loc.clearLibrary),
            subtitle: Text(loc.clearDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
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
            },
          ),

          const Divider(),

          // Library Filters Section
          _buildSectionHeader(context, 'Filters'),

          // Min Duration
          StatefulBuilder(
            builder: (context, setState) {
              final min = settingsService.loadMinTrackDuration();
              return Column(
                children: [
                  ListTile(
                    title: const Text('Skip Short Tracks'),
                    subtitle: Text('Less than $min seconds'),
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
                        setState(() {
                          settingsService.saveMinTrackDuration(val.toInt());
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),

          // Max Duration
          StatefulBuilder(builder: (context, setState) {
            final max = settingsService.loadMaxTrackDuration();
            return Column(
              children: [
                ListTile(
                  title: const Text('Skip Long Tracks'),
                  subtitle:
                      Text(max == 0 ? 'No Limit' : 'More than ${max ~/ 60}m'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: max.toDouble(),
                    min: 0,
                    max: 3600, // 1 hour max for slider
                    divisions: 60,
                    label: max == 0 ? 'Off' : '${max ~/ 60}m',
                    onChanged: (val) {
                      setState(() {
                        settingsService.saveMaxTrackDuration(val.toInt());
                      });
                    },
                  ),
                ),
              ],
            );
          }),

          // Excluded Folders
          ListTile(
            title: Text('Excluded Folders'),
            subtitle: Text(
                '${settingsService.loadExcludedFolders().length} folders hidden'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showExcludedFoldersDialog(context, settingsService);
            },
          ),
          ListTile(
            leading: const Icon(Icons.auto_fix_high),
            title: const Text('Match Metadata (Beta)'),
            subtitle: const Text('Auto-tag unknown tracks from YouTube'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (!GetIt.I.isRegistered<MetadataMatchingService>()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Service not available')),
                );
                return;
              }
              final service = GetIt.I<MetadataMatchingService>();
              _showTagScanDialog(context, service.scanEntireLibrary());
            },
          ),

          const Divider(),

          // Cache Section
          _buildSectionHeader(context, 'Cache'),
          StatefulBuilder(builder: (context, setState) {
            final currentSize = settingsService.loadMaxCacheSize();
            return Column(
              children: [
                ListTile(
                  title: const Text('Max Cache Size'),
                  subtitle: Text(
                      'Used: ${_formatBytes(_cacheUsage)} / ${_formatBytes(currentSize)}'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Slider(
                    value: currentSize.toDouble(),
                    min: 512 * 1024 * 1024,
                    max: 24 * 1024 * 1024 * 1024,
                    divisions: 47,
                    label: _formatBytes(currentSize),
                    onChanged: (val) {
                      final newSize = val.toInt();
                      settingsService.saveMaxCacheSize(newSize);
                      if (GetIt.I.isRegistered<CacheService>()) {
                        GetIt.I<CacheService>().setMaxCacheSize(newSize);
                      }
                      setState(() {});
                    },
                    onChangeEnd: (_) => _loadCacheUsage(),
                  ),
                ),
                ListTile(
                  title: const Text('View Cached Tracks'),
                  subtitle: const Text('Show downloaded songs'),
                  trailing: const Icon(Icons.queue_music),
                  onTap: () {
                    Navigator.of(context)
                        .push(MaterialPageRoute(
                            builder: (_) => const CachedTracksScreen()))
                        .then((_) => _loadCacheUsage());
                  },
                ),
              ],
            );
          }),
          ListTile(
              title: const Text('Clear Cache'),
              subtitle: const Text('Remove all downloaded songs'),
              trailing: const Icon(Icons.delete_forever),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cache'),
                    content: const Text(
                        'Are you sure you want to delete all cached songs?'),
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
                  if (GetIt.I.isRegistered<CacheService>()) {
                    await GetIt.I<CacheService>().clearCache();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cache cleared')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Cache Service unavailable')),
                    );
                  }
                }
              }),

          const Divider(),

          // Language Section
          _buildSectionHeader(context, loc.language),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(localizationService.currentLocale.languageCode == 'en'
                ? 'English'
                : 'Українська'),
            subtitle: Text(loc.language),
            trailing: DropdownButton<String>(
              value: localizationService.currentLocale.languageCode,
              items: [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'uk', child: Text('Українська')),
              ],
              onChanged: (value) {
                if (value != null) {
                  localizationService.changeLanguage(value);
                }
              },
              underline: const SizedBox(),
            ),
          ),

          const Divider(),

          // Playback Section
          _buildSectionHeader(context, loc.playback),
          ListTile(
            leading: const Icon(Icons.equalizer),
            title: Text(loc.equalizer),
            subtitle: const Text('Adjust audio frequencies'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to equalizer
            },
          ),

          const Divider(),

          // YouTube Section
          _buildSectionHeader(context, loc.youtube),
          FutureBuilder<bool>(
            future: authService.isSignedIn(),
            builder: (context, snapshot) {
              final isSignedIn = snapshot.data ?? false;
              return Column(
                children: [
                  ListTile(
                    leading: Icon(
                      isSignedIn ? Icons.check_circle : Icons.cancel,
                      color: isSignedIn ? Colors.green : Colors.red,
                    ),
                    title: Text(isSignedIn ? loc.signedIn : loc.notSignedIn),
                    subtitle: const Text('Personalized recommendations'),
                  ),
                  if (isSignedIn)
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: Text(loc.reauth),
                      subtitle: Text(loc.reauthDesc),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        final success = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WebViewLoginScreen(),
                          ),
                        );
                        if (success == true && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.cookiesUpdated),
                              backgroundColor: Colors.green,
                            ),
                          );
                          setState(() {}); // Refresh the UI
                        }
                      },
                    ),
                ],
              );
            },
          ),

          const Divider(),

          // About Section
          _buildSectionHeader(context, loc.about),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Oxide Player'),
            subtitle: const Text('Version 1.0.0'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  void _showExcludedFoldersDialog(
      BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final folders = settings.loadExcludedFolders();
            return AlertDialog(
              title: const Text('Excluded Folders'),
              content: SizedBox(
                width: double.maxFinite,
                child: folders.isEmpty
                    ? const Text('No excluded folders.')
                    : ListView.builder(
                        itemCount: folders.length,
                        itemBuilder: (context, index) {
                          final folder = folders[index];
                          return ListTile(
                            title: Text(_basename(folder)),
                            subtitle: Text(folder,
                                style: const TextStyle(fontSize: 10)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                settings.removeExcludedFolder(folder).then((_) {
                                  setState(() {});
                                });
                              },
                            ),
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _basename(String path) {
    // simple basename to avoid path import if not present
    return path.split(RegExp(r'[/\\]')).last;
  }

  void _showTagScanDialog(BuildContext context, Stream<String> stream) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Scanning Library...'),
          content: StreamBuilder<String>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              final status = snapshot.data ?? 'Starting...';

              // Closing logic when complete
              if (status.startsWith('Scan complete')) {
                // Future.microtask to avoid build phase navigation
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) Navigator.pop(context);
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(status, textAlign: TextAlign.center),
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                  'Close'), // Allow verifying "Scan complete" manually if needed
            ),
          ],
        );
      },
    );
  }
}
