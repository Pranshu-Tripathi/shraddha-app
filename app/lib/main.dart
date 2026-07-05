import 'package:flutter/material.dart';

import 'api/service_locator.dart';
import 'app.dart';
import 'state/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Restore any saved session (phone + subscription) before the first frame.
  final session = SessionController();
  await session.load();
  final services = Services(deviceId: session.deviceId);
  runApp(ShantiApp(services: services, session: session));
}
