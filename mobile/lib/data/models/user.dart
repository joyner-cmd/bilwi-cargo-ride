class AppUser {
  AppUser({
    required this.id,
    required this.role,
    required this.fullName,
    required this.phone,
    this.email,
    this.photoUrl,
    this.ratingAvg = 0,
    this.ratingCount = 0,
  });

  final int id;
  final String role; // client | driver | admin
  final String fullName;
  final String phone;
  final String? email;
  final String? photoUrl;
  final double ratingAvg;
  final int ratingCount;

  bool get isDriver => role == 'driver';
  bool get isClient => role == 'client';

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        role: j['role'] as String,
        fullName: j['full_name'] as String,
        phone: j['phone'] as String,
        email: j['email'] as String?,
        photoUrl: j['photo_url'] as String?,
        ratingAvg: double.tryParse('${j['rating_avg'] ?? 0}') ?? 0,
        ratingCount: (j['rating_count'] ?? 0) as int,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'role': role,
        'full_name': fullName,
        'phone': phone,
        'email': email,
        'photo_url': photoUrl,
        'rating_avg': ratingAvg,
        'rating_count': ratingCount,
      };
}
