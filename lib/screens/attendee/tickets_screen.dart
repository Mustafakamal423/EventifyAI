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

/// UC06 - My tickets (design: mobile-09). Tickets of the same type for the
/// same event are grouped on one card ("General · 2 tickets"); the QR screen
/// then lets the attendee swipe between them. Below the list: tickets sent to
/// friends and whether they have been claimed yet.
class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketData {
  final List<Ticket> tickets;
  final List<Map<String, dynamic>> sent;
  _TicketData(this.tickets, this.sent);
}

class _TicketsScreenState extends State<TicketsScreen> {
  final _view = GlobalKey<AsyncViewState<_TicketData>>();
  bool _past = false;

  @override
  void initState() {
    super.initState();
    // Reload whenever the user comes back to this tab (e.g. after buying)
    attendeeTab.addListener(_onTab);
  }

  @override
  void dispose() {
    attendeeTab.removeListener(_onTab);
    super.dispose();
  }

  void _onTab() {
    if (attendeeTab.value == AttendeeTabs.tickets) _view.currentState?.reload();
  }

  Future<_TicketData> _load() async {
    final res = await api.get('/tickets/mine');
    return _TicketData((res['tickets'] as List).map((t) => Ticket.fromJson(t)).toList(), List<Map<String, dynamic>>.from(res['sent'] ?? []));
  }

  /// A ticket is "past" once its event has ended, or when it was cancelled/refunded.
  bool _isPast(Ticket t) =>
      !t.isUsable || t.event.status == 'completed' || t.event.status == 'cancelled' || t.event.end.isBefore(DateTime.now().toUtc());

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AsyncView<_TicketData>(
        key: _view,
        load: _load,
        builder: (context, data, reload) {
          final upcoming = data.tickets.where((t) => !_isPast(t)).toList();
          final past = data.tickets.where(_isPast).toList();
          final shown = _past ? past : upcoming;

          // Group by event + ticket type, keeping the server's order
          final groups = <String, List<Ticket>>{};
          for (final t in shown) {
            groups.putIfAbsent('${t.event.id}-${t.typeName}-${t.status}', () => []).add(t);
          }

          return RefreshIndicator(
            color: C.accent,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                Text('Tickets', style: T.display(34)),
                const SizedBox(height: 16),
                _segmented(upcoming.length),
                const SizedBox(height: 18),
                if (groups.isEmpty)
                  EmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: _past ? 'No past tickets' : 'No tickets yet',
                    message: _past ? 'Tickets for events you went to show up here.' : 'Find an event you like and get a ticket.',
                    action: _past
                        ? null
                        : FilledButton(
                            style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
                            onPressed: () => attendeeTab.value = AttendeeTabs.explore,
                            child: const Text('Explore events'),
                          ),
                  )
                else ...[
                  for (final (i, g) in groups.values.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _TicketCard(tickets: g, dark: i == 0 && !_past, onChanged: reload),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Each QR code checks in one person, once.',
                      textAlign: TextAlign.center,
                      style: T.body(15, color: C.muted),
                    ),
                  ),
                ],
                if (!_past && data.sent.isNotEmpty) ...[const SectionTitle('Sent to friends'), for (final s in data.sent) _sentRow(s)],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _segmented(int upcomingCount) {
    Widget seg(String label, bool selected, VoidCallback onTap) => Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(color: selected ? C.surface : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: T.body(16, weight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? C.ink : C.muted),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          seg(upcomingCount > 0 ? 'Upcoming · $upcomingCount' : 'Upcoming', !_past, () => setState(() => _past = false)),
          seg('Past', _past, () => setState(() => _past = true)),
        ],
      ),
    );
  }

  Widget _sentRow(Map<String, dynamic> s) {
    final name = '${s['to_name'] ?? s['to_email'] ?? ''}';
    final event = s['event'] is Map ? '${s['event']['title']}' : '';
    final claimed = s['status'] == 'claimed';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Avatar(name: name, size: 42),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: T.body(16, weight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${s['type_name'] ?? ''} · $event',
                    style: T.body(14, color: C.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            claimed ? const Pill('Received', bg: C.greenSoft, fg: C.greenInk) : const Pill('Waiting', bg: C.goldSoft, fg: C.goldInk),
          ],
        ),
      ),
    );
  }
}

