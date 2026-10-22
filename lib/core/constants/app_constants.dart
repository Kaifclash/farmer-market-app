class AppConstants {
  AppConstants._();

  static const appName = 'Farmer Market';
  static const tagline = 'Fresh from the farm, straight to you';

  static const splashDuration = Duration(milliseconds: 1800);

  // Spacing scale
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 16;
  static const double spaceLg = 24;
  static const double spaceXl = 32;

  static const double radius = 16;
}

/// Admin is reserved for accounts provisioned outside public registration.
enum UserRole { customer, seller, admin }
