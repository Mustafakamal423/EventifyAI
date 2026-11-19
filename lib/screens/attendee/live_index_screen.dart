import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'attendee_shell.dart';
import 'event_detail_screen.dart';
import 'live_hub_screen.dart';
import 'ticket_qr_screen.dart';

/// The "Live" tab. Lists events happening now that the attendee is checked in
/// to (each opens the live hub), plus events happening now where they still
/// need to show their QR at the door.
class LiveIndexScreen extends StatefulWidget {
  const LiveIndexScreen({super.key});

  @override
  State<LiveIndexScreen> createState() => _LiveIndexScreenState();
}

class _LiveData {
  final List<Map<String, dynamic>> checkedIn;
  final List<Ticket> atTheDoor; // live events with a ticket that is not scanned yet
  _LiveData(this.checkedIn, this.atTheDoor);
}

class _LiveIndexScreenState extends State<LiveIndexScreen> {
  final _view = GlobalKey<AsyncViewState<_LiveData>>();

  @override
  void initState() {
    super.initState();
    attendeeTab.addListener(_onTab);
  }

  @override
  void dispose() {
    attendeeTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (attendeeTab.value == AttendeeTabs.live) _view.currentState?.reload();
  }

  Future<_LiveData> _load() async {
    final results = await Future.wait([api.get('/events/live'), api.get('/tickets/mine')]);
    final live = List<Map<String, dynamic>>.from(results[0]['events'] ?? []);
    final liveIds = live.map((e) => e['event_id']).toSet();
    final tickets = (results[1]['tickets'] as List).map((t) => Ticket.fromJson(t)).toList();
    final door = <int, Ticket>{};
    for (final t in tickets) {
      if (t.event.isLive && t.status == 'confirmed' && !liveIds.contains(t.event.id)) door.putIfAbsent(t.event.id, () => t);
    }
    return _LiveData(live, door.values.toList());
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncView<_LiveData>(
        key: _view,
        load: _load,
        builder: (context, data, reload) => RefreshIndicator(
          color: C.accent,
          onRefresh: reload,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              Text('Live', style: T.display(34)),
              const SizedBox(height: 6),
              Text('Your Digital Room, AI matches and Q&A open once your ticket is scanned at the door.', style: T.body(16, color: C.muted)),
              const SizedBox(height: 18),
              if (data.checkedIn.isEmpty && data.atTheDoor.isEmpty)
                const EmptyState(
                  icon: Icons.sensors_off,
                  title: 'Nothing live right now',
                  message: 'When an event you have a ticket for starts, it shows up here.',
                ),
              for (final e in data.checkedIn) _liveCard(context, e),
              if (data.atTheDoor.isNotEmpty) ...[const SectionTitle('Happening now'), for (final t in data.atTheDoor) _doorCard(context, t)],
            ],
          ),
        ),
      ),
    );
  }

  Widget _liveCard(BuildContext context, Map<String, dynamic> e) {
    final checkedAt = DateTime.tryParse('${e['checked_in_at']}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Material(
          color: C.ink,
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiveHubScreen(eventId: e['event_id']))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('● LIVE NOW', style: T.eyebrow(color: C.accent)),
                      const SizedBox(height: 6),
                      Text('${e['title']}', style: T.display(26, color: C.bg)),
                      const SizedBox(height: 4),
                      Text(
                        '${e['venue_name'] ?? 'Online'}${checkedAt != null ? ' · checked in ${Fmt.time(checkedAt)}' : ''}',
                        style: T.body(15, color: C.darkMuted),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            'Open live event',
                            style: T.body(16, color: C.gold, weight: FontWeight.w700),
                          ),
                          const Icon(Icons.chevron_right, color: C.gold),
                        ],
                      ),
                    ],
                  ),
                ),
                const TibebStrip(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// A live event where the attendee still needs to get scanned in.
  Widget _doorCard(BuildContext context, Ticket t) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(t.event.title, style: T.body(18, weight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text('Show your QR at the door to unlock the room.', style: T.body(15, color: C.muted)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: t.event.id))),
                  child: const Text('Event details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                  onPressed: () =>
                      Navigator.of(context)
                          .push(MaterialPageRoute(builder: (_) => TicketQrScreen(ticketId: t.id)))
                          .then((_) => _view.currentState?.reload()),
                  child: const Text('Show my QR'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
