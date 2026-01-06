/// Represents the different types of Smart applications.
library;

/// This enum defines the different types of Smart applications that exist within the system.
/// Each value represents a specific category or role within the Smart ecosystem.
enum SmartApp {
  /// Represents the user-facing application.
  user("Hapnium"),

  /// Represents the application used by service providers.
  provider("Hapnium Provider"),

  /// Represents the application for finding nearby services.
  nearby("Nearby"),

  /// Represents the application for blink ai.
  blink("Blink"),

  /// Represents the application for managing businesses.
  business("Hapnium Business");

  final String type;
  const SmartApp(this.type);
}