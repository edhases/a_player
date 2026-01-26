/// Model representing an available update from GitHub Releases
class UpdateInfo {
  final String versionName;
  final int versionCode;
  final String apkUrl;
  final String apkSha256;
  final String changelog;
  final int minSupportedVersionCode;

  const UpdateInfo({
    required this.versionName,
    required this.versionCode,
    required this.apkUrl,
    required this.apkSha256,
    required this.changelog,
    required this.minSupportedVersionCode,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      versionName: json['versionName'] as String? ?? '',
      versionCode: json['versionCode'] as int? ?? 0,
      apkUrl: json['apkUrl'] as String? ?? '',
      apkSha256: json['apkSha256'] as String? ?? '',
      changelog: json['changelog'] as String? ?? '',
      minSupportedVersionCode: json['minSupportedVersionCode'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'versionName': versionName,
      'versionCode': versionCode,
      'apkUrl': apkUrl,
      'apkSha256': apkSha256,
      'changelog': changelog,
      'minSupportedVersionCode': minSupportedVersionCode,
    };
  }

  /// Check if this update requires Plan B (forced update)
  bool isForcedUpdate(int currentVersionCode) {
    return currentVersionCode < minSupportedVersionCode;
  }

  /// Check if this is a newer version
  bool isNewerThan(int currentVersionCode) {
    return versionCode > currentVersionCode;
  }
}
