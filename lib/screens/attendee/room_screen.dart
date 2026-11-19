import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import 'person_screen.dart';

/// UC08 - Digital Room (design: mobile-12): everyone checked in right now.
/// The list refreshes every 15 seconds so new arrivals appear on their own.
class RoomScreen extends StatefulWidget {
  final int eventId;
  const RoomScreen({super.key, required this.eventId});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  final _search = TextEditingController();
  List<Profile> _people = [];
  int _total = 0;
  String _filter = 'all';
  bool _loading = true;
  Object? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 15), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await api.get('/events/${widget.eventId}/room');
      if (!mounted) return;
      setState(() {
        _people = (res['people'] as List).map((p) => Profile.fromJson(p)).toList();
        _total = (res['checked_in_total'] as num?)?.toInt() ?? 0;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loading = false;
        });
      }
    }
  }

  List<Profile> get _visible {
    final needle = _search.text.trim().toLowerCase();
    return _people
        .where((p) => _filter != 'matches' || p.matchScore != null)
        .where((p) => _filter != 'hiring' || p.goals.contains('Hiring'))
        .where(
          (p) =>
              needle.isEmpty ||
              [p.fullName, p.jobTitle, p.company, ...p.skills, ...p.interests].whereType<String>().join(' ').toLowerCase().contains(needle),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final list = _visible;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Digital Room', style: T.display(28)),
            Row(
              children: [
                const CircleAvatar(radius: 4, backgroundColor: C.green),
                const SizedBox(width: 6),
                Text('$_total checked in · updating live', style: T.body(14, color: C.muted)),
              ],
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.accent))
          : _error != null && _people.isEmpty
          ? ErrorView(error: _error, onRetry: _load)
          : RefreshIndicator(
              color: C.accent,
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          TextField(
                            controller: _search,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(hintText: 'Search by name, skill or company', prefixIcon: Icon(Icons.search)),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _chip('all', 'Everyone'),
                              _chip('matches', 'My matches', icon: Icons.auto_awesome),
                              _chip('hiring', 'Hiring'),
                            ],
                          ),
                          const SizedBox(height: 14),
                        ],
                      ),
                    ),
                  ),
                  if (list.isEmpty)
                    SliverToBoxAdapter(
                      child: EmptyState(
                        icon: Icons.groups_outlined,
                        title: _people.isEmpty ? 'Nobody else is here yet' : 'Nobody matches that',
                        message: _people.isEmpty ? 'People appear as soon as they check in.' : 'Try another search or filter.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          mainAxisExtent: 236,
                        ),
                        delegate: SliverChildBuilderDelegate((_, i) => _personCard(list[i]), childCount: list.length),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _chip(String value, String label, {IconData? icon}) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: icon != null ? Icon(icon, size: 16, color: selected ? C.bg : C.green) : null,
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        selectedColor: C.ink,
        backgroundColor: value == 'matches' ? C.greenSoft : C.surface,
        side: BorderSide(color: value == 'matches' && !selected ? C.greenSoft : C.line),
        shape: const StadiumBorder(),
        labelStyle: T.body(15, weight: FontWeight.w600, color: selected ? C.bg : C.ink),
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _personCard(Profile p) => SurfaceCard(
    padding: const EdgeInsets.all(14),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PersonScreen(eventId: widget.eventId, userId: p.userId),
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Avatar(name: p.fullName, photo: p.photo, size: 52),
            const Spacer(),
            if (p.matchScore != null) Pill('${(p.matchScore! * 100).round()}% match', bg: C.green, fg: C.bg),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          p.fullName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: T.body(17, weight: FontWeight.w700),
        ),
        Text(
          p.headline,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: T.body(14, color: C.muted),
        ),
        const Spacer(),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final s in p.skills.take(2))
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  s,
                  style: T.body(12, weight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
      ],
    ),
  );
}
