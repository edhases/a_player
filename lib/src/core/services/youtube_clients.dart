// YouTube client configurations for InnerTube API
// Based on OuterTune's YouTubeClient.kt for reliability
//
// IMPORTANT: User-Agent MUST match the clientName to avoid
// YouTube anti-bot detection. Using a browser UA with an Android
// clientName is a red flag.

/// Configuration for a YouTube InnerTube client
class YouTubeClientConfig {
  final String clientName;
  final String clientVersion;
  final String userAgent;
  final String? platform;
  final int? androidSdkVersion;
  final String? osName;
  final String? osVersion;

  const YouTubeClientConfig({
    required this.clientName,
    required this.clientVersion,
    required this.userAgent,
    this.platform,
    this.androidSdkVersion,
    this.osName,
    this.osVersion,
  });

  /// Build the client context for InnerTube API requests
  Map<String, dynamic> buildContext({String? hl, String? gl}) {
    final client = <String, dynamic>{
      'clientName': clientName,
      'clientVersion': clientVersion,
      'hl': hl ?? 'en',
      'gl': gl ?? 'US',
    };

    if (platform != null) {
      client['platform'] = platform;
    }
    if (androidSdkVersion != null) {
      client['androidSdkVersion'] = androidSdkVersion;
    }
    if (osName != null) {
      client['osName'] = osName;
    }
    if (osVersion != null) {
      client['osVersion'] = osVersion;
    }

    return {'client': client};
  }
}

/// WEB_REMIX - Use for search, browse, metadata operations
/// This is YouTube Music's web client
const webRemixClient = YouTubeClientConfig(
  clientName: 'WEB_REMIX',
  clientVersion: '1.20250127.01.00',
  userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/130.0.0.0 Safari/537.36',
  platform: 'DESKTOP',
);

/// ANDROID_VR - Most reliable for streaming (handles signature cipher)
/// NOTE: Actual streaming should use youtube_explode_dart which handles
/// signature deciphering, PO Token, etc. automatically.
/// This is documented for reference.
const androidVrClient = YouTubeClientConfig(
  clientName: 'ANDROID_VR',
  clientVersion: '1.61.48',
  userAgent: 'com.google.android.apps.youtube.vr.oculus/1.61.48 '
      '(Linux; U; Android 12L; eureka-user Build/SQ3A.220605.009.A1) gzip',
  androidSdkVersion: 32,
  osName: 'Android',
  osVersion: '12L',
);

/// iOS - Alternative streaming client
/// Sometimes works when ANDROID_VR is blocked
const iosClient = YouTubeClientConfig(
  clientName: 'IOS',
  clientVersion: '19.29.1',
  userAgent: 'com.google.ios.youtube/19.29.1 (iPhone16,2; U; CPU iOS 17_5_1 '
      'like Mac OS X;)',
  osName: 'iOS',
  osVersion: '17.5.1.21F90',
);

/// TVHTML5 - TV client, sometimes bypasses restrictions
const tvHtml5Client = YouTubeClientConfig(
  clientName: 'TVHTML5',
  clientVersion: '7.20230405.08.01',
  userAgent: 'Mozilla/5.0 (X11; CrOS x86_64 15136.72.0) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/130.0.6045.90 Safari/537.36',
);
