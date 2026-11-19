import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/common.dart';
import '../../widgets/event_cards.dart';
import '../shared/notifications_screen.dart';
import 'event_detail_screen.dart';

/// UC04 - Browse events (design: mobile-05 Explore).
/// "Picked for you" comes from the recommendation service (interests and past
/// events, FR-21); "Coming up" is every event on sale, filtered by search text
/// and category.
class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _search = TextEditingController();
  Timer? _debounce;
  String? _category;
  List<String> _categories = [];
  List<EventItem> _picked = [];
  List<EventItem> _events = [];
  int _unread = 0;
  bool _loading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([api.get('/events/categories'), api.get('/events/recommended'), api.get('/notifications')]);
      _categories = List<String>.from(results[0]['categories'] ?? []);
      _picked = (results[1]['events'] as List).map((e) => EventItem.fromJson(e)).toList();
      _unread = (results[2]['unread'] as num?)?.toInt() ?? 0;
      await _loadEvents();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadEvents() async {
    final res = await api.get('/events', query: {'q': _search.text.trim(), 'category': _category});
    final list = (res['events'] as List).map((e) => EventItem.fromJson(e)).toList();
    if (mounted) {
      setState(() {
        _events = list;
        _error = null;
      });
    }
  }

  void _showError(Object e) {
    if (mounted) toast(context, e);
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 350),
      () => _loadEvents().catchError(_showError),
    );
  }

  void _open(EventItem e) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: e.id))).then((_) => _loadAll());

  @override
  Widget build(BuildContext context) {
    final user = context.watch<Session>().user!;
    final filtering = _search.text.trim().isNotEmpty || _category != null;
    // Don't repeat the featured event in the list below it
    final featured = filtering || _picked.isEmpty ? null : _picked.first;
    final list = _events.where((e) => e.id != featured?.id).toList();

    return SafeArea(
      child: RefreshIndicator(
        color: C.accent,
        onRefresh: _loadAll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Selam, ${user.firstName}', style: T.body(16, color: C.muted)),
                      Text("What's on in Addis", style: T.display(30)),
                    ],
                  ),
                ),
                Stack(
                  children: [
                    CircleIconButton(
                      icon: Icons.notifications_none,
                      tooltip: 'Notifications',
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())).then((_) => _loadAll()),
                    ),
                    if (_unread > 0) const Positioned(right: 10, top: 10, child: CircleAvatar(radius: 5, backgroundColor: C.accent)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _search,
              onChanged: _onSearch,
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(hintText: 'Events, speakers, venues', prefixIcon: Icon(Icons.search)),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final c in [null, ..._categories])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(c ?? 'All'),
                        selected: _category == c,
                        showCheckmark: false,
                        selectedColor: C.ink,
                        backgroundColor: C.surface,
                        side: const BorderSide(color: C.line),
                        shape: const StadiumBorder(),
                        labelStyle: T.body(15, weight: FontWeight.w600, color: _category == c ? C.bg : C.ink),
                        onSelected: (_) {
                          setState(() => _category = c);
                          _loadEvents().catchError(_showError);
                        },
                      ),
                    ),
                ],
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(48),
                child: Center(child: CircularProgressIndicator(color: C.accent)),
              )
            else if (_error != null && _events.isEmpty)
              ErrorView(error: _error, onRetry: _loadAll)
            else ...[
              if (featured != null) ...[
                SectionTitle(
                  'Picked for you',
                  trailing: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 16, color: C.green),
                      const SizedBox(width: 4),
                      Text(
                        'From your interests',
                        style: T.body(14, color: C.green, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
                FeaturedEventCard(event: featured, onTap: () => _open(featured)),
              ],
              SectionTitle(filtering ? 'Results' : 'Coming up'),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.event_busy_outlined,
                  title: filtering ? 'No events match' : 'No events yet',
                  message: filtering ? 'Try another word or category.' : 'New events will show up here.',
                )
              else
                for (var i = 0; i < list.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: EventRowCard(event: list[i], index: i, onTap: () => _open(list[i])),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
