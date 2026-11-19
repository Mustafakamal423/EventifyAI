import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../shared/notifications_screen.dart';
import '../shared/profile_edit_screen.dart';
import 'attendee_shell.dart';

/// The attendee's own profile (design: mobile-17) with the profile-strength
/// meter, which tells them what to add for better AI matches.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _view = GlobalKey<AsyncViewState<Profile>>();

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
    if (attendeeTab.value == AttendeeTabs.profile) _view.currentState?.reload();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<Session>();
    return SafeArea(
      child: AsyncView<Profile>(
        key: _view,
        load: () async => Profile.fromJson(await api.get('/profile')),
        builder: (context, p, reload) {
          final tags = {...p.skills, ...p.interests}.toList();
          return RefreshIndicator(
            color: C.accent,
            onRefresh: reload,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Row(
                  children: [
                    Avatar(name: p.fullName, photo: p.photo, size: 84),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.fullName, style: T.display(28)),
                          Text(p.headline.isNotEmpty ? p.headline : (session.user?.email ?? ''), style: T.body(16, color: C.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (session.user?.emailVerified == false) ...[const SizedBox(height: 16), const _VerifyEmailBanner()],
                const SizedBox(height: 18),
                if (p.strengthScore != null)
                  SurfaceCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Profile strength', style: T.body(17, weight: FontWeight.w700)),
                            ),
                            Text('${p.strengthScore}%', style: T.mono(16, weight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(value: p.strengthScore! / 100, minHeight: 10, color: C.green, backgroundColor: C.fill),
                        ),
                        if (p.strengthTip != null) ...[const SizedBox(height: 10), Text(p.strengthTip!, style: T.body(15, color: C.muted))],
                      ],
                    ),
                  ),
                if (tags.isNotEmpty) ...[const SectionTitle('Skills & interests'), TagWrap(tags)],
                if (p.goals.isNotEmpty) ...[const SectionTitle('Looking for'), TagWrap(p.goals, bg: C.greenSoft, fg: C.greenInk)],
                const SizedBox(height: 22),
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      _menuItem(
                        'Edit profile',
                        () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())).then((_) => reload()),
                      ),
                      const Divider(),
                      _menuItem('Notifications', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen()))),
                      const Divider(),
                      _menuItem('Payments & refunds', () => attendeeTab.value = AttendeeTabs.tickets),
                      const Divider(),
                      _menuItem('Help', () => launchUrl(Uri.parse('mailto:eventifyai@xvalue.et?subject=Eventify%20AI%20help'))),
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
        },
      ),
    );
  }

  Widget _menuItem(String label, VoidCallback onTap) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
    title: Text(label, style: T.body(18, weight: FontWeight.w700)),
    trailing: const Icon(Icons.chevron_right),
    onTap: onTap,
  );
}

/// "Confirm your email" reminder with a resend button.
class _VerifyEmailBanner extends StatelessWidget {
  const _VerifyEmailBanner();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: C.goldSoft, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        const Icon(Icons.mark_email_unread_outlined, color: C.goldInk),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Confirm your email to receive your tickets by email.',
            style: T.body(14, color: C.goldInk, weight: FontWeight.w600),
          ),
        ),
        TextButton(
          onPressed: () async {
            try {
              await api.post('/auth/resend-verification');
              if (context.mounted) toast(context, 'Confirmation email sent. Check your inbox.');
            } catch (e) {
              if (context.mounted) toast(context, e);
            }
          },
          child: const Text('Resend'),
        ),
      ],
    ),
  );
}
