import 'dart:ui';

/// Builds the device-context headers attached to every backend request. Used
/// for campaign prioritization (locale/region/timezone + server-side IP-geo)
/// and for returning perfectly-fitted images (screen resolution). No GPS, no
/// PII. See docs/BACKEND_API.md → §6.
class DeviceContext {
  const DeviceContext._();

  static Map<String, String> headers({
    required String deviceId,
    String appVersion = '0.1.0+1',
  }) {
    final dispatcher = PlatformDispatcher.instance;
    final locale = dispatcher.locale;
    final view = dispatcher.views.isNotEmpty ? dispatcher.views.first : null;
    final size = view?.physicalSize ?? Size.zero;
    final dpr = view?.devicePixelRatio ?? 1.0;
    final now = DateTime.now();
    return {
      'X-App-Version': appVersion,
      'X-Platform': 'android',
      'X-Locale': locale.toLanguageTag(),
      'X-Region': locale.countryCode ?? '',
      'X-Timezone': now.timeZoneName,
      'X-Tz-Offset': _formatOffset(now.timeZoneOffset),
      'X-Screen-W': size.width.round().toString(),
      'X-Screen-H': size.height.round().toString(),
      'X-Density': dpr.toStringAsFixed(2),
      if (deviceId.isNotEmpty) 'X-Device-Id': deviceId,
    };
  }

  static String _formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final h = offset.inHours.abs().toString().padLeft(2, '0');
    final m = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    return '$sign$h:$m';
  }
}
