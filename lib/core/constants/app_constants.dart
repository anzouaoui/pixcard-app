class AppConstants {
  AppConstants._();

  static const String appName = 'PixCard';
  static const String sentryDsn = ''; // TODO: Add Sentry DSN

  // Firestore collections
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String transactionsCollection = 'transactions';
  static const String messagesCollection = 'messages';

  // Platform commission
  static const double platformCommissionPercent = 5.0;
}
