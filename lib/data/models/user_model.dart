// ============================================================
// USER MODEL
// ============================================================

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? plan;
  final int credits;
  final String? referralCode;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.plan,
    this.credits = 0,
    this.referralCode,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      plan: json['plan']?['name'],
      credits: json['credits'] ?? 0,
      referralCode: json['referral_code'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'avatar': avatar,
    'plan': plan,
    'credits': credits,
    'referral_code': referralCode,
  };

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  bool get isPro => plan != null && plan!.toLowerCase() != 'free';
}
