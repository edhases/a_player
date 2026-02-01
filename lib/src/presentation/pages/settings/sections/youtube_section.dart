import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../../../../core/services/google_auth_service.dart';
import '../../../../core/utils/localization.dart';
import '../settings_section_header.dart';
import '../../webview_login_screen.dart';

/// Секція налаштувань YouTube
///
/// Включає:
/// - Статус авторизації
/// - Повторна авторизація
class YouTubeSection extends StatefulWidget {
  const YouTubeSection({super.key});

  @override
  State<YouTubeSection> createState() => _YouTubeSectionState();
}

class _YouTubeSectionState extends State<YouTubeSection> {
  @override
  Widget build(BuildContext context) {
    final authService = GetIt.I<GoogleAuthService>();
    final loc = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: loc.youtube),
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
      ],
    );
  }
}
