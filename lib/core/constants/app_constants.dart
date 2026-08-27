import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'PixCard';

  static String get sentryDsn => dotenv.env['SENTRY_DSN'] ?? '';
  static String get stripePublishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY'] ?? '';

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
  static const double sellerCommissionRate = 0.05;
}
