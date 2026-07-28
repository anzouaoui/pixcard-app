import 'package:pixcard/domain/entities/listing.dart';

abstract interface class ListingRepository {
  Future<List<Listing>> getListings({
    String? game,
    String? series,
    String? condition,
    double? minPrice,
    double? maxPrice,
  });
  Future<Listing> getListingById(String id);
  Future<Listing> createListing(Listing listing);
  Future<void> updateListing(Listing listing);
  Future<void> deleteListing(String id);
  Future<List<Listing>> getListingsBySeller(String sellerId);
  Stream<List<Listing>> watchListingsBySeller(String sellerId);
  Future<CardAnalysisResult> analyzeCard(String imagePath);
}

class CardAnalysisResult {
  const CardAnalysisResult({
    required this.cardName,
    required this.setName,
    required this.condition,
    required this.confidence,
    this.estimatedPrice,
    this.imageUrl,
    this.marketPriceMin,
    this.marketPriceAvg,
    this.marketPriceMax,
    this.marketPricesWeek,
  });

  final String cardName;
  final String setName;
  final CardCondition condition;
  final double confidence;
  final double? estimatedPrice;
  final String? imageUrl;
  final double? marketPriceMin;
  final double? marketPriceAvg;
  final double? marketPriceMax;

  /// Prix journaliers des 7 derniers jours (index 0 = il y a 7j, index 6 = aujourd'hui).
  final List<double>? marketPricesWeek;
}

class CardAnalysisException implements Exception {
  const CardAnalysisException(
    this.message, {
    this.code,
    this.confidence,
  });

  final String message;
  final String? code;
  final double? confidence;

  @override
  String toString() => 'CardAnalysisException: $message (code: $code, confidence: $confidence)';
}
