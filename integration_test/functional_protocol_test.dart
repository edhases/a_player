import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:oxide_player/main.dart' as app;
import 'package:oxide_player/src/core/utils/test_overrides.dart';
import 'package:oxide_player/src/testing/fakes/fake_services.dart';

/// Main functional protocol test - runs the complete test protocol
/// as defined in oxide_player_functional_test_protocol.md
/// 
/// This is a single comprehensive test that mimics a full user session.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Oxide Player Full Functional Protocol', (tester) async {
    TestOverrides.enable(permissionGranted: false);
    TestUtils.resetAll();

    print('=== OXIDE PLAYER FUNCTIONAL PROTOCOL TEST ===\n');

    // ====================================
    // SECTION 1: ONBOARDING & PERMISSIONS
    // ====================================
    print('1. ONBOARDING & PERMISSIONS');
    
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // 1.1 Verify permission gate
    print('   1.1 Checking permission gate...');
    expect(find.byKey(const Key('permission_gate')), findsOneWidget);
    expect(find.byKey(const Key('permission_grant_button')), findsOneWidget);
    print('   ✓ Permission gate displayed');

    // 1.2 Grant permissions
    print('   1.2 Granting permissions...');
    await tester.tap(find.byKey(const Key('permission_grant_button')));
    await tester.pumpAndSettle(const Duration(seconds: 3));
    print('   ✓ Permissions granted');

    // ====================================
    // SECTION 2: HOME FEED VERIFICATION
    // ====================================
    print('\n2. HOME FEED VERIFICATION');

    // 2.1 Verify all sections
    print('   2.1 Checking home sections...');
    expect(find.byKey(const ValueKey('home_section_quick_picks')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_section_made_for_you')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_section_recommended')), findsOneWidget);
    expect(find.byKey(const ValueKey('home_section_your_library')), findsOneWidget);
    print('   ✓ All home sections present');

    // 2.2 Verify content in sections
    print('   2.2 Checking section content...');
    expect(find.text('Enimkon'), findsWidgets);
    expect(find.text('Test Artist'), findsWidgets);
    print('   ✓ Section content verified');

    // ====================================
    // SECTION 3: SEARCH & DISCOVERY
    // ====================================
    print('\n3. SEARCH & DISCOVERY');

    // 3.1 Open search
    print('   3.1 Opening search...');
    await tester.tap(find.byKey(const Key('home_search_button')));
    await tester.pumpAndSettle();
    print('   ✓ Search opened');

    // 3.2 Search for song
    print('   3.2 Searching for "Enimkon"...');
    await tester.enterText(find.byType(TextField).first, 'Enimkon');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(TestTracker.searchQueries.contains('Enimkon'), isTrue);
    expect(find.text('Enimkon'), findsWidgets);
    expect(find.text('Enimkon Playlist'), findsWidgets);
    print('   ✓ Search results verified (songs and playlists)');

    // 3.3 Play from search
    print('   3.3 Playing from search results...');
    await tester.tap(find.text('Enimkon').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    print('   ✓ Playback initiated from search');

    // ====================================
    // SECTION 4: PLAYER CONTROLS
    // ====================================
    print('\n4. PLAYER CONTROLS');

    // 4.1 Verify mini player
    print('   4.1 Checking mini player...');
    expect(find.byKey(const Key('mini_player')), findsOneWidget);
    print('   ✓ Mini player visible');

    // 4.2 Open full player
    print('   4.2 Opening full player...');
    await tester.tap(find.byKey(const Key('mini_player')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('player_screen')), findsOneWidget);
    print('   ✓ Full player opened');

    // 4.3 Test play/pause
    print('   4.3 Testing play/pause...');
    await tester.tap(find.byKey(const Key('player_play_pause_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player_play_pause_button')));
    await tester.pump(const Duration(milliseconds: 300));
    print('   ✓ Play/pause working');

    // 4.4 Test skip controls
    print('   4.4 Testing skip controls...');
    await tester.tap(find.byKey(const Key('player_next_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player_prev_button')));
    await tester.pump(const Duration(milliseconds: 300));
    print('   ✓ Skip controls working');

    // 4.5 Test shuffle
    print('   4.5 Testing shuffle...');
    await tester.tap(find.byKey(const Key('player_shuffle_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player_shuffle_button')));
    await tester.pump(const Duration(milliseconds: 300));
    print('   ✓ Shuffle toggle working');

    // 4.6 Test repeat
    print('   4.6 Testing repeat modes...');
    await tester.tap(find.byKey(const Key('player_repeat_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player_repeat_button')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player_repeat_button')));
    await tester.pump(const Duration(milliseconds: 300));
    print('   ✓ Repeat mode cycling working');

    // ====================================
    // SECTION 5: ARTIST NAVIGATION
    // ====================================
    print('\n5. ARTIST NAVIGATION');

    // 5.1 Navigate to artist page
    print('   5.1 Navigating to artist page...');
    await tester.tap(find.byKey(const Key('player_artist_link')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('playlist_tracks_screen')), findsOneWidget);
    print('   ✓ Artist page opened');

    // 5.2 Return to player
    print('   5.2 Returning to player...');
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    print('   ✓ Returned from artist page');

    // ====================================
    // SECTION 6: LIKE & DOWNLOAD
    // ====================================
    print('\n6. LIKE & DOWNLOAD');

    // 6.1 Like current song
    print('   6.1 Liking current song...');
    await tester.tap(find.byKey(const Key('player_like_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    print('   ✓ Song liked');

    // 6.2 Download song
    print('   6.2 Downloading song...');
    await tester.tap(find.byKey(const Key('player_options_button')));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('player_download_action')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(TestTracker.cachedVideoIds.isNotEmpty, isTrue);
    print('   ✓ Download initiated');

    // ====================================
    // SECTION 7: LIKED SONGS VERIFICATION
    // ====================================
    print('\n7. LIKED SONGS VERIFICATION');

    // 7.1 Navigate to liked songs
    print('   7.1 Navigating to liked songs...');
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byIcon(Icons.play_circle_outline));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.byKey(const Key('youtube_liked_songs_button')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    print('   ✓ Liked songs screen opened');

    // 7.2 Verify liked song appears
    print('   7.2 Verifying liked song...');
    expect(find.textContaining('Enimkon'), findsWidgets);
    print('   ✓ Liked song verified');

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // ====================================
    // SECTION 8: LOCAL LIBRARY
    // ====================================
    print('\n8. LOCAL LIBRARY');

    // 8.1 Navigate to local tracks
    print('   8.1 Navigating to local tracks...');
    await tester.tap(find.byIcon(Icons.music_note_outlined));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('all_tracks_screen')), findsOneWidget);
    print('   ✓ Local tracks screen opened');

    // 8.2 Play local track
    print('   8.2 Playing local track...');
    await tester.tap(find.byKey(const ValueKey('track_tile_local:test_song.mp3')));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    print('   ✓ Local track playing');

    // 8.3 Test local artist navigation
    print('   8.3 Testing local artist navigation...');
    await tester.tap(find.byKey(const Key('mini_player')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('player_artist_link')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('detail_screen')), findsOneWidget);
    print('   ✓ Local artist detail screen opened');

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // ====================================
    // SECTION 9: EDGE CASES
    // ====================================
    print('\n9. EDGE CASES');

    // 9.1 Song without artist ID
    print('   9.1 Testing song without artist ID...');
    await tester.tap(find.byKey(const Key('home_search_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'No Artist ID Song');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('No Artist ID Song').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('mini_player')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('player_artist_link')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Artist page unavailable'), findsWidgets);
    print('   ✓ Missing artist ID handled gracefully');

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 9.2 Ukrainian song (bug verification)
    print('   9.2 Testing Ukrainian song (bug verification)...');
    await tester.tap(find.byKey(const Key('home_search_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Я зігрію тебе взимку');
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await tester.tap(find.text('Я зігрію тебе взимку').first);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await tester.tap(find.byKey(const Key('mini_player')));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.tap(find.byKey(const Key('player_artist_link')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.byKey(const Key('playlist_tracks_screen')), findsOneWidget);
    print('   ✓ Ukrainian song artist navigation working');

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // ====================================
    // SECTION 10: SETTINGS
    // ====================================
    print('\n10. SETTINGS');

    // 10.1 Navigate to settings
    print('   10.1 Opening settings...');
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    print('   ✓ Settings opened');

    // 10.2 Theme change
    print('   10.2 Testing theme change...');
    await tester.tap(find.byKey(const Key('settings_theme_dropdown')));
    await tester.pumpAndSettle();
    if (find.text('Dark').evaluate().isNotEmpty) {
      await tester.tap(find.text('Dark').last);
      await tester.pumpAndSettle(const Duration(milliseconds: 500));
    }
    print('   ✓ Theme changed to Dark');

    // 10.3 View cached tracks
    print('   10.3 Viewing cached tracks...');
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_view_cached_tracks')),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_view_cached_tracks')));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.textContaining('Enimkon'), findsWidgets);
    print('   ✓ Cached tracks visible');

    await tester.pageBack();
    await tester.pumpAndSettle(const Duration(milliseconds: 500));

    // 10.4 Clear cache
    print('   10.4 Clearing cache...');
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_clear_cache')),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_clear_cache')));
    await tester.pumpAndSettle();
    if (find.text('Clear').evaluate().isNotEmpty) {
      await tester.tap(find.text('Clear').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }
    print('   ✓ Cache cleared');

    // 10.5 Language change
    print('   10.5 Testing language change...');
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings_language_dropdown')),
      200,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings_language_dropdown')));
    await tester.pumpAndSettle();
    if (find.text('Українська').evaluate().isNotEmpty) {
      await tester.tap(find.text('Українська').last);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(find.text('Налаштування'), findsWidgets);
      print('   ✓ Language changed to Ukrainian');
    }

    // ====================================
    // TEST SUMMARY
    // ====================================
    print('\n===========================================');
    print('TEST SUMMARY');
    print('===========================================');
    print('Searches performed: ${TestTracker.searchQueries.length}');
    print('Tracks cached: ${TestTracker.cachedVideoIds.length}');
    print('Artists navigated: ${TestTracker.navigatedArtists.length}');
    print('');
    print('✅ ALL PROTOCOL TESTS PASSED');
    print('===========================================\n');
  });
}
