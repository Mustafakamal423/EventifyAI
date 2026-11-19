import 'package:flutter/material.dart';

import '../../api/models.dart';
import 'attendance_screen.dart';
import 'org_events_screen.dart';
import 'org_profile_screen.dart';
import 'scanner_screen.dart';

/// The event the door staff is working on. Picked on the Events tab and used
/// by the Scan and Attendance tabs, so a ticket for another event is refused.
final doorEvent = ValueNotifier<EventItem?>(null);

/// Which tab the organizer is on (Events, Scan, Attendance, Profile).
final organizerTab = ValueNotifier<int>(0);

class OrganizerTabs {
  static const events = 0, scan = 1, attendance = 2, profile = 3;

  /// Choose the event and jump to a tab (e.g. "Scan tickets" on an event card).
  static void open(EventItem event, int tab) {
    doorEvent.value = event;
    organizerTab.value = tab;
  }
}

/// Organizer app = door tools only (design: mobile-18..21). Creating events,
/// Q&A moderation and analytics stay on the web dashboard.
class OrganizerShell extends StatefulWidget {
  const OrganizerShell({super.key});

  @override
  State<OrganizerShell> createState() => _OrganizerShellState();
}

class _OrganizerShellState extends State<OrganizerShell> {
  @override
  void initState() {
    super.initState();
    organizerTab.value = OrganizerTabs.events;
    doorEvent.value = null;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: organizerTab,
      builder: (context, index, _) => Scaffold(
        // The scanner only exists while its tab is open, so the camera is off otherwise
        body: IndexedStack(
          index: index,
          children: [
            const OrgEventsScreen(),
            index == OrganizerTabs.scan ? const ScannerScreen() : const SizedBox(),
            const AttendanceScreen(),
            const OrgProfileScreen(),
          ],
        ),
        bottomNavigationBar: index == OrganizerTabs.scan
            ? null // the scanner is full screen with its own close button
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => organizerTab.value = i,
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.calendar_today_outlined), selectedIcon: Icon(Icons.calendar_today), label: 'Events'),
                  NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
                  NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Attendance'),
                  NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
                ],
              ),
      ),
    );
  }
}
