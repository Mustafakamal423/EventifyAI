import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/brand.dart';

/// The admin is the SaaS owner. Managing organizers, users and platform
/// analytics happens on the web dashboard, so the app only points there.
class AdminWebOnlyScreen extends StatelessWidget {
  const AdminWebOnlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.ink,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const BrandMark(onDark: true),
              const Spacer(),
              Text('PLATFORM ADMIN', style: T.eyebrow(color: C.gold)),
              const SizedBox(height: 10),
              Text('The admin panel lives on the web', style: T.display(36, color: C.bg)),
              const SizedBox(height: 14),
              Text(
                'Organizers, users, platform analytics and settings are managed from the web dashboard. '
                'The mobile app is for attendees and for organizers at the door.',
                style: T.body(17, color: C.darkMuted),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open the admin dashboard'),
                onPressed: () => launchUrl(Uri.parse('${AppConfig.baseUrl}/admin'), mode: LaunchMode.externalApplication),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.bg,
                  side: const BorderSide(color: C.darkLine),
                ),
                onPressed: () => context.read<Session>().logout(),
                child: const Text('Log out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
