class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl,
    this.bio,
    this.createdAt,
    this.salesCount = 0,
    this.rating = 0,
    // Calculé comme le pourcentage de transactions sans litige
    // sur les 90 derniers jours (mis à jour par Cloud Function).
    this.reliabilityScore = 100,
  });

  final String id;
  final String email;
  final String displayName;
  final String? photoUrl;
  final String? bio;
  final DateTime? createdAt;
  final int salesCount;
  final double rating;
  final double reliabilityScore;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      // Firestore field is "pseudo", Flutter entity uses "displayName"
      displayName: map['pseudo'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      bio: map['bio'] as String?,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
      salesCount: map['salesCount'] as int? ?? 0,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      reliabilityScore: (map['reliabilityScore'] as num?)?.toDouble() ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      // Flutter entity uses "displayName", Firestore field is "pseudo"
      'pseudo': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'createdAt': createdAt?.toIso8601String(),
      'salesCount': salesCount,
      'rating': rating,
      'reliabilityScore': reliabilityScore,
    };
  }
}
