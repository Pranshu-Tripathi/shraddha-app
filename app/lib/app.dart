import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'api/service_locator.dart';
import 'api/services_scope.dart';
import 'router/app_router.dart';
import 'state/session_controller.dart';
import 'state/session_scope.dart';
import 'theme/app_colors.dart';

/// Root widget: provides Services + Session to the tree and wires up routing.
class ShantiApp extends StatefulWidget {
  const ShantiApp({super.key, required this.services, required this.session});

  final Services services;
  final SessionController session;

  @override
  State<ShantiApp> createState() => _ShantiAppState();
}

class _ShantiAppState extends State<ShantiApp> {
  late final GoRouter _router = createRouter(widget.session);

  @override
  Widget build(BuildContext context) {
    return SessionScope(
      controller: widget.session,
      child: ServicesScope(
        services: widget.services,
        child: MaterialApp.router(
          title: 'Shanti',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorSchemeSeed: AppColors.saffron,
            scaffoldBackgroundColor: AppColors.cream,
            useMaterial3: true,
          ),
          routerConfig: _router,
        ),
      ),
    );
  }
}
