import 'package:go_router/go_router.dart';

import '../screens/health_screen.dart';
import '../screens/home_screen.dart';
import '../screens/meditation_player_screen.dart';
import '../screens/meditation_screen.dart';
import '../screens/queue_screen.dart';
import '../screens/rashifal_screen.dart';
import '../screens/ringtone_screen.dart';
import '../screens/section_screen.dart';
import '../screens/send_message_screen.dart';
import '../screens/send_summary_screen.dart';
import '../screens/ticket_status_screen.dart';
import '../screens/wallpaper_screen.dart';
import '../screens/login_screen.dart';
import '../screens/subscribe_screen.dart';
import '../screens/wallpaper_view_screen.dart';
import '../state/session_controller.dart';
import '../screens/status_result_screen.dart';
import '../screens/status_screen.dart';
import 'app_routes.dart';

/// The app's navigation table: it maps URLs to screens and nothing more.
/// This is the "routing logic"; all real work happens in the backend.
GoRouter createRouter(SessionController session) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: session,
    redirect: (context, state) {
      if (!session.loaded) return null;
      final loc = state.matchedLocation;
      final atLogin = loc == AppRoutes.login;
      final atSubscribe = loc == AppRoutes.subscribe;
      if (!session.isLoggedIn) return atLogin ? null : AppRoutes.login;
      if (!session.isSubscribed) {
        return atSubscribe ? null : AppRoutes.subscribe;
      }
      if (atLogin || atSubscribe) return AppRoutes.home;
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscribe,
        name: 'subscribe',
        builder: (context, state) => const SubscribeScreen(),
      ),
      GoRoute(
        path: AppRoutes.statusMaker,
        name: 'statusMaker',
        builder: (context, state) => const StatusScreen(),
      ),
      GoRoute(
        path: AppRoutes.statusResult,
        name: 'statusResult',
        builder: (context, state) {
          final args = state.extra as StatusResultArgs?;
          if (args == null) return const StatusScreen();
          return StatusResultScreen(
            templateId: args.templateId,
            photoPath: args.photoPath,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.health,
        name: 'health',
        builder: (context, state) => const HealthScreen(),
      ),
      GoRoute(
        path: AppRoutes.send,
        name: 'send',
        builder: (context, state) => const SendMessageScreen(),
      ),
      GoRoute(
        path: AppRoutes.summary,
        name: 'summary',
        builder: (context, state) => const SendSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.queue,
        name: 'queue',
        builder: (context, state) => const QueueScreen(),
      ),
      GoRoute(
        path: AppRoutes.status,
        name: 'status',
        builder: (context, state) => TicketStatusScreen(
          ticketId: state.pathParameters['ticketId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.section,
        name: 'section',
        builder: (context, state) =>
            SectionScreen(sectionId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: AppRoutes.wallpaper,
        name: 'wallpaper',
        builder: (context, state) => const WallpaperScreen(),
      ),
      GoRoute(
        path: AppRoutes.rashifal,
        name: 'rashifal',
        builder: (context, state) => const RashifalScreen(),
      ),
      GoRoute(
        path: AppRoutes.ringtone,
        name: 'ringtone',
        builder: (context, state) => const RingtoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.meditation,
        name: 'meditation',
        builder: (context, state) => const MeditationScreen(),
      ),
      GoRoute(
        path: AppRoutes.meditationPlay,
        name: 'meditationPlay',
        builder: (context, state) => MeditationPlayerScreen(
          mantraKey: state.pathParameters['key'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.wallpaperView,
        name: 'wallpaperView',
        builder: (context, state) => WallpaperViewScreen(
          args: state.extra is WallpaperViewArgs
              ? state.extra as WallpaperViewArgs
              : null,
        ),
      ),
    ],
  );
}
