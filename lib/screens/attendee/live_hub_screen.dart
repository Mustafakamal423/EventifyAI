import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'assistant_screen.dart';
import 'matches_screen.dart';
import 'qa_screen.dart';
import 'room_screen.dart';

/// UC08 - Live event hub (design: mobile-11). Unlocked by check-in (BR-09):
/// the server answers 403 until the attendee's QR has been scanned.
class LiveHubScreen extends StatelessWidget {
  final int eventId;
  const LiveHubScreen({super.key, required this.eventId});

  void _go(BuildContext context, Widget screen) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<Map<String, dynamic>>(
        load: () async => Map<String, dynamic>.from(await api.get('/events/$eventId/hub')),
        builder: (context, hub, reload) {
          final live = hub['status'] == 'active';
          final checkedAt = DateTime.tryParse('${hub['checked_in_at']}');
          final end = DateTime.tryParse('${hub['end_datetime']}');
          final matches = (hub['match_count'] as num?)?.toInt() ?? 0;
          final inRoom = (hub['checked_in_total'] as num?)?.toInt() ?? 0;
          return RefreshIndicator(
            color: C.accent,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Text(live ? '● LIVE NOW' : '${hub['status']}'.toUpperCase(), style: T.eyebrow(color: live ? C.accent : C.muted)),
                const SizedBox(height: 4),
                Text('${hub['title']}', style: T.display(32)),
                const SizedBox(height: 16),
                if (checkedAt != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: C.greenSoft, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        const Icon(Icons.check, color: C.greenInk),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Checked in at ${Fmt.time(checkedAt)} · Room unlocked',
                            style: T.body(16, color: C.greenInk, weight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    color: C.ink,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${(hub['venue_name'] ?? 'Online').toString().toUpperCase()}${end != null ? ' · UNTIL ${Fmt.time(end)}' : ''}',
                                style: T.eyebrow(color: C.gold),
                              ),
                              const SizedBox(height: 8),
                              Text('${Fmt.plural(inRoom, 'person')} in the room', style: T.display(26, color: C.bg)),
                            ],
                          ),
                        ),
                        const TibebStrip(height: 10),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _bigTile(
                  color: C.accent,
                  icon: Icons.groups_outlined,
                  title: 'Digital Room',
                  sub: "See who's here right now",
                  onTap: () => _go(context, RoomScreen(eventId: eventId)),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _squareTile(
                        color: C.green,
                        fg: C.bg,
                        icon: Icons.auto_awesome,
                        title: 'AI matches',
                        sub: matches > 0 ? '$matches people to meet' : 'Find people to meet',
                        onTap: () => _go(context, MatchesScreen(eventId: eventId)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _squareTile(
                        color: C.gold,
                        fg: C.ink,
                        icon: Icons.contact_support_outlined,
                        title: 'Live Q&A',
                        sub: hub['qa_enabled'] == true ? 'Ask the panel' : 'Read the questions',
                        onTap: () => _go(context, QaScreen(eventId: eventId)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SurfaceCard(
                  onTap: () => _go(context, AssistantScreen(eventId: eventId)),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(color: C.greenSoft, borderRadius: BorderRadius.circular(14)),
                        child: const Icon(Icons.chat_bubble_outline, color: C.green),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Networking assistant', style: T.body(18, weight: FontWeight.w700)),
                            Text('Get openers for anyone in the room', style: T.body(15, color: C.muted)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _bigTile({required Color color, required IconData icon, required String title, required String sub, required VoidCallback onTap}) =>
      Material(
        color: color,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 34),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: T.display(26, color: Colors.white)),
                      Text(sub, style: T.body(16, color: Colors.white.withValues(alpha: 0.85))),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      );

  Widget _squareTile({
    required Color color,
    required Color fg,
    required IconData icon,
    required String title,
    required String sub,
    required VoidCallback onTap,
  }) => Material(
    color: color,
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        height: 150,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: fg, size: 30),
            const Spacer(),
            Text(title, style: T.display(22, color: fg)),
            Text(sub, style: T.body(15, color: fg.withValues(alpha: 0.85))),
          ],
        ),
      ),
    ),
  );
}
