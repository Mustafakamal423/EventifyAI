/// Eventify AI - mobile app (Flutter).
///
/// One app for everyone who goes to or runs an event. After login the app
/// opens the part that matches the account's role (SDD 3.6, RBAC):
///   attendee  -> the full attendee app: Explore, Tickets, Live, Profile
///   organizer -> the door tools: events, QR scanner, live attendance
///   admin     -> the platform owner works on the web dashboard only
/// Everything else (creating events, Q&A moderation, analytics) stays on the
/// web dashboard, which uses the same REST API.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'screens/attendee/attendee_shell.dart';
import 'screens/auth/welcome_screen.dart';
import 'screens/organizer/organizer_shell.dart';
import 'screens/shared/admin_web_only_screen.dart';
import 'state/session.dart';
import 'theme.dart';

/// Used to close every open screen when the logged-in user changes.
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final session = Session();
  // Login, logout or an expired token: drop any screens pushed on top so the
  // user lands on RoleGate's new home (login screens, attendee app, door tools).
  Object? lastUser = 'start';
  session.addListener(() {
    final current = session.user?.id;
    if (current != lastUser) {
      lastUser = current;
      navigatorKey.currentState?.popUntil((r) => r.isFirst);
    }
  });
  session.restore();

  runApp(ChangeNotifierProvider.value(value: session, child: const EventifyApp()));
}

class EventifyApp extends StatelessWidget {
  const EventifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventify AI',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: buildTheme(),
      home: const RoleGate(),
    );
  }
}

/// Picks the first screen from the session: splash while the saved token is
/// checked, the welcome/login flow when logged out, then the role's own app.
/// Because it rebuilds whenever the session changes, logging in or out (or a
/// token expiring) moves the user to the right place automatically.
class RoleGate extends StatelessWidget {
  const RoleGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    final Widget child;
    if (!session.ready) {
      child = const _Splash();
    } else if (session.user == null) {
      child = const WelcomeScreen();
    } else if (session.user!.isOrganizer) {
      child = const OrganizerShell();
    } else if (session.user!.isAdmin) {
      child = const AdminWebOnlyScreen();
    } else {
      child = const AttendeeShell();
    }
    // KeyedSubtree resets the navigation stack when the user changes
    return KeyedSubtree(key: ValueKey(session.user?.id ?? (session.ready ? 'out' : 'splash')), child: child);
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: C.ink,
    body: Center(child: CircularProgressIndicator(color: C.gold)),
  );
}
