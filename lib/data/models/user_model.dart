// ============================================================
// USER MODEL
// ============================================================

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? avatar;
  final String? phone;
  final String? role;
  final String? plan;
  final int? planId;
  final int quota;
  final bool havePassword;
  final String? referralCode;
  final DateTime? subscriptionExpiredAt;
  final DateTime? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.phone,
    this.role,
    this.plan,
    this.planId,
    this.quota = 0,
    this.havePassword = true,
    this.referralCode,
    this.subscriptionExpiredAt,
    this.createdAt,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawPlan = json['plan_name'] ?? json['plan'];

    String? planName;

    if (rawPlan is Map) {
      planName = rawPlan['name']?.toString();
    } else if (rawPlan != null) {
      planName = rawPlan.toString();
    }

    return UserModel(
      id: _toInt(json['id'] ?? json['M_UserID']),
      name:
          json['name']?.toString() ?? json['M_UserFullName']?.toString() ?? '',
      email: json['email']?.toString() ?? json['M_UserEmail']?.toString() ?? '',
      avatar: json['image']?.toString() ??
          json['avatar']?.toString() ??
          json['M_UserImage']?.toString(),
      phone: json['phone']?.toString() ?? json['M_UserPhone']?.toString(),
      role: json['role']?.toString() ?? json['M_UserRole']?.toString(),
      plan: planName,
      planId: _toIntNullable(json['plan_id'] ?? json['M_UserPlan']),
      quota: _toInt(
        json['quota'] ?? json['M_UserQuota'] ?? json['credits'],
      ),
      havePassword: json['havePassword'] != false,
      referralCode: json['referral_code']?.toString(),
      subscriptionExpiredAt: json['subscription_expired_at'] != null
          ? DateTime.tryParse(json['subscription_expired_at'].toString())
          : (json['M_UserSubsExp'] != null
              ? DateTime.tryParse(json['M_UserSubsExp'].toString())
              : null),
      createdAt: json['created_at'] != null
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
      'phone': phone,
      'role': role,
      'plan': plan,
      'plan_id': planId,
      'quota': quota,
      'havePassword': havePassword,
      'referral_code': referralCode,
      'subscription_expired_at': subscriptionExpiredAt?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
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
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }

    return parts.first[0].toUpperCase();
  }

  bool get isPro {
    final value = plan?.toLowerCase().trim();

    return value != null && value.isNotEmpty && value != 'free';
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

  static int? _toIntNullable(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }
}
