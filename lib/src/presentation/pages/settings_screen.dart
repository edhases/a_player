import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'manual_screen.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/settings_service.dart';
import '../../core/services/google_auth_service.dart';
// LocalizationService removed
import '../../core/utils/localization.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../../core/services/metadata_matching_service.dart';
import '../../core/services/cache_service.dart';
import '../../core/services/log_service.dart';
import '../../core/services/telegram_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'webview_login_screen.dart';
import 'cached_tracks_screen.dart';
import 'equalizer_screen.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/services/data_management_service.dart';

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
    // LocalizationService removed
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
          _buildSectionHeader(context, loc.filters),

          // Min Duration
          StatefulBuilder(
            builder: (context, setState) {
              final min = settingsService.loadMinTrackDuration();
              return Column(
                children: [
                  ListTile(
                    title: Text(loc.skipShortTracks),
                    subtitle: Text(loc.translate('skip_short_tracks_desc',
                        args: {'min': min})),
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
            title: Text(loc.excludedFolders),
            subtitle: Text(loc.translate('folders_hidden',
                args: {'count': settingsService.loadExcludedFolders().length})),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _showExcludedFoldersDialog(context, settingsService);
            },
          ),
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
              _showTagScanDialog(context, service.scanEntireLibrary());
            },
          ),

          const Divider(),

          // Cache Section
          _buildSectionHeader(context, loc.cache),
          StatefulBuilder(builder: (context, setState) {
            final currentSize = settingsService.loadMaxCacheSize();
            return Column(
              children: [
                ListTile(
                  title: Text(loc.maxCacheSize),
                  subtitle: Text(loc.translate('cache_usage', args: {
                    'used': _formatBytes(_cacheUsage),
                    'total': _formatBytes(currentSize)
                  })),
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
                  title: Text(loc.viewCachedTracks),
                  subtitle: Text(loc.showDownloadedSongs),
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
              title: Text(loc.clearCache),
              subtitle: Text(loc.clearCacheDesc),
              trailing: const Icon(Icons.delete_forever),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(loc.clearCache),
                    content: Text(loc.clearCacheConfirm),
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
                        SnackBar(content: Text(loc.cacheCleared)),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.cacheServiceUnavailable)),
                    );
                  }
                }
              }),

          const Divider(),

          // Language Section
          _buildSectionHeader(context, loc.language),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return ListTile(
                leading: const Icon(Icons.language),
                title: Text(_getLanguageName(state.locale.languageCode)),
                subtitle: Text(loc.language),
                trailing: DropdownButton<String>(
                  value: state.locale.languageCode,
                  items: [
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

          // Appearance Section
          _buildSectionHeader(context, loc.translate('appearance')),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: Text(loc.translate('theme')),
                    subtitle: Text(_getThemeName(state.themeMode, loc)),
                    trailing: DropdownButton<ThemeMode>(
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
                          context
                              .read<SettingsBloc>()
                              .add(ChangeThemeMode(val));
                        }
                      },
                      underline: const SizedBox(),
                    ),
                  ),
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
                  ListTile(
                    leading: const Icon(Icons.color_lens),
                    title: Text(loc.translate('accent_color')),
                    subtitle: SizedBox(
                      height: 50,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildColorOption(context, null,
                              state.accentColor), // Dynamic/Default
                          _buildColorOption(context, Colors.blue.toARGB32(),
                              state.accentColor),
                          _buildColorOption(context, Colors.red.toARGB32(),
                              state.accentColor),
                          _buildColorOption(context, Colors.green.toARGB32(),
                              state.accentColor),
                          _buildColorOption(context, Colors.orange.toARGB32(),
                              state.accentColor),
                          _buildColorOption(context, Colors.purple.toARGB32(),
                              state.accentColor),
                          _buildColorOption(context, Colors.teal.toARGB32(),
                              state.accentColor),
                          _buildColorOption(context, Colors.pink.toARGB32(),
                              state.accentColor),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          const Divider(),

          // Playback Section
          _buildSectionHeader(context, loc.playback),
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

          // Network Section
          _buildSectionHeader(context, loc.translate('network')),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return SwitchListTile(
                title: Text(loc.translate('wifi_only')),
                subtitle: Text(loc.translate('wifi_only_desc')),
                value: state.wifiOnly,
                onChanged: (val) {
                  context.read<SettingsBloc>().add(ChangeWifiOnly(val));
                },
                secondary: const Icon(Icons.wifi),
              );
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
                    subtitle: Text(loc.personalizedRecommendations),
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

          // Logs Section
          _buildSectionHeader(context, loc.logs),
          BlocBuilder<SettingsBloc, SettingsState>(
            builder: (context, state) {
              return Column(
                children: [
                  ListTile(
                    title: Text(loc.translate('log_history_size')),
                    subtitle: Text(state.maxLogSize == 0
                        ? loc.translate('disabled_not_recommended')
                        : _formatBytes(state.maxLogSize)),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Slider(
                      value: state.maxLogSize.toDouble(),
                      min: 0,
                      max: 50 * 1024 * 1024, // 50 MB
                      divisions: 50,
                      label: state.maxLogSize == 0
                          ? loc.off
                          : _formatBytes(state.maxLogSize),
                      onChanged: (val) {
                        context
                            .read<SettingsBloc>()
                            .add(ChangeMaxLogSize(val.toInt()));
                      },
                      onChangeEnd: (val) {
                        final sizeMB = val / (1024 * 1024);
                        if (val == 0) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title:
                                  Text(loc.translate('logging_disabled_title')),
                              content:
                                  Text(loc.translate('logging_disabled_desc')),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text(loc.ok),
                                ),
                              ],
                            ),
                          );
                        } else if (sizeMB > 0 && sizeMB <= 5) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc.translate('more_logs_needed')),
                              duration: const Duration(seconds: 4),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.send),
            title: Text(loc.sendLogs),
            subtitle: Text(loc.sendLogsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (!GetIt.I.isRegistered<TelegramService>()) return;

              final success = await GetIt.I<TelegramService>().sendLogs();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text(success ? loc.logsSent : loc.logsSendFailed)),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: Text(loc.shareLogs),
            subtitle: Text(loc.shareLogsDesc),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (!GetIt.I.isRegistered<LogService>()) return;
              final file = await GetIt.I<LogService>().getLogFile();
              if (file != null && context.mounted) {
                await Share.shareXFiles([XFile(file.path)],
                    text: 'Oxide Player Logs');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text(loc.clearLogs),
            subtitle: Text(loc.clearLogsDesc),
            onTap: () async {
              if (!GetIt.I.isRegistered<LogService>()) return;
              await GetIt.I<LogService>().clearLogs();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.logsCleared)),
                );
              }
            },
          ),

          const Divider(),

          // Data Management
          _buildSectionHeader(context, loc.translate('data_management')),
          ListTile(
            leading: const Icon(Icons.backup),
            title: Text(loc.translate('backup_data')),
            subtitle: Text(loc.translate('backup_desc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              if (GetIt.I.isRegistered<DataManagementService>()) {
                final file =
                    await GetIt.I<DataManagementService>().createBackup();
                if (file != null && context.mounted) {
                  await Share.shareXFiles([XFile(file.path)],
                      text: 'Oxide Player Backup');
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(loc.translate('backup_success'))));
                  }
                }
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: Text(loc.translate('restore_data')),
            subtitle: Text(loc.translate('restore_desc')),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              try {
                final result = await FilePicker.platform.pickFiles();
                if (result != null && result.files.single.path != null) {
                  final file = File(result.files.single.path!);
                  if (GetIt.I.isRegistered<DataManagementService>()) {
                    final success = await GetIt.I<DataManagementService>()
                        .restoreBackup(file);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success
                            ? loc.translate('restore_success_restart')
                            : loc.translate('error',
                                args: {'error': 'Restore failed'})),
                        backgroundColor: success ? Colors.green : Colors.red,
                      ));
                    }
                  }
                }
              } catch (e) {
                debugPrint('Pick file error: $e');
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(loc.translate('factory_reset'),
                style: const TextStyle(color: Colors.red)),
            subtitle: Text(loc.translate('reset_desc')),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(loc.translate('reset_confirm_title')),
                  content: Text(loc.translate('reset_confirm_message')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(loc.cancel)),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(loc.translate('reset_confirm_action'),
                            style: const TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirmed == true &&
                  GetIt.I.isRegistered<DataManagementService>()) {
                await GetIt.I<DataManagementService>().factoryReset();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Reset complete. Exiting...')));
                  await Future.delayed(const Duration(seconds: 2));
                  exit(0);
                }
              }
            },
          ),
          const Divider(),

          // About Section
          _buildSectionHeader(context, loc.about),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(loc.manualTitle),
            subtitle: const Text('Detailed guide & help'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ManualScreen()),
              );
            },
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.data?.version ?? '';
              final build = snapshot.data?.buildNumber ?? '';
              final displayVersion =
                  version.isEmpty ? 'Debug Build' : '$version ($build)';
              return ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Oxide Player'),
                subtitle: Text(loc
                    .translate('version', args: {'version': displayVersion})),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  final url = Uri.parse(
                      'https://www.paypal.com/donate/?hosted_button_id=MUGPMK7UPCYUW');
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
                icon: const Icon(Icons.favorite, color: Colors.pink),
                label: const Text('Donate via PayPal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).cardColor,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ),
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
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final folders = settings.loadExcludedFolders();
            return AlertDialog(
              title: Text(loc.excludedFolders),
              content: SizedBox(
                width: double.maxFinite,
                child: folders.isEmpty
                    ? Text(loc.noExcludedFolders)
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
                  child: Text(loc.close),
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
    final loc = AppLocalizations.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(loc.scanningLibraryTitle),
          content: StreamBuilder<String>(
            stream: stream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text(
                    loc.translate('error', args: {'error': snapshot.error}));
              }
              final status = snapshot.data ?? loc.scanStarting;

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
              child: Text(loc.close),
            ),
          ],
        );
      },
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
      case 'en':
      default:
        return 'English';
    }
  }

  Widget _buildColorOption(
      BuildContext context, int? colorValue, int? selectedValue) {
    // If colorValue is null, it represents "System/Default"
    final isSelected = colorValue == selectedValue;
    final color = colorValue != null
        ? Color(colorValue)
        : Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: () {
        context.read<SettingsBloc>().add(ChangeAccentColor(colorValue));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface, width: 2)
                : null,
            boxShadow: [
              if (colorValue == null) // Special style for dynamic/default
                BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.5), blurRadius: 2)
            ]),
        child: colorValue == null
            ? const Icon(Icons.auto_awesome, size: 16, color: Colors.white)
            : (isSelected
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : null),
      ),
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
}
