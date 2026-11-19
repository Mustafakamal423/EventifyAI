import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../shared/profile_edit_screen.dart';
import 'assistant_screen.dart';
import 'person_screen.dart';

/// UC09 - AI matches (design: mobile-14). The server ranks the people in the
/// room by TF-IDF + cosine similarity of skills, interests and goals (FR-10,
/// FR-11) and explains each match in one line.
class MatchesScreen extends StatelessWidget {
  final int eventId;
  const MatchesScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: C.green,
      appBar: AppBar(backgroundColor: C.green, foregroundColor: C.bg),
      body: Theme(
        data: Theme.of(context).copyWith(progressIndicatorTheme: const ProgressIndicatorThemeData(color: C.gold)),
        child: AsyncView<Map<String, dynamic>>(
          load: () async => Map<String, dynamic>.from(await api.get('/events/$eventId/matches')),
          builder: (context, data, reload) {
            final matches = List<Map<String, dynamic>>.from(data['matches'] ?? []);
            final generated = DateTime.tryParse('${data['generated_at']}');
            final count = ['', 'One person', 'Two people', 'Three people', 'Four people', 'Five people'];
            return RefreshIndicator(
              color: C.green,
              onRefresh: reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                children: [
                  if (generated != null)
                    Text(
                      'Updated ${Fmt.ago(generated.toUtc())}',
                      textAlign: TextAlign.right,
                      style: T.body(14, color: C.greenSoft),
                    ),
                  const SizedBox(height: 6),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: matches.isEmpty
                              ? 'Your matches '
                              : '${matches.length < count.length ? count[matches.length] : '${matches.length} people'} worth ',
                        ),
                        TextSpan(
                          text: matches.isEmpty ? 'appear here' : 'your coffee break',
                          style: T.display(34, color: C.gold),
                        ),
                      ],
                    ),
                    style: T.display(34, color: C.bg),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ranked by how your skills, interests and goals overlap. New matches appear as people check in.',
                    style: T.body(15, color: C.greenSoft),
                  ),
                  const SizedBox(height: 18),
                  if (data['needs_profile'] == true)
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Add your skills and goals first', style: T.body(18, weight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('The AI matches people by what they do and what they are looking for.', style: T.body(15, color: C.muted)),
                          const SizedBox(height: 14),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileEditScreen())).then((_) => reload()),
                            child: const Text('Complete my profile'),
                          ),
                        ],
                      ),
                    )
                  else if (matches.isEmpty)
                    SurfaceCard(
                      child: Text(
                        'Nobody with a similar profile has checked in yet. Pull down to check again in a few minutes.',
                        style: T.body(16, color: C.ink2),
                      ),
                    ),
                  for (final m in matches) _matchCard(context, m),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _matchCard(BuildContext context, Map<String, dynamic> m) {
    final p = Profile.fromJson(Map<String, dynamic>.from(m['person']));
    final score = ((m['similarity_score'] as num?) ?? 0) * 100;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 30,
                  child: Text('${m['rank']}', style: T.display(30, color: C.line)),
                ),
                Avatar(name: p.fullName, photo: p.photo, size: 50),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.fullName, style: T.body(18, weight: FontWeight.w700)),
                      Text(p.headline, style: T.body(14, color: C.muted)),
                    ],
                  ),
                ),
                Text(
                  '${score.round()}%',
                  style: T.mono(16, color: C.green, weight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${m['explanation'] ?? ''}', style: T.body(16, color: C.ink2)),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(100, 46)),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => PersonScreen(eventId: eventId, userId: p.userId),
                          ),
                        ),
                        child: const Text('Profile'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: C.ink, minimumSize: const Size(120, 46)),
                        icon: const Icon(Icons.auto_awesome, size: 18),
                        label: const Text('Openers'),
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AssistantScreen(eventId: eventId, target: p),
                          ),
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
