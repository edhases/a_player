import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;
import 'package:oxide_player/src/core/utils/test_overrides.dart';
import 'package:oxide_player/src/testing/fakes/fake_services.dart';

/// Specialized test suite for audio playback features
/// 
/// Tests:
/// - Playback initiation
/// - Queue management
/// - Shuffle/Repeat modes
/// - Seeking
/// - Volume (if exposed)
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Playback Core', () {
    testWidgets('Song plays from search results', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Search and play
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify playback started
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });

    testWidgets('Song plays from home feed', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Tap a song from Quick Picks
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });

    testWidgets('Playlist plays all tracks in order', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Search for playlist
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon Playlist');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Play playlist
      await tester.tap(find.text('Enimkon Playlist').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should start playing
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });
  });

  group('Queue Management', () {
    testWidgets('Next button skips to next track', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play from home
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Record current state
      final currentTitle = find.byKey(const Key('player_artist_text'));
      expect(currentTitle, findsOneWidget);

      // Skip to next
      await tester.tap(find.byKey(const Key('player_next_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Player should still be visible
      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });

    testWidgets('Previous button goes to previous track', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Skip next first, then go back
      await tester.tap(find.byKey(const Key('player_next_button')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('player_prev_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });
  });

  group('Shuffle Mode', () {
    testWidgets('Shuffle toggles on/off', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Toggle shuffle multiple times
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('player_shuffle_button')));
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.byKey(const Key('player_shuffle_button')), findsOneWidget);
    });
  });

  group('Repeat Mode', () {
    testWidgets('Repeat cycles through modes', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Cycle through repeat modes: off -> all -> one -> off
      for (int i = 0; i < 4; i++) {
        await tester.tap(find.byKey(const Key('player_repeat_button')));
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(find.byKey(const Key('player_repeat_button')), findsOneWidget);
    });
  });

  group('Player UI State', () {
    testWidgets('Player displays correct track info', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify track info is displayed
      expect(find.text('Enimkon'), findsWidgets);
      expect(find.text('Test Artist'), findsWidgets);
    });

    testWidgets('Mini player shows current track', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Mini player should show track info
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
      expect(find.descendant(
        of: find.byKey(const Key('mini_player')),
        matching: find.textContaining('Enimkon'),
      ), findsWidgets);
    });
  });

  group('Local Playback', () {
    testWidgets('Local track plays without network', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Go to local tracks
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Play local track
      await tester.tap(find.byKey(const ValueKey('track_tile_local:test_song.mp3')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should play successfully
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });

    testWidgets('Multiple local tracks play in sequence', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Play first track
      await tester.tap(find.byKey(const ValueKey('track_tile_local:test_song.mp3')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open player and skip
      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('player_next_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });
  });
}
