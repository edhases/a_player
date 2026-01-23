import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;

// Note: Integration tests require a running device or emulator.
// To run: flutter test integration_test/app_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Test', () {
    testWidgets('App starts and loads Home Screen', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify Home Screen appears by checking for a known widget or text
      // We expect 'Oxide Player' or 'Home' title depending on localization
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

      // Verify Bottom Navigation Bar exists
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.library_music), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      // Navigate to Settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();

      // Check for 'Settings' title
      expect(find.text('Settings'), findsAny); // Could be in AppBar or List
    });
  });
}
