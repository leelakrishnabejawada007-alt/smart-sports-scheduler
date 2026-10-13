import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/scheduler_provider.dart';

/// Clears per-user UI state, then signs out (the auth gate shows the login page).
void logOut(BuildContext context) {
  context.read<SchedulerProvider>().reset();
  context.read<AuthProvider>().logout();
}
