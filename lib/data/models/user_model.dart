// ============================================================
// USER MODEL
// ============================================================

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? plan;
  final int quota;
  final String? referralCode;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.plan,
    this.quota = 0,
    this.referralCode,
    this.createdAt,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawPlan = json['plan'];

    String? planName;

    if (rawPlan is Map) {
      planName = rawPlan['name']?.toString();
    } else if (rawPlan != null) {
      planName = rawPlan.toString();
    }

    return UserModel(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
      plan: planName,

      // Backend PintarAja mengirim "quota".
      // "credits" dipakai sebagai fallback agar
      // data lama di storage tidak langsung rusak.
      quota: _toInt(
        json['quota'] ?? json['credits'],
      ),

      referralCode:
          json['referral_code']?.toString(),

      createdAt:
          json['created_at'] != null
              ? DateTime.tryParse(
                  json['created_at'].toString(),
                )
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'avatar': avatar,
      'plan': plan,
      'quota': quota,
      'referral_code': referralCode,
      'created_at':
          createdAt?.toIso8601String(),
    };
  }

  String get initials {
    final cleanName = name.trim();

    if (cleanName.isEmpty) {
      return '?';
    }

    final parts = cleanName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'
          .toUpperCase();
    }

    return parts.first[0].toUpperCase();
  }

  bool get isPro {
    final value =
        plan?.toLowerCase().trim();

    return value != null &&
        value.isNotEmpty &&
        value != 'free';
  }

  static int _toInt(dynamic value) {
    if (value == null) {
      return 0;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(
          value.toString(),
        ) ??
        0;
  }
}