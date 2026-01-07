import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/music_finder.dart';
import '../../core/services/settings_service.dart';
import '../../data/datasources/app_database.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final musicFinder = Provider.of<MusicFinder>(context, listen: false);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Library Section
          _buildSectionHeader(context, 'Library'),
          ValueListenableBuilder<bool>(
            valueListenable: musicFinder.isScanning,
            builder: (context, isScanning, child) {
              return ListTile(
                leading: Icon(
                  Icons.refresh,
                  color: isScanning ? colorScheme.primary : null,
                ),
                title: const Text('Scan Music Library'),
                subtitle: ValueListenableBuilder<String>(
                  valueListenable: musicFinder.scanStatus,
                  builder: (context, status, _) {
                    return Text(
                      isScanning 
                          ? (status.isNotEmpty ? status : 'Scanning...')
                          : 'Scan device for all music files',
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
                            const SnackBar(
                              content: Text('Library scan complete!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Library'),
            subtitle: const Text('Remove all tracks from the database'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Clear Library?'),
                  content: const Text(
                    'This will remove all tracks from the library. You will need to scan your music folders again.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear'),
                    ),
                  ],
                ),
              );
              
              if (confirmed == true && context.mounted) {
                await musicFinder.clearLibrary();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Library cleared!'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
          ),
          
          const Divider(),
          
          // Playback Section
          _buildSectionHeader(context, 'Playback'),
          ListTile(
            leading: const Icon(Icons.equalizer),
            title: const Text('Equalizer'),
            subtitle: const Text('Adjust audio frequencies'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // TODO: Navigate to equalizer
            },
          ),
          
          const Divider(),
          
          // About Section
          _buildSectionHeader(context, 'About'),
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
}
