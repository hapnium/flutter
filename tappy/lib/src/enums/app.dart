/// Enum representing the different applications in the system.
///
/// Each value corresponds to a specific app and its use case:
/// - `user`: The app designed for end-users interacting with the platform.
/// - `business`: The app for business owners to manage their services or offerings.
/// - `provider`: The app for service providers or workers to handle their tasks.
/// - `nearby`: The app for local discovery or nearby interactions.
///
/// This enum is useful for distinguishing behavior or configurations specific to each app.
enum TappyApp {
  /// The user-facing app.
  ///
  /// This app is designed for end-users who interact with the platform to access services
  /// or perform other user-centric activities.
  user,

  /// The business-facing app.
  ///
  /// This app is tailored for business owners or managers to oversee their services,
  /// manage orders, and engage with their customers.
  business,

  /// The provider-facing app.
  ///
  /// This app serves service providers or workers, enabling them to manage their tasks,
  /// track jobs, and communicate with customers or businesses.
  provider,

  /// The nearby-focused app.
  ///
  /// This app is intended for local discovery, interactions, or finding nearby services.
  nearby,

  /// The blink-focused app.
  ///
  /// This app is intended for AI security platform, blink.
  blink,

  /// The relay-focused app.
  ///
  /// This app is intended for call screening and management.
  relay
}