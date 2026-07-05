import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/services/auth_service.dart';
import '../models/user_session.dart';

/// TODO(testing): REMOVE before release. When `true`, the login screen is shown
/// on EVERY launch (the saved session is NOT auto-restored) so the registration
/// flow can be tested repeatedly. Set to `false` for real persist-and-skip
/// behavior (saved number → re-check subscription → render or gate).
const bool kForceLoginOnLaunch = true;

/// TODO(testing): REMOVE before release. Dummy number prefilled into the login
/// field so a tester can continue without typing (only while
/// [kForceLoginOnLaunch] is true).
const String kTestingDummyPhone = '9876543210';

/// Holds the current [UserSession] and persists it across launches. Drives the
/// router's redirect (login / subscription gate). Backend calls are mocked.
class SessionController extends ChangeNotifier {
  static const _kPhone = 'session_phone';
  static const _kToken = 'session_token';
  static const _kSub = 'session_sub';
  static const _kDeviceId = 'device_id';

  UserSession? _session;
  String _deviceId = '';
  String _savedPhone = '';
  bool _loaded = false;
  bool _busy = false;

  UserSession? get session => _session;

  /// The last number the user signed in with (persisted) — used to prefill login.
  String get savedPhone => _savedPhone;

  /// Anonymous, stable-per-install id (sent to the backend; no PII).
  String get deviceId => _deviceId;
  bool get loaded => _loaded;
  bool get busy => _busy;
  bool get isLoggedIn => _session != null;
  bool get isSubscribed => _session?.subscription == SubscriptionStatus.active;

  /// Restore any saved session on app start.
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _deviceId = p.getString(_kDeviceId) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _generateDeviceId();
      await p.setString(_kDeviceId, _deviceId);
    }
    _savedPhone = p.getString(_kPhone) ?? '';
    // If a number is saved, re-validate its subscription with the backend
    // (mocked) on launch — we don't trust the stored status. Skipped while
    // kForceLoginOnLaunch is on (testing), so the login screen always shows.
    if (_savedPhone.isNotEmpty && !kForceLoginOnLaunch) {
      _session = await AuthService.checkSubscription(_savedPhone);
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> signIn(String phone) async {
    _setBusy(true);
    _session = await AuthService.registerPhone(phone);
    await _persist();
    _setBusy(false);
  }

  Future<void> activateSubscription() async {
    final current = _session;
    if (current == null) return;
    _setBusy(true);
    _session = await AuthService.activateSubscription(current);
    await _persist();
    _setBusy(false);
  }

  Future<void> signOut() async {
    final p = await SharedPreferences.getInstance();
    await Future.wait([p.remove(_kPhone), p.remove(_kToken), p.remove(_kSub)]);
    _session = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  String _generateDeviceId() {
    final r = Random();
    return List<int>.generate(16, (_) => r.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  Future<void> _persist() async {
    final s = _session;
    if (s == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kPhone, s.phone);
    await p.setString(_kToken, s.token);
    await p.setString(_kSub, s.subscription.name);
  }
}
