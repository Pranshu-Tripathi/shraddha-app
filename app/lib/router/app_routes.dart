/// Route paths and names — the single source of truth for navigation targets.
class AppRoutes {
  const AppRoutes._();

  static const String home = '/';
  static const String login = '/login';
  static const String subscribe = '/subscribe';
  static const String statusMaker = '/status';
  static const String statusResult = '/status-result';
  static const String health = '/health';
  static const String send = '/send';
  static const String summary = '/summary';
  static const String queue = '/queue';
  static const String status = '/status/:ticketId';
  static const String section = '/section/:id';
  static const String wallpaper = '/wallpaper';
  static const String wallpaperView = '/wallpaper/view';
  static const String rashifal = '/rashifal';
  static const String ringtone = '/ringtone';
  static const String meditation = '/meditation';
  static const String meditationPlay = '/meditation/play/:key';

  static String statusPath(String ticketId) => '/status/$ticketId';
  static String sectionPath(String id) => '/section/$id';
  static String meditationPlayPath(String key) => '/meditation/play/$key';
}
