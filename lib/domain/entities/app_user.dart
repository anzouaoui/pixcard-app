class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    this.displayName = '',
    this.photoUrl = '',
    this.phoneNumber = '',
    this.createdAt,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final String phoneNumber;
  final DateTime? createdAt;

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String? ?? '',
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
