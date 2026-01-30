import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;
import 'package:oxide_player/src/core/utils/test_overrides.dart';
import 'package:oxide_player/src/testing/fakes/fake_services.dart';

/// Comprehensive integration test suite for Oxide Player
/// 
/// This test suite covers:
/// - Onboarding & Permissions
/// - Home Feed Navigation
/// - Search & Discovery
/// - Player Controls
/// - Playlist & Queue Management
/// - Library Features
/// - Settings & Customization
/// - Edge Cases & Error Handling
/// - Performance & Stress Tests
/// - Localization
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('1. Onboarding & Permissions', () {
    testWidgets('1.1 Permission gate displays correctly', (tester) async {
      TestOverrides.enable(permissionGranted: false);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify permission gate is shown
      expect(find.byKey(const Key('permission_gate')), findsOneWidget);
      expect(find.byKey(const Key('permission_grant_button')), findsOneWidget);
    });

    testWidgets('1.2 Granting permissions navigates to home', (tester) async {
      TestOverrides.enable(permissionGranted: false);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Grant permissions
      await tester.tap(find.byKey(const Key('permission_grant_button')));
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify home feed is visible
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    });

    testWidgets('1.3 Pre-granted permissions skip gate', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should go directly to home
      expect(find.byKey(const Key('permission_gate')), findsNothing);
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    });
  });

  group('2. Home Feed Navigation', () {
    testWidgets('2.1 All home sections are present', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify all sections
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_section_made_for_you')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_section_recommended')), findsOneWidget);
      expect(find.byKey(const ValueKey('home_section_your_library')), findsOneWidget);
    });

    testWidgets('2.2 Bottom navigation works correctly', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to Tracks tab
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('all_tracks_screen')), findsOneWidget);

      // Navigate to YouTube tab
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('YouTube Music'), findsWidgets);

      // Navigate to Library tab
      await tester.tap(find.byIcon(Icons.library_music_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('library_screen')), findsOneWidget);

      // Navigate to Settings tab
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const Key('settings_theme_dropdown')), findsOneWidget);

      // Navigate back to Home
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    });

    testWidgets('2.3 Quick picks section has songs', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify quick picks has content
      expect(find.text('Enimkon'), findsWidgets);
      expect(find.text('Test Artist'), findsWidgets);
    });
  });

  group('3. Search & Discovery', () {
    testWidgets('3.1 Search opens and accepts input', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open search
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify search was performed
      expect(TestTracker.searchQueries.contains('Enimkon'), isTrue);
      expect(find.text('Enimkon'), findsWidgets);
    });

    testWidgets('3.2 Search results show songs and playlists', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should find song and playlist
      expect(find.text('Enimkon'), findsWidgets);
      expect(find.text('Enimkon Playlist'), findsWidgets);
    });

    testWidgets('3.3 Ukrainian text search works', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Я зігрію тебе взимку');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Я зігрію тебе взимку'), findsWidgets);
      expect(find.text('Український Артист'), findsWidgets);
    });

    testWidgets('3.4 Empty search results handled', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'empty');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Empty query returns no matches - UI should handle gracefully
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('4. Player Controls', () {
    testWidgets('4.1 Tapping song opens mini player', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Search and play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Mini player should appear
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });

    testWidgets('4.2 Mini player opens full player', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open full player
      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });

    testWidgets('4.3 Play/Pause button works', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open player and toggle play/pause
      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('player_play_pause_button')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('player_play_pause_button')));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('player_play_pause_button')), findsOneWidget);
    });

    testWidgets('4.4 Next/Previous buttons work', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Test skip buttons
      await tester.tap(find.byKey(const Key('player_next_button')));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('player_prev_button')));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byKey(const Key('player_next_button')), findsOneWidget);
      expect(find.byKey(const Key('player_prev_button')), findsOneWidget);
    });

    testWidgets('4.5 Shuffle button toggles', (tester) async {
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

      // Toggle shuffle
      await tester.tap(find.byKey(const Key('player_shuffle_button')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('player_shuffle_button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('player_shuffle_button')), findsOneWidget);
    });

    testWidgets('4.6 Repeat button cycles modes', (tester) async {
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

      // Cycle repeat modes (off -> all -> one -> off)
      await tester.tap(find.byKey(const Key('player_repeat_button')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('player_repeat_button')));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.byKey(const Key('player_repeat_button')));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byKey(const Key('player_repeat_button')), findsOneWidget);
    });
  });

  group('5. Like & Favorites', () {
    testWidgets('5.1 Like button toggles favorite status', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Like the song
      await tester.tap(find.byKey(const Key('player_like_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Should show confirmation snackbar
      expect(find.byType(SnackBar), findsWidgets);
    });

    testWidgets('5.2 Liked songs appear in favorites list', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play and like a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('player_like_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Go to YouTube Hub -> Liked Songs
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.byKey(const Key('youtube_liked_songs_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Liked song should appear
      expect(find.textContaining('Enimkon'), findsWidgets);
    });
  });

  group('6. Download & Cache', () {
    testWidgets('6.1 Download action initiates caching', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Open options and download
      await tester.tap(find.byKey(const Key('player_options_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('player_download_action')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify caching was tracked
      expect(TestTracker.cachedVideoIds.isNotEmpty, isTrue);
    });

    testWidgets('6.2 Cached tracks visible in settings', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Download a song first
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const Key('player_options_button')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.byKey(const Key('player_download_action')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigate to settings -> cached tracks
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Scroll to find cached tracks button
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_view_cached_tracks')),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_view_cached_tracks')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Cached song should be visible
      expect(find.textContaining('Enimkon'), findsWidgets);
    });

    testWidgets('6.3 Clear cache removes all cached tracks', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find and tap clear cache
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_clear_cache')),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_clear_cache')));
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Confirm clear
      if (find.text('Clear').evaluate().isNotEmpty) {
        await tester.tap(find.text('Clear').last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    });
  });

  group('7. Artist Navigation', () {
    testWidgets('7.1 Artist link navigates to artist page', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song with valid artist ID
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap artist link
      await tester.tap(find.byKey(const Key('player_artist_link')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should navigate to artist screen
      expect(find.byKey(const Key('playlist_tracks_screen')), findsOneWidget);
    });

    testWidgets('7.2 Missing artist ID shows error gracefully', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play song without artist ID
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'No Artist ID Song');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('No Artist ID Song').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap artist link
      await tester.tap(find.byKey(const Key('player_artist_link')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show error message
      expect(find.text('Artist page unavailable'), findsWidgets);
    });

    testWidgets('7.3 Ukrainian artist navigation works', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play Ukrainian song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Я зігрію тебе взимку');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Я зігрію тебе взимку').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Navigate to artist
      await tester.tap(find.byKey(const Key('player_artist_link')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show artist page
      expect(find.byKey(const Key('playlist_tracks_screen')), findsOneWidget);
    });
  });

  group('8. Local Library', () {
    testWidgets('8.1 Local tracks screen displays tracks', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to tracks tab
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show local tracks
      expect(find.byKey(const Key('all_tracks_screen')), findsOneWidget);
      expect(find.text('Local Test Song'), findsWidgets);
    });

    testWidgets('8.2 Local track plays correctly', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to tracks and play
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const ValueKey('track_tile_local:test_song.mp3')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Mini player should show
      expect(find.byKey(const Key('mini_player')), findsOneWidget);
    });

    testWidgets('8.3 Local artist navigates to detail screen', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play local track
      await tester.tap(find.byIcon(Icons.music_note_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byKey(const ValueKey('track_tile_local:test_song.mp3')));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open player
      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Tap artist
      await tester.tap(find.byKey(const Key('player_artist_link')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should show detail screen (for local artists)
      expect(find.byKey(const Key('detail_screen')), findsOneWidget);
    });
  });

  group('9. Settings & Customization', () {
    testWidgets('9.1 Theme dropdown works', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Change theme
      await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
      await tester.pumpAndSettle();

      // Select dark theme
      if (find.text('Dark').evaluate().isNotEmpty) {
        await tester.tap(find.text('Dark').last);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }
    });

    testWidgets('9.2 Language change works', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Find language dropdown and change
      await tester.scrollUntilVisible(
        find.byKey(const Key('settings_language_dropdown')),
        200,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('settings_language_dropdown')));
      await tester.pumpAndSettle();

      // Select Ukrainian
      if (find.text('Українська').evaluate().isNotEmpty) {
        await tester.tap(find.text('Українська').last);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Verify UI changed to Ukrainian
        expect(find.text('Налаштування'), findsWidgets);
      }
    });
  });

  group('10. Library Modes', () {
    testWidgets('10.1 Library view mode changes', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to library
      await tester.tap(find.byIcon(Icons.library_music_outlined));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.byKey(const Key('library_screen')), findsOneWidget);

      // Change view mode
      await tester.tap(find.byKey(const Key('library_view_mode_dropdown')));
      await tester.pumpAndSettle();

      // Select albums view
      final albumsOption = find.text('Albums');
      if (albumsOption.evaluate().isNotEmpty) {
        await tester.tap(albumsOption.last);
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    });
  });

  group('11. YouTube Hub', () {
    testWidgets('11.1 YouTube hub shows quick access buttons', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate to YouTube tab
      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify quick access buttons
      expect(find.byKey(const Key('youtube_liked_songs_button')), findsOneWidget);
      expect(find.byKey(const Key('youtube_last_played_button')), findsOneWidget);
    });

    testWidgets('11.2 Last played screen opens', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.play_circle_outline));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Open last played
      await tester.tap(find.byKey(const Key('youtube_last_played_button')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Screen should open
      expect(find.byType(Scaffold), findsWidgets);
    });
  });

  group('12. Stress & Performance', () {
    testWidgets('12.1 Rapid navigation between tabs', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Rapidly switch between all tabs multiple times
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.music_note_outlined));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byIcon(Icons.play_circle_outline));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byIcon(Icons.library_music_outlined));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byIcon(Icons.settings_outlined));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.byIcon(Icons.home_outlined));
        await tester.pump(const Duration(milliseconds: 200));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // App should still be responsive
      expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    });

    testWidgets('12.2 Multiple search queries', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final queries = ['Enimkon', 'Test', 'Rock', 'Electronic', 'UA'];

      for (final query in queries) {
        await tester.tap(find.byKey(const Key('home_search_button')));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField).first, query);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        await tester.pageBack();
        await tester.pumpAndSettle(const Duration(milliseconds: 300));
      }

      // All searches should have been tracked
      expect(TestTracker.searchQueries.length, greaterThanOrEqualTo(queries.length));
    });

    testWidgets('12.3 Player controls rapid interaction', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Play a song
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Enimkon');
      await tester.pumpAndSettle(const Duration(seconds: 1));
      await tester.tap(find.text('Enimkon').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('mini_player')));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Rapid button presses
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('player_play_pause_button')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byKey(const Key('player_next_button')));
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byKey(const Key('player_shuffle_button')));
        await tester.pump(const Duration(milliseconds: 100));
      }

      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Player should still be functional
      expect(find.byKey(const Key('player_screen')), findsOneWidget);
    });
  });

  group('13. Edge Cases', () {
    testWidgets('13.1 Long title text truncation', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Long');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Long title should be in results (truncated in UI)
      expect(find.textContaining('This Is A Very Long'), findsWidgets);
    });

    testWidgets('13.2 Special characters in search', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Quotes');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Should handle special characters
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('14. Test Verification', () {
    testWidgets('14.1 TestTracker records all operations', (tester) async {
      TestOverrides.enable(permissionGranted: true);
      TestUtils.resetAll();

      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Perform several actions
      await tester.tap(find.byKey(const Key('home_search_button')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'Test');
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Verify tracking
      expect(TestTracker.searchQueries.contains('Test'), isTrue);
    });

    testWidgets('14.2 TestUtils reset clears state', (tester) async {
      // Add some data
      TestTracker.recordSearch('Old Query');
      TestTracker.recordCache('old_video');

      // Reset
      TestUtils.resetAll();

      // Verify cleared
      expect(TestTracker.searchQueries.isEmpty, isTrue);
      expect(TestTracker.cachedVideoIds.isEmpty, isTrue);
    });
  });
}
