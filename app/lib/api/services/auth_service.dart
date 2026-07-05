import '../../models/user_session.dart';

/// MOCKED auth/session. Replace with real calls to `POST /v1/auth/register`
/// and a subscription-status check once the backend exists (no OTP — just the
/// phone number). See docs/BACKEND_API.md → §0.
class AuthService {
  const AuthService._();

  /// Registers/looks up a user by phone and returns their session.
  static Future<UserSession> registerPhone(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 600)); // fake network
    // MOCK: the backend always returns an ACTIVE subscription for now.
    return _activeSession(phone);
  }

  /// Re-checks the subscription status of a saved number on app launch.
  static Future<UserSession> checkSubscription(String phone) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    // MOCK: always active for now.
    return _activeSession(phone);
  }

  /// MOCK: pretend a payment succeeded. Real flow goes through the gateway.
  static Future<UserSession> activateSubscription(UserSession current) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    return _activeSession(current.phone);
  }

  static UserSession _activeSession(String phone) => UserSession(
        phone: phone,
        token: 'mock_${phone.hashCode.toUnsigned(32)}',
        subscription: SubscriptionStatus.active,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
}
