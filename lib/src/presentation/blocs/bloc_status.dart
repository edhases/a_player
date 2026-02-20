/// Common status enum for all BLoCs.
///
/// This eliminates duplicate enum definitions across different BLoC states.
/// Each BLoC can import this instead of defining its own status enum.
enum BlocStatus {
  /// Initial state before any action.
  initial,

  /// Currently loading data.
  loading,

  /// Data loaded successfully.
  success,

  /// An error occurred.
  failure,
}
