/// The signed-in user's session. Created from a phone number (no OTP).
/// The backend decides [subscription]; the app only renders based on it.
enum SubscriptionStatus { active, inactive }

class UserSession {
  const UserSession({
    required this.phone,
    required this.token,
    required this.subscription,
    this.expiresAt,
  });

  final String phone;
  final String token;
  final SubscriptionStatus subscription;
  final DateTime? expiresAt;

  bool get isActive => subscription == SubscriptionStatus.active;

  factory UserSession.fromJson(Map<String, dynamic> json) => UserSession(
    phone: json['phone']?.toString() ?? '',
    token: json['token']?.toString() ?? '',
    subscription: (json['subscription']?.toString() == 'active')
        ? SubscriptionStatus.active
        : SubscriptionStatus.inactive,
    expiresAt: json['expires_at'] != null
        ? DateTime.tryParse(json['expires_at'].toString())
        : null,
  );
}
