import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'assistant_screen.dart';

/// UC08 step 6 - another attendee's profile (design: mobile-13). Only visible
/// to people checked in at the same event; shows why the AI matched you.
class PersonScreen extends StatelessWidget {
  final int eventId;
  final int userId;
  const PersonScreen({super.key, required this.eventId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: AsyncView<Profile>(
        load: () async => Profile.fromJson(await api.get('/events/$eventId/room/$userId')),
        builder: (context, p, _) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
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
                      if (p.headline.isNotEmpty) Text(p.headline, style: T.body(16, color: C.muted)),
                    ],
                  ),
                ),
              ],
            ),
            if (p.matchScore != null) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome, color: C.gold),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${(p.matchScore! * 100).round()}% match',
                            style: T.body(17, color: C.bg, weight: FontWeight.w700),
                          ),
                          if (p.matchExplanation != null) Text(p.matchExplanation!, style: T.body(15, color: C.bg.withValues(alpha: 0.85))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if ((p.bio ?? '').isNotEmpty) ...[const SectionTitle('About'), Text(p.bio!, style: T.body(16, color: C.ink2))],
            if (p.skills.isNotEmpty) ...[const SectionTitle('Skills'), TagWrap(p.skills)],
            if (p.interests.isNotEmpty) ...[const SectionTitle('Interests'), TagWrap(p.interests, bg: C.greenSoft, fg: C.greenInk)],
            if (p.goals.isNotEmpty) ...[const SectionTitle('Looking for'), TagWrap(p.goals, bg: C.goldSoft, fg: C.goldInk)],
            const SizedBox(height: 26),
            FilledButton.icon(
              icon: const Icon(Icons.auto_awesome),
              label: Text('Conversation openers for ${p.fullName.split(' ').first}'),
              style: FilledButton.styleFrom(backgroundColor: C.ink),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AssistantScreen(eventId: eventId, target: p),
                ),
              ),
            ),
            if ((p.linkedinUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('LinkedIn'),
                onPressed: () => launchUrl(Uri.parse(p.linkedinUrl!), mode: LaunchMode.externalApplication),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
