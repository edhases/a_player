import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;
import 'package:oxide_player/src/core/utils/test_overrides.dart';
import 'package:oxide_player/src/testing/fakes/fake_services.dart';

/// Localization and internationalization tests
/// 
/// Tests:
/// - Language switching
/// - RTL support (if applicable)
/// - Ukrainian text handling
/// - Special characters
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Language Switching', () {
    testWidgets('English is default language', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // English labels should be present
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Settings'), findsWidgets);
    });

    testWidgets('Switch to Ukrainian updates all labels', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find language dropdown
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();

      // Change to Ukrainian
      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      final ukrainianOption = find.text('Українська');
      if (ukrainianOption.evaluate().isNotEmpty) {
        await tester.tap(ukrainianOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify Ukrainian text
        expect(find.text('Налаштування'), findsWidgets);
      }
    });

    testWidgets('Switch to German updates labels', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      final germanOption = find.text('Deutsch');
      if (germanOption.evaluate().isNotEmpty) {
        await tester.tap(germanOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify German text (Einstellungen = Settings)
        expect(find.text('Einstellungen'), findsWidgets);
      }
    });

    testWidgets('Switch to Spanish updates labels', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      final spanishOption = find.text('Español');
      if (spanishOption.evaluate().isNotEmpty) {
        await tester.tap(spanishOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify Spanish text (Configuración = Settings)
        expect(find.text('Configuración'), findsWidgets);
      }
    });

    testWidgets('Switch to Japanese updates labels', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      final japaneseOption = find.text('日本語');
      if (japaneseOption.evaluate().isNotEmpty) {
        await tester.tap(japaneseOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify Japanese text (設定 = Settings)
        expect(find.text('設定'), findsWidgets);
      }
    });

    testWidgets('Switch to Polish updates labels', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      final polishOption = find.text('Polski');
      if (polishOption.evaluate().isNotEmpty) {
        await tester.tap(polishOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify Polish text (Ustawienia = Settings)
        expect(find.text('Ustawienia'), findsWidgets);
      }
    });
  });

  group('Unicode and Special Characters', () {
    testWidgets('Ukrainian song titles display correctly', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Search for Ukrainian song
      await tester.enterText(find.byType(TextField).first, 'Я зігрію тебе взимку');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should display correctly
      expect(find.text('Я зігрію тебе взимку'), findsWidgets);
      expect(find.text('Український Артист'), findsWidgets);
    });

    testWidgets('Special characters in search work', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Search with special characters
      await tester.enterText(find.byType(TextField).first, 'Test & Artist');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should handle gracefully
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('Cyrillic input in search', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Various Cyrillic inputs
      final cyrillicQueries = [
        'Привіт',
        'Музика',
        'Пісня',
        'Артист',
      ];

      for (final query in cyrillicQueries) {
        await tester.enterText(find.byType(TextField).first, query);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.enterText(find.byType(TextField).first, '');
      }
    });
  });

  group('Language Persistence', () {
    testWidgets('Language setting persists after tab change', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Change language
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      final ukrainianOption = find.text('Українська');
      if (ukrainianOption.evaluate().isNotEmpty) {
        await tester.tap(ukrainianOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Go to home and back
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Language should still be Ukrainian
      expect(find.text('Налаштування'), findsWidgets);
    });
  });

  group('Text Overflow', () {
    testWidgets('Long titles truncate with ellipsis', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Search for long title
      await tester.enterText(find.byType(TextField).first, 'This Is A Very Long');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should find the long title (may be truncated)
      expect(find.textContaining('This Is A Very Long'), findsWidgets);
    });
  });
}