/// One ticket card. The first upcoming one is dark with the tibeb border, the
/// rest are light (as in the design).
class _TicketCard extends StatelessWidget {
  final List<Ticket> tickets;
  final bool dark;
  final Future<void> Function() onChanged;
  const _TicketCard({required this.tickets, required this.dark, required this.onChanged});

  String _countdown(DateTime start) {
    final now = DateTime.now().toUtc();
    if (start.isBefore(now)) return 'Today';
    final days = Fmt.addis(start).difference(Fmt.addis(now)).inHours ~/ 24;
    if (days == 0) return 'Today';
    if (days == 1) return 'Tomorrow';
    return 'In $days days';
  }

  @override
  Widget build(BuildContext context) {
    final t = tickets.first;
    final e = t.event;
    final fg = dark ? C.bg : C.ink;
    final sub = dark ? C.darkMuted : C.muted;
    final label = '${t.typeName.toUpperCase()}${tickets.length > 1 ? ' · ${tickets.length} TICKETS' : ''}';
    final canOpenLive = e.isLive && t.isCheckedIn;

    String status;
    if (t.status == 'cancelled' || t.status == 'refunded') {
      status = t.status == 'refunded' ? 'Refunded' : 'Cancelled';
    } else if (t.isCheckedIn) {
      status = 'Checked in';
    } else if (e.isLive) {
      status = 'Live now';
    } else {
      status = _countdown(e.start);
    }

    void openQr() => Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => TicketQrScreen(ticketId: t.id, groupIds: tickets.map((x) => x.id).toList()),
          ),
        )
        .then((_) => onChanged());

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Material(
        color: dark ? C.ink : C.surface,
        shape: dark
            ? null
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
                side: const BorderSide(color: C.line),
              ),
        child: InkWell(
          onTap: t.isUsable ? openQr : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const TibebStrip(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(label, style: T.eyebrow(color: dark ? C.gold : C.accent)),
                              const SizedBox(height: 6),
                              Text(e.title, style: T.display(26, color: fg)),
                              const SizedBox(height: 4),
                              Text('${Fmt.shortDate(e.start)} · ${Fmt.time(e.start)}', style: T.body(15, color: sub)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Pill(status, bg: dark ? C.green : C.fill, fg: dark ? C.bg : C.ink),
                      ],
                    ),
                    if (t.receivedFrom != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sent to you by ${t.receivedFrom}',
                        style: T.body(14, color: dark ? C.gold : C.green, weight: FontWeight.w600),
                      ),
                    ],
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: dark ? C.darkLine : C.line),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.place,
                                style: T.body(14, color: sub),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                tickets.length > 1 ? '${tickets.length} QR codes' : t.code,
                                style: T.mono(13, color: sub, weight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // "Event details" next to the main action, both always fit the card width
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: fg,
                              minimumSize: const Size.fromHeight(46),
                              side: BorderSide(color: dark ? C.darkLine : C.line, width: 1.5),
                            ),
                            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))),
                            child: const Text('Event details'),
                          ),
                        ),
                        if (t.isUsable) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size.fromHeight(46),
                                backgroundColor: dark ? C.gold : C.accent,
                                foregroundColor: dark ? C.ink : Colors.white,
                              ),
                              onPressed: canOpenLive
                                  ? () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiveHubScreen(eventId: e.id)))
                                  : openQr,
                              child: Text(canOpenLive ? 'Open live' : (tickets.length > 1 ? 'Show QR codes' : 'Show QR')),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
