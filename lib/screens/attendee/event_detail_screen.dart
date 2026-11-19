import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/share.dart';
import '../../widgets/common.dart';
import '../../widgets/event_cards.dart';
import 'attendee_shell.dart';
import 'checkout_screen.dart';
import 'live_hub_screen.dart';

/// UC04 - Event detail (design: mobile-06). Shows the ticket types and opens
/// checkout; the share button sends the event's link to other apps.
class EventDetailScreen extends StatefulWidget {
  final int eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final _view = GlobalKey<AsyncViewState<EventItem>>();

  Future<EventItem> _load() async => EventItem.fromJson(await api.get('/events/${widget.eventId}'));

  void _openMap(EventItem e) {
    final q = Uri.encodeComponent([e.venueName, e.venueAddress].whereType<String>().join(', '));
    launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$q'), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncView<EventItem>(
        key: _view,
        load: _load,
        builder: (context, e, reload) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: C.accent,
                onRefresh: reload,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _hero(context, e),
                    const TibebStrip(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (e.status == 'cancelled') ...[
                            SurfaceCard(
                              color: C.accentSoft,
                              child: Text(
                                'This event was cancelled. Paid tickets are refunded automatically.',
                                style: T.body(15, color: C.danger, weight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          _infoRow(Icons.calendar_today_outlined, Fmt.longDate(e.start), Fmt.timeRange(e.start, e.end)),
                          const SizedBox(height: 12),
                          _infoRow(
                            e.isOnline ? Icons.videocam_outlined : Icons.place_outlined,
                            e.place,
                            e.isOnline ? 'The link is sent to ticket holders' : (e.venueAddress ?? ''),
                            action: e.isOnline || e.venueName == null ? null : TextButton(onPressed: () => _openMap(e), child: const Text('Map')),
                          ),
                          if (e.similarCount > 0) ...[const SizedBox(height: 18), _similarPeople(e)],
                          if ((e.description ?? '').isNotEmpty) ...[
                            const SectionTitle('About'),
                            Text(e.description!, style: T.body(16, color: C.ink2)),
                          ],
                          if (e.organizerName != null) ...[
                            const SizedBox(height: 10),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Hosted by ',
                                    style: T.body(15, color: C.muted),
                                  ),
                                  TextSpan(
                                    text: e.organizerName,
                                    style: T.body(15, weight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SectionTitle('Tickets'),
                          for (final t in e.ticketTypes) _ticketTypeRow(t),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.check, size: 16, color: C.muted),
                              const SizedBox(width: 8),
                              Text('Automatic refund if the organizer cancels', style: T.body(14, color: C.muted)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _bottomBar(context, e),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, EventItem e) {
    final top = MediaQuery.of(context).padding.top;
    final label = [
      e.category?.toUpperCase(),
      e.isOnline ? 'ONLINE' : (e.format == 'hybrid' ? 'HYBRID' : 'IN PERSON'),
    ].whereType<String>().join(' · ');
    return EventBanner(
      event: e,
      height: 260 + top,
      showTitle: false,
      overlay: Stack(
        children: [
          Positioned(
            left: 16,
            top: top + 10,
            child: CircleIconButton(icon: Icons.chevron_left, tooltip: 'Back', onPressed: () => Navigator.of(context).pop()),
          ),
          // Share to Telegram, WhatsApp, etc. - the same link the web app shares
          Positioned(
            right: 16,
            top: top + 10,
            child: CircleIconButton(icon: Icons.ios_share, tooltip: 'Share event', onPressed: () => shareEvent(e)),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (e.isLive) Text('● LIVE NOW', style: T.eyebrow(color: C.gold)) else Text(label, style: T.eyebrow(color: Colors.white)),
                const SizedBox(height: 6),
                Text(
                  e.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: T.display(38, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String sub, {Widget? action}) => Row(
    children: [
      Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: C.ink, size: 22),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: T.body(17, weight: FontWeight.w700)),
            if (sub.isNotEmpty) Text(sub, style: T.body(15, color: C.muted)),
          ],
        ),
      ),
      if (action != null) action,
    ],
  );

  /// "People who share your interests are going" (matching preview, FR-10)
  Widget _similarPeople(EventItem e) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(18)),
    child: Row(
      children: [
        SizedBox(
          width: 30.0 + 30 * e.similarInitials.length.clamp(1, 3),
          height: 44,
          child: Stack(
            children: [
              for (var i = 0; i < e.similarInitials.length && i < 3; i++)
                Positioned(
                  left: i * 30.0,
                  child: Avatar(name: e.similarInitials[i].split('').join(' '), size: 44),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: T.body(15, color: C.darkMuted),
              children: [
                TextSpan(text: '${Fmt.plural(e.similarCount, 'person')} who share your interests ${e.similarCount == 1 ? 'is' : 'are'} going. '),
                TextSpan(
                  text: 'Meet them in the Digital Room',
                  style: T.body(15, color: C.gold, weight: FontWeight.w700),
                ),
                const TextSpan(text: ' after check-in.'),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _ticketTypeRow(TicketType t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: SurfaceCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(t.name, style: T.body(18, weight: FontWeight.w700)),
                    ),
                    if (t.soldOut) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Sold out',
                        style: T.body(14, color: C.muted, weight: FontWeight.w700),
                      ),
                    ],
                    if (t.fewLeft) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Few left',
                        style: T.body(14, color: C.accent, weight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
                if ((t.description ?? '').isNotEmpty) Text(t.description!, style: T.body(15, color: C.muted)),
              ],
            ),
          ),
          Text(
            Fmt.money(t.price),
            style: T.mono(16, weight: FontWeight.w700, color: t.soldOut ? C.muted : C.ink),
          ),
        ],
      ),
    ),
  );

  Widget _bottomBar(BuildContext context, EventItem e) {
    final Widget action;
    if (e.isLive && e.myCheckedIn) {
      action = FilledButton(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LiveHubScreen(eventId: e.id))),
        child: const Text('Open live event'),
      );
    } else if (!e.onSale) {
      action = FilledButton(onPressed: null, child: Text(e.status == 'cancelled' ? 'Cancelled' : 'Sales closed'));
    } else if (e.ticketTypes.every((t) => t.soldOut)) {
      action = const FilledButton(onPressed: null, child: Text('Sold out'));
    } else {
      action = FilledButton(
        onPressed: () =>
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen(event: e))).then((_) => _view.currentState?.reload()),
        child: Text(e.myTicketCount > 0 ? 'Get more tickets' : 'Get tickets'),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        color: C.surface,
        border: Border(top: BorderSide(color: C.line)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (e.myTicketCount > 0 && !(e.isLive && e.myCheckedIn))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () => AttendeeTabs.go(context, AttendeeTabs.tickets),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number, size: 18, color: C.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have ${Fmt.plural(e.myTicketCount, 'ticket')} for this event',
                        style: T.body(15, color: C.green, weight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      'View',
                      style: T.body(15, color: C.accent, weight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(e.minPrice == e.maxPrice ? 'Price' : 'From', style: T.body(14, color: C.muted)),
                  Text(Fmt.money(e.minPrice), style: T.display(24)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(child: action),
            ],
          ),
        ],
      ),
    );
  }
}
