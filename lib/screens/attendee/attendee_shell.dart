import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session.dart';
import '../shared/profile_edit_screen.dart';
import 'explore_screen.dart';
import 'live_index_screen.dart';
import 'profile_screen.dart';
import 'tickets_screen.dart';

/// Which bottom tab is showing. Other screens change it, e.g. after a
/// successful payment the app jumps to the Tickets tab.
final attendeeTab = ValueNotifier<int>(0);

class AttendeeTabs {
  static const explore = 0, tickets = 1, live = 2, profile = 3;

  /// Close any pushed screens and switch tab.
  static void go(BuildContext context, int tab) {
    Navigator.of(context).popUntil((r) => r.isFirst);
    attendeeTab.value = tab;
  }
}

/// The attendee app: four tabs as in the design (Explore, Tickets, Live, Profile).
/// Detail screens are pushed on top of the tabs and cover the whole screen.
class AttendeeShell extends StatefulWidget {
  const AttendeeShell({super.key});

  @override
  State<AttendeeShell> createState() => _AttendeeShellState();
}

class _AttendeeShellState extends State<AttendeeShell> {
  // Each tab is built once and kept alive (IndexedStack), so switching tabs
  // does not reload the lists every time.
  final _tabs = const [ExploreScreen(), TicketsScreen(), LiveIndexScreen(), ProfileScreen()];

  @override
  void initState() {
    super.initState();
    attendeeTab.value = AttendeeTabs.explore;
    // A brand-new attendee fills in their networking profile first (design: mobile-04)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = context.read<Session>();
      if (session.needsOnboarding) {
        session.needsOnboarding = false;
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen(onboarding: true)));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: attendeeTab,
      builder: (context, index, _) => Scaffold(
        body: IndexedStack(index: index, children: _tabs),
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => attendeeTab.value = i,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Explore'),
            NavigationDestination(icon: Icon(Icons.confirmation_number_outlined), selectedIcon: Icon(Icons.confirmation_number), label: 'Tickets'),
            NavigationDestination(icon: Icon(Icons.sensors), label: 'Live'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
