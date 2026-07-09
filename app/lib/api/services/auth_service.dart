import 'package:flutter/foundation.dart';

import '../../models/user_session.dart';
import '../api_exception.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Auth/session API. The backend decides subscription state; the app only
/// stores and renders the returned session.
class AuthService {
  const AuthService._();

  /// Registers/looks up a user by phone and returns their session.
  static Future<UserSession> registerPhone(String phone) async {
    try {
      final json = await ApiClient().postJson(
        Endpoints.authRegister,
        body: {'phone': phone},
      );
      return UserSession.fromJson(json);
    } on ApiException catch (e) {
      if (!kReleaseMode && e.statusCode == 404) {
        return UserSession(
          phone: phone,
          token: '',
          subscription: SubscriptionStatus.inactive,
        );
      }
      rethrow;
    }
  }

  /// Re-checks the subscription status of a saved number on app launch.
  static Future<UserSession> checkSubscription(String phone) async {
    return registerPhone(phone);
  }

  static Future<UserSession> activateSubscription(UserSession current) async {
    throw UnsupportedError(
      'Subscription activation requires a verified payment backend.',
    );
  }
}
