/// The update icon / modal state.
enum UpdatePhase {
  /// No update to talk about.
  hidden,

  /// A new version exists but the download has not started (for example the
  /// phone is on mobile data).
  available,

  /// The APK is being downloaded right now.
  downloading,

  /// A checked APK is on disk and ready to install.
  ready,

  /// Something went wrong; the user can try again.
  error,
}
