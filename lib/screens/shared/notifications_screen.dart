import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// In-app notifications (UC12): ticket confirmed, check-in, event reminders,
/// cancellations, tickets received from friends.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static IconData _icon(String type) {
    switch (type) {
      case 'ticket_confirmed':
        return Icons.confirmation_number_outlined;
      case 'checkin':
        return Icons.how_to_reg_outlined;
      case 'event_cancelled':
        return Icons.event_busy_outlined;
      case 'ticket_received':
      case 'ticket_sent':
        return Icons.card_giftcard;
      case 'reminder':
        return Icons.alarm;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: AsyncView<List<AppNotification>>(
        load: () async {
          final res = await api.get('/notifications');
          final list = (res['notifications'] as List).map((n) => AppNotification.fromJson(n)).toList();
          // Opening the list counts as reading them
          if (list.any((n) => !n.isRead)) api.patch('/notifications/read-all').catchError((_) => null);
          return list;
        },
        builder: (context, list, reload) => RefreshIndicator(
          color: C.accent,
          onRefresh: reload,
          child: list.isEmpty
              ? ListView(
                  children: const [
                    EmptyState(
                      icon: Icons.notifications_none,
                      title: 'No notifications yet',
                      message: 'Ticket confirmations and event updates show up here.',
                    ),
                  ],
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final n = list[i];
                    return SurfaceCard(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(color: n.isRead ? C.fill : C.accentSoft, borderRadius: BorderRadius.circular(12)),
                            child: Icon(_icon(n.type), color: n.isRead ? C.muted : C.accent),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(n.title, style: T.body(16, weight: FontWeight.w700)),
                                    ),
                                    Text(Fmt.ago(n.createdAt), style: T.body(13, color: C.muted)),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(n.body, style: T.body(15, color: C.ink2)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
