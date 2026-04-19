import 'package:flutter/widgets.dart';

import 'app_session.dart';

class SessionScope extends InheritedNotifier<AppSession> {
  const SessionScope({
    super.key,
    required AppSession session,
    required super.child,
  }) : super(notifier: session);

  static AppSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<SessionScope>();
    assert(scope != null, 'SessionScope khong ton tai trong widget tree.');
    return scope!.notifier!;
  }
}
