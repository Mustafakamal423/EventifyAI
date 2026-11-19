import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../config.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/share.dart';
import '../../widgets/common.dart';
import 'organizer_shell.dart';

/// Organizer home (design: mobile-18 "Your events"). Events happening now get
/// a dark card with the check-in progress and the Scan / Attendance buttons.
class OrgEventsScreen extends StatefulWidget {
  const OrgEventsScreen({super.key});

  @override
  State<OrgEventsScreen> createState() => _OrgEventsScreenState();
}

class _OrgEventsScreenState extends State<OrgEventsScreen> {
  final _view = GlobalKey<AsyncViewState<List<EventItem>>>();

  @override
  void initState() {
    super.initState();
    organizerTab.addListener(_onTab);
  }

  @override
  void dispose() {
    organizerTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (organizerTab.value == OrganizerTabs.events) _view.currentState?.reload();
  }

  Future<List<EventItem>> _load() async {
    final res = await api.get('/events/mine');
    final list = (res['events'] as List).map((e) => EventItem.fromJson(e)).toList();
    // Default door event: the first one happening now
    doorEvent.value ??= list.where((e) => e.isLive).firstOrNull;
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    return SafeArea(
      child: AsyncView<List<EventItem>>(
        key: _view,
        load: _load,
        builder: (context, events, reload) {
          final now = DateTime.now().toUtc();
          final live = events.where((e) => e.isLive).toList();
          final upcoming = events.where((e) => !e.isLive && e.end.isAfter(now) && e.status != 'cancelled').toList()
            ..sort((a, b) => a.start.compareTo(b.start));
          final past = events.where((e) => !e.isLive && !upcoming.contains(e)).toList();

          return RefreshIndicator(
            color: C.accent,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text('ORGANIZER · ${user.fullName.toUpperCase()}', style: T.eyebrow(), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Your events', style: T.display(34)),
                const SizedBox(height: 18),
                for (final e in live)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _LiveEventCard(event: e),
                  ),
                if (live.isEmpty)
                  SurfaceCard(
                    child: Text('No event is live right now. Scanning opens 2 hours before an event starts.', style: T.body(15, color: C.muted)),
                  ),
                if (upcoming.isNotEmpty) ...[const SectionTitle('Upcoming'), for (final e in upcoming) _eventRow(context, e)],
                if (past.isNotEmpty) ...[const SectionTitle('Past'), for (final e in past.take(10)) _eventRow(context, e)],
                const SizedBox(height: 18),
                // Everything else is managed on the web dashboard
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => launchUrl(Uri.parse('${AppConfig.baseUrl}/dashboard'), mode: LaunchMode.externalApplication),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: C.line, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.desktop_windows_outlined, color: C.ink2),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text('Create events, moderate Q&A and see analytics on the web dashboard.', style: T.body(15, color: C.ink2)),
                        ),
                        const Icon(Icons.open_in_new, size: 18, color: C.muted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _eventRow(BuildContext context, EventItem e) {
    final sold = e.ticketsSold;
    final sub = e.status == 'draft' ? 'not on sale' : '$sold / ${e.capacity} sold';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title, style: T.body(17, weight: FontWeight.w700)),
                  Text('${Fmt.shortDate(e.start)} · $sub', style: T.body(14, color: C.muted)),
                ],
              ),
            ),
            Pill.status(e.status),
            // Organizers can share their published events too
            if (e.status == 'published' || e.status == 'active')
              IconButton(icon: const Icon(Icons.ios_share, size: 20), tooltip: 'Share event', onPressed: () => shareEvent(e))
            else
              const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

/// "Happening now" card: check-in progress plus the door actions.
class _LiveEventCard extends StatelessWidget {
  final EventItem event;
  const _LiveEventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    final sold = event.ticketsSold;
    final progress = sold == 0 ? 0.0 : (event.checkedIn / sold).clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        color: C.ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TibebStrip(height: 10),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('● HAPPENING NOW', style: T.eyebrow(color: const Color(0xFFE8754F))),
                      ),
                      IconButton(
                        icon: const Icon(Icons.ios_share, color: C.darkMuted, size: 20),
                        tooltip: 'Share event',
                        onPressed: () => shareEvent(event),
                      ),
                    ],
                  ),
                  Text(event.title, style: T.display(26, color: C.bg)),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text('Checked in', style: T.body(16, color: C.darkMuted)),
                      ),
                      Text('${event.checkedIn}', style: T.display(40, color: C.bg)),
                      Text(' / $sold sold', style: T.body(17, color: C.darkMuted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(value: progress, minHeight: 10, color: C.gold, backgroundColor: C.darkLine),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan tickets'),
                          onPressed: () => OrganizerTabs.open(event, OrganizerTabs.scan),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: C.bg,
                            minimumSize: const Size.fromHeight(54),
                            side: const BorderSide(color: C.darkLine, width: 1.5),
                          ),
                          onPressed: () => OrganizerTabs.open(event, OrganizerTabs.attendance),
                          child: const Text('Attendance'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
