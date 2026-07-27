class AppConstants {
  AppConstants._();

  static const String appName = 'PixCard';
  static const String sentryDsn = ''; // TODO: Add Sentry DSN

  // Firestore collections
  static const String usersCollection = 'users';
  static const String listingsCollection = 'listings';
  static const String offersCollection = 'offers';
  static const String conversationsCollection = 'conversations';
  static const String messagesSubcollection = 'messages'; // conversations/{id}/messages
  static const String ordersCollection = 'orders';
  static const String reviewsCollection = 'reviews';
  static const String favoritesSubcollection = 'favorites'; // users/{id}/favorites

  // Platform commission
  static const double platformCommissionPercent = 5.0;
}
