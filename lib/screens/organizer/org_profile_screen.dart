import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../shared/notifications_screen.dart';

/// Organizer account tab: who is logged in, links to the web dashboard, logout.
class OrgProfileScreen extends StatelessWidget {
  const OrgProfileScreen({super.key});

  void _web(String path) => launchUrl(Uri.parse('${AppConfig.baseUrl}$path'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          Row(
            children: [
              Avatar(name: user.fullName, size: 76, square: true),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName, style: T.display(26)),
                    Text(user.email, style: T.body(15, color: C.muted)),
                    const SizedBox(height: 6),
                    const Pill('Organizer', bg: C.goldSoft, fg: C.goldInk),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _item(Icons.dashboard_outlined, 'Web dashboard', () => _web('/dashboard')),
                const Divider(),
                _item(Icons.add_box_outlined, 'Create an event', () => _web('/dashboard/events/new')),
                const Divider(),
                _item(Icons.forum_outlined, 'Moderate live Q&A', () => _web('/dashboard/qa')),
                const Divider(),
                _item(Icons.bar_chart, 'Analytics', () => _web('/dashboard/analytics')),
                const Divider(),
                _item(
                  Icons.notifications_none,
                  'Notifications',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
                  external: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: () => context.read<Session>().logout(),
              child: Text(
                'Log out',
                style: T.body(17, color: C.accent, weight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(IconData icon, String label, VoidCallback onTap, {bool external = true}) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    leading: Icon(icon, color: C.ink2),
    title: Text(label, style: T.body(17, weight: FontWeight.w700)),
    trailing: Icon(external ? Icons.open_in_new : Icons.chevron_right, size: 20),
    onTap: onTap,
  );
}
