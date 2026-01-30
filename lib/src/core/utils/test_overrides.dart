class TestOverrides {
  static bool enabled = false;
  static bool permissionGranted = false;

  static void enable({bool permissionGranted = true}) {
    enabled = true;
    TestOverrides.permissionGranted = permissionGranted;
  }

  static void setPermissionGranted(bool granted) {
    permissionGranted = granted;
  }

  static void reset() {
    enabled = false;
    permissionGranted = false;
  }
}
