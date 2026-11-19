import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'organizer_shell.dart';

/// FR-08 - Live attendance (design: mobile-21). Updates every 10 seconds while
/// open. Attendees who haven't arrived can be checked in by hand (e.g. their
/// phone died), which goes through the same server rules as a scan.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _search = TextEditingController();
  Map<String, dynamic>? _stats;
  List<Map<String, dynamic>> _people = [];
  String _type = 'All';
  bool _showArrived = true;
  Object? _error;
  bool _loading = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    doorEvent.addListener(_reset);
    organizerTab.addListener(_onTab);
    _reset();
  }

  @override
  void dispose() {
    doorEvent.removeListener(_reset);
    organizerTab.removeListener(_onTab);
    _poll?.cancel();
    _search.dispose();
    super.dispose();
  }

  /// Poll only while this tab is visible.
  void _onTab() {
    _poll?.cancel();
    if (organizerTab.value == OrganizerTabs.attendance) {
      _load();
      _poll = Timer.periodic(const Duration(seconds: 10), (_) => _load());
    }
  }

  void _reset() {
    setState(() {
      _stats = null;
      _people = [];
      _type = 'All';
    });
    _load();
  }

  Future<void> _load() async {
    final e = doorEvent.value;
    if (e == null) return;
    if (_stats == null) setState(() => _loading = true);
    try {
      final res = await api.get('/events/${e.id}/attendees');
      if (!mounted || doorEvent.value?.id != e.id) return;
      setState(() {
        _stats = Map<String, dynamic>.from(res['stats']);
        _people = List<Map<String, dynamic>>.from(res['attendees']);
        _error = null;
      });
    } catch (err) {
      if (mounted) setState(() => _error = err);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _manualCheckIn(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Check in ${p['full_name']}?'),
        content: Text('Only do this after checking their ID or ticket code (${p['ticket_code']}).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Check in')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await api.post('/checkin/manual', {'ticket_id': p['ticket_id'], 'event_id': doorEvent.value?.id});
      if (mounted) toast(context, '${p['full_name']} is checked in.');
      await _load();
    } catch (e) {
      if (mounted) toast(context, e);
    }
  }

  Future<void> _pickEvent() async {
    try {
      final res = await api.get('/events/mine');
      final events = (res['events'] as List).map((e) => EventItem.fromJson(e)).where((e) => e.status != 'draft').toList();
      if (!mounted) return;
      final picked = await showModalBottomSheet<EventItem>(
        context: context,
        backgroundColor: C.bg,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              for (final e in events)
                ListTile(
                  title: Text(e.title, style: T.body(16, weight: FontWeight.w700)),
                  subtitle: Text(Fmt.dateTime(e.start)),
                  trailing: Pill.status(e.status),
                  onTap: () => Navigator.pop(ctx, e),
                ),
            ],
          ),
        ),
      );
      if (picked != null) doorEvent.value = picked;
    } catch (e) {
      if (mounted) toast(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = doorEvent.value;
    if (event == null) {
      return SafeArea(
        child: Center(
          child: EmptyState(
            icon: Icons.groups_outlined,
            title: 'Choose an event',
            message: 'Pick the event you are checking people in for.',
            action: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(180, 48)),
              onPressed: _pickEvent,
              child: const Text('Choose event'),
            ),
          ),
        ),
      );
    }

    final needle = _search.text.trim().toLowerCase();
    final types = {'All', ..._people.map((p) => '${p['type_name']}')};
    final visible = _people
        .where((p) => _type == 'All' || p['type_name'] == _type)
        .where((p) => _showArrived ? p['status'] == 'checked_in' : p['status'] == 'confirmed')
        .where((p) => needle.isEmpty || '${p['full_name']} ${p['ticket_code']}'.toLowerCase().contains(needle))
        .toList();
    final s = _stats;
    final total = (s?['total'] as num?)?.toInt() ?? 0;
    final inside = (s?['checked_in'] as num?)?.toInt() ?? 0;
    final rate = total == 0 ? 0 : (inside * 100 / total).round();

    return SafeArea(
      child: RefreshIndicator(
        color: C.accent,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Text('Live attendance', style: T.display(32)),
            InkWell(
              onTap: _pickEvent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const CircleAvatar(radius: 4, backgroundColor: C.green),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        '${event.title} · updates live',
                        overflow: TextOverflow.ellipsis,
                        style: T.body(15, color: C.muted),
                      ),
                    ),
                    const Icon(Icons.expand_more, color: C.muted, size: 20),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_loading && s == null)
              const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: C.accent)),
              )
            else if (_error != null && s == null)
              ErrorView(error: _error, onRetry: _load)
            else ...[
              Row(
                children: [
                  _stat('$inside', 'Checked in', dark: true),
                  const SizedBox(width: 10),
                  _stat('${(s?['not_arrived'] as num?)?.toInt() ?? 0}', 'Not yet'),
                  const SizedBox(width: 10),
                  _stat('$rate%', 'Rate'),
                ],
              ),
              if (((s?['duplicate_scans'] as num?) ?? 0) > 0) ...[
                const SizedBox(height: 8),
                Text(
                  '${s!['duplicate_scans']} duplicate scan(s) blocked',
                  style: T.body(14, color: C.accent, weight: FontWeight.w600),
                ),
              ],
              const SizedBox(height: 14),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(hintText: 'Search name or ticket code', prefixIcon: Icon(Icons.search)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final t in types)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: _type == t,
                          showCheckmark: false,
                          selectedColor: C.ink,
                          backgroundColor: C.surface,
                          side: const BorderSide(color: C.line),
                          shape: const StadiumBorder(),
                          labelStyle: T.body(15, weight: FontWeight.w600, color: _type == t ? C.bg : C.ink),
                          onSelected: (_) => setState(() => _type = t),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Arrived')),
                  ButtonSegment(value: false, label: Text('Not arrived')),
                ],
                selected: {_showArrived},
                showSelectedIcon: false,
                onSelectionChanged: (v) => setState(() => _showArrived = v.first),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                EmptyState(
                  icon: Icons.person_search_outlined,
                  title: _showArrived ? 'Nobody checked in yet' : 'Everyone is here',
                  message: needle.isNotEmpty || _type != 'All' ? 'Try another search or filter.' : null,
                )
              else
                SurfaceCard(
                  padding: EdgeInsets.zero,
                  child: Column(
                    children: [
                      for (final (i, p) in visible.indexed) ...[
                        if (i > 0) const Divider(),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Avatar(name: '${p['full_name']}', photo: p['profile_photo'], size: 46),
                          title: Text('${p['full_name']}', style: T.body(17, weight: FontWeight.w700)),
                          subtitle: Text('${p['type_name']} · ${p['ticket_code']}', style: T.body(13, color: C.muted)),
                          trailing: p['status'] == 'checked_in'
                              ? Text(p['checked_in_at'] != null ? Fmt.time(DateTime.parse('${p['checked_in_at']}')) : '', style: T.mono(15))
                              : TextButton(onPressed: () => _manualCheckIn(p), child: const Text('Check in')),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label, {bool dark = false}) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? C.ink : C.surface,
        borderRadius: BorderRadius.circular(18),
        border: dark ? null : Border.all(color: C.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            child: Text(value, style: T.display(32, color: dark ? C.bg : C.ink)),
          ),
          Text(label, style: T.body(14, color: dark ? C.darkMuted : C.muted)),
        ],
      ),
    ),
  );
}
