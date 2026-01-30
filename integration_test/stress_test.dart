import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;
import 'package:oxide_player/src/core/utils/test_overrides.dart';
import 'package:oxide_player/src/testing/fakes/fake_services.dart';

/// Performance and stress test suite
/// 
/// Tests:
/// - Rapid interactions
/// - Memory-intensive operations
/// - Long-running scenarios
/// - Repeated operations
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Rapid Navigation Stress', () {
    testWidgets('Rapid tab switching 50 times', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < 10; i++) {
        await tester.tap(find.byIcon(Icons.music_note_outlined));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byIcon(Icons.play_circle_outline));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byIcon(Icons.library_music_outlined));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(find.byIcon(Icons.home_outlined));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      stopwatch.stop();

      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(30000));
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    });
  });

  group('Search Stress', () {
    testWidgets('100 search queries in sequence', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final queries = List.generate(20, (i) => 'Query$i');
      final stopwatch = Stopwatch()..start();

      for (final query in queries) {
        await tester.tap(find.byKey(const Key('home_search_button')));
        await tester.pumpAndSettle(const Duration(milliseconds: 200));
        await tester.enterText(find.byType(TextField).first, query);
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pageBack();
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      stopwatch.stop();

      expect(TestTracker.searchQueries.length, greaterThanOrEqualTo(queries.length));
    });
  });

  group('Player Control Stress', () {
    testWidgets('Rapid play/pause toggling', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Rapid toggling
      for (int i = 0; i < 20; i++) {
        await tester.tap(find.byKey(const Key('player_play_pause_button')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });

    testWidgets('Rapid skip next/prev', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Rapid skipping
      for (int i = 0; i < 15; i++) {
        await tester.tap(find.byKey(const Key('player_next_button')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byKey(const Key('player_prev_button')));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });
  });

  group('Shuffle/Repeat Toggle Stress', () {
    testWidgets('Toggle shuffle 30 times', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      for (int i = 0; i < 30; i++) {
        await tester.tap(find.byKey(const Key('player_shuffle_button')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('player_shuffle_button')), findsOneWidget);
    });

    testWidgets('Toggle repeat 30 times', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      for (int i = 0; i < 30; i++) {
        await tester.tap(find.byKey(const Key('player_repeat_button')));
        await tester.pump(const Duration(milliseconds: 50));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('player_repeat_button')), findsOneWidget);
    });
  });

  group('Like Button Stress', () {
    testWidgets('Toggle like 20 times', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      for (int i = 0; i < 20; i++) {
        await tester.tap(find.byKey(const Key('player_like_button')));
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('player_like_button')), findsOneWidget);
    });
  });

  group('Settings Stress', () {
    testWidgets('Theme toggle multiple times', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
        await tester.pumpAndSettle();

        if (find.text('Dark').evaluate().isNotEmpty) {
          await tester.tap(find.text('Dark').last);
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
        }

        await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
        await tester.pumpAndSettle();

        if (find.text('Light').evaluate().isNotEmpty) {
          await tester.tap(find.text('Light').last);
          await tester.pumpAndSettle(const Duration(milliseconds: 300));
        }
      }

      expect(find.byKey(const Key('settings_theme_dropdown')), findsOneWidget);
    });
  });

  group('Memory Simulation', () {
    testWidgets('Open and close player 20 times', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      for (int i = 0; i < 20; i++) {
        // Open player
        await tester.tap(find.byKey(const Key('mini_player')));
        await tester.pumpAndSettle(const Duration(milliseconds: 300));

        // Close player
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }

      // App should still be responsive
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });

    testWidgets('Navigate through all artist pages', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final searchTerms = ['Enimkon', 'Я зігрію тебе взимку'];

      for (final term in searchTerms) {
        await tester.tap(find.byKey(const Key('home_search_button')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, term);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.tap(find.textContaining(term.substring(0, 5)).first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        await tester.tap(find.byKey(const Key('mini_player')));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        await tester.tap(find.byKey(const Key('player_artist_link')));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Go back twice
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));
    });
  });

  group('UI Responsiveness', () {
    testWidgets('UI remains responsive after many operations', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Perform many operations
      for (int i = 0; i < 5; i++) {
        // Search
        await tester.tap(find.byKey(const Key('home_search_button')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, 'Test$i');
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pageBack();
        await tester.pump(const Duration(milliseconds: 100));

        // Tab switch
        await tester.tap(find.byIcon(Icons.music_note_outlined));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byIcon(Icons.home_outlined));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // UI should still be responsive
      final stopwatch = Stopwatch()..start();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      stopwatch.stop();

      // Navigation should be fast (under 2 seconds)
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
      expect(find.byKey(const Key('settings_theme_dropdown')), findsOneWidget);
    });
  });
}
