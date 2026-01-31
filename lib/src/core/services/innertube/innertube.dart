// InnerTube API services for YouTube Music integration
//
// This package provides modular services for interacting with YouTube Music's
// InnerTube API. Each service is focused on a specific domain:
//
// - InnerTubeService - Facade for backward compatibility
// - InnerTubeSearchService - Search functionality
// - InnerTubeHomeService - Home feed and recommendations
// - InnerTubePlaylistService - Playlists, albums, and liked songs
// - InnerTubeArtistService - Artist pages and top tracks
// - InnerTubeLyricsService - Song lyrics (plain and synced)
// - InnerTubeTrackingService - Playback tracking and history

export 'innertube_artist_service.dart';
export 'innertube_base.dart';
export 'innertube_constants.dart';
export 'innertube_home_service.dart';
export 'innertube_lyrics_service.dart';
export 'innertube_parser.dart';
export 'innertube_playlist_service.dart';
export 'innertube_search_service.dart';
export 'innertube_service_facade.dart';
export 'innertube_tracking_service.dart';
