import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;
import 'package:oxide_player/src/core/utils/test_overrides.dart';
import 'package:oxide_player/src/testing/fakes/fake_services.dart';

/// Specialized test suite for UI navigation and interactions
/// 
/// Tests:
/// - Screen transitions
/// - Back navigation
/// - Gestures
/// - Modal dialogs
/// - Context menus
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Screen Transitions', () {
    testWidgets('Home -> Settings -> Back', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('settings_theme_dropdown')), findsOneWidget);

      // Go back to home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    });

    testWidgets('Search -> Results -> Song -> Player -> Back', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open search
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Search
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Play result
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open player
      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('player_screen')), findsOneWidget);

      // Back to search
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Back to home
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    });

    testWidgets('Player -> Artist Page -> Back to Player', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Go to artist
      await tester.tap(find.byKey(const Key('player_artist_link')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('playlist_tracks_screen')), findsOneWidget);

      // Back to player
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Player might still be visible or we're at previous screen
    });
  });

  group('Tab Navigation', () {
    testWidgets('All tabs are accessible', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Home tab
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);

      // Tracks tab
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('all_tracks_screen')), findsOneWidget);

      // YouTube tab
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('YouTube Music'), findsWidgets);

      // Library tab
      await tester.tap(find.byIcon(Icons.library_music_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('library_screen')), findsOneWidget);

      // Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('settings_theme_dropdown')), findsOneWidget);
    });

    testWidgets('Tab state is preserved', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to library and change view
      await tester.tap(find.byIcon(Icons.library_music_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Change view mode
      await tester.tap(find.byKey(const Key('library_view_mode_dropdown')));
      await tester.pumpAndSettle();

      if (find.text('Albums').evaluate().isNotEmpty) {
        await tester.tap(find.text('Albums').last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }

      // Go to another tab
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Come back to library
      await tester.tap(find.byIcon(Icons.library_music_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Library screen should still be there
      expect(find.byKey(const Key('library_screen')), findsOneWidget);
    });
  });

  group('Modal Dialogs', () {
    testWidgets('Player options menu opens', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Open options
      await tester.tap(find.byKey(const Key('player_options_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Download option should be visible
      expect(find.byKey(const Key('player_download_action')), findsOneWidget);
    });

    testWidgets('Clear cache confirmation dialog', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll to clear cache
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_clear_cache')),
        200,
      );
      await tester.pumpAndSettle();

      // Tap clear cache
      await tester.tap(find.byKey(const Key('settings_clear_cache')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Dialog should appear
      expect(find.byType(AlertDialog), findsOneWidget);
    });
  });

  group('Scroll Behavior', () {
    testWidgets('Settings screen scrolls', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll down
      await tester.drag(find.byType(ListView).first, const Offset(0, -500));
      await tester.pumpAndSettle();

      // Scroll up
      await tester.drag(find.byType(ListView).first, const Offset(0, 500));
      await tester.pumpAndSettle();
    });

    testWidgets('Home feed sections scroll horizontally', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find a horizontal scroll area
      final scrollable = find.byType(SingleChildScrollView);
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable.first, const Offset(-200, 0));
        await tester.pumpAndSettle();
      }
    });
  });

  group('Search Behavior', () {
    testWidgets('Search clears on new search', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // First search
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'First');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Clear and new search
      await tester.enterText(find.byType(TextField).first, '');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Second');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(TestTracker.searchQueries, contains('Second'));
    });

    testWidgets('Search handles rapid input', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Type rapidly
      await tester.enterText(find.byType(TextField).first, 'a');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField).first, 'ab');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField).first, 'abc');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField).first, 'abcd');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should handle gracefully
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('Mini Player Interaction', () {
    testWidgets('Mini player expands to full player', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byKey(const Key('mini_player')), findsOneWidget);

      // Tap to expand
      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });

    testWidgets('Mini player visible across tabs', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to different tabs - mini player should persist
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('mini_player')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.library_music_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('mini_player')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });
  });
}
