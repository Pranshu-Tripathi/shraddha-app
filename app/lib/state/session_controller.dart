import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../api/services/auth_service.dart';
import '../models/user_session.dart';

const bool kForceLoginOnLaunch = bool.fromEnvironment(
  'FORCE_LOGIN_ON_LAUNCH',
  defaultValue: false,
);

const String kTestingDummyPhone = String.fromEnvironment(
  'TESTING_DUMMY_PHONE',
  defaultValue: '',
);

/// Holds the current [UserSession] and persists it across launches. Drives the
/// router's redirect (login / subscription gate).
class SessionController extends ChangeNotifier {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
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
    _deviceId = await _storage.read(key: _kDeviceId) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _generateDeviceId();
      await _storage.write(key: _kDeviceId, value: _deviceId);
    }
    _savedPhone = await _storage.read(key: _kPhone) ?? '';
    // If a number is saved, re-validate its subscription with the backend
    // on launch; stored subscription state is only a cache.
    if (_savedPhone.isNotEmpty && !kForceLoginOnLaunch) {
      try {
        _session = await AuthService.checkSubscription(_savedPhone);
        await _persist();
      } catch (_) {
        await _clearSessionOnly();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> signIn(String phone) async {
    _setBusy(true);
    try {
      _session = await AuthService.registerPhone(phone);
      _savedPhone = phone;
      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> activateSubscription() async {
    final current = _session;
    if (current == null) return;
    _setBusy(true);
    try {
      _session = await AuthService.activateSubscription(current);
      await _persist();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> signOut() async {
    await _clearSessionOnly();
    _savedPhone = '';
    _session = null;
    notifyListeners();
  }

  void _setBusy(bool v) {
    _busy = v;
    notifyListeners();
  }

  String _generateDeviceId() {
    final r = Random.secure();
    return List<int>.generate(
      16,
      (_) => r.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _persist() async {
    final s = _session;
    if (s == null) return;
    await Future.wait([
      _storage.write(key: _kPhone, value: s.phone),
      _storage.write(key: _kToken, value: s.token),
      _storage.write(key: _kSub, value: s.subscription.name),
    ]);
  }

  Future<void> _clearSessionOnly() async {
    await Future.wait([
      _storage.delete(key: _kPhone),
      _storage.delete(key: _kToken),
      _storage.delete(key: _kSub),
    ]);
  }
}
