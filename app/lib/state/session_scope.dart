import 'package:flutter/widgets.dart';

import 'session_controller.dart';

/// Exposes the [SessionController] to the widget tree and rebuilds dependents
/// when the session changes.
class SessionScope extends InheritedNotifier<SessionController> {
  const SessionScope({
    super.key,
    required SessionController controller,
    required super.child,
  }) : super(notifier: controller);

  static SessionController of(BuildContext context) {
    final controller = context
        .dependOnInheritedWidgetOfExactType<SessionScope>()
        ?.notifier;
    assert(controller != null, 'SessionScope was not found in the tree');
    return controller!;
  }
}
