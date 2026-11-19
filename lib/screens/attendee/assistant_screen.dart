import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// UC10 - AI networking assistant (design: mobile-15, FR-12).
///
/// A chat about one person in the room (or about networking in general).
/// The whole conversation is sent each time; the server adds both profiles
/// and asks Google Gemini for an answer, so the API key never touches the phone.
class AssistantScreen extends StatefulWidget {
  final int eventId;
  final Profile? target;
  const AssistantScreen({super.key, required this.eventId, this.target});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _Message {
  final String role; // user | assistant
  final String content;
  _Message(this.role, this.content);
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_Message> _history = [];
  List<Profile> _people = [];
  Profile? _target;
  bool _thinking = false;

  @override
  void initState() {
    super.initState();
    _target = widget.target;
    _loadPeople();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadPeople() async {
    try {
      final res = await api.get('/events/${widget.eventId}/room');
      if (mounted) setState(() => _people = (res['people'] as List).map((p) => Profile.fromJson(p)).toList());
    } catch (_) {
      // The picker is optional; the chat still works without it
    }
  }

  List<String> get _suggestions {
    final t = _target;
    if (t == null) return ['Who should I talk to first?', 'Give me a 20-second introduction of myself', 'How do I leave a conversation politely?'];
    final first = t.fullName.split(' ').first;
    return [
      'How should I start a conversation with $first?',
      'What should I ask about their work?',
      'Write a short follow-up message',
      "Summarize $first's profile",
    ];
  }

  Future<void> _send(String text) async {
    text = text.trim();
    if (text.isEmpty || _thinking) return;
    _input.clear();
    setState(() {
      _history.add(_Message('user', text));
      _thinking = true;
    });
    _scrollDown();
    try {
      final res = await api.post('/events/${widget.eventId}/assistant', {
        'target_user_id': _target?.userId,
        'messages': [
          for (final m in _history.length > 40 ? _history.sublist(_history.length - 40) : _history) {'role': m.role, 'content': m.content},
        ],
      });
      if (mounted) setState(() => _history.add(_Message('assistant', '${res['reply']}')));
    } catch (e) {
      if (mounted) {
        // Take the question back out so it can be resent
        setState(() => _history.removeLast());
        _input.text = text;
        toast(context, e);
      }
    } finally {
      if (mounted) setState(() => _thinking = false);
      _scrollDown();
    }
  }

  void _scrollDown() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (_scroll.hasClients) _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  });

  void _pickTarget() async {
    final picked = await showModalBottomSheet<Profile?>(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: C.fill,
                child: Icon(Icons.public, color: C.ink),
              ),
              title: const Text('General networking advice'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            for (final p in _people)
              ListTile(
                leading: Avatar(name: p.fullName, photo: p.photo, size: 40),
                title: Text(p.fullName),
                subtitle: Text(p.headline),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _target = picked;
      _history.clear(); // a new person starts a new conversation
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Networking assistant', style: T.display(24)),
            Text('Uses your profile and theirs', style: T.body(14, color: C.muted)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Who the conversation is about
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SurfaceCard(
              padding: const EdgeInsets.all(12),
              onTap: _pickTarget,
              child: Row(
                children: [
                  _target == null
                      ? const CircleAvatar(
                          radius: 20,
                          backgroundColor: C.fill,
                          child: Icon(Icons.public, color: C.ink, size: 20),
                        )
                      : Avatar(name: _target!.fullName, photo: _target!.photo, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_target?.fullName ?? 'General advice', style: T.body(16, weight: FontWeight.w700)),
                        Text(
                          _target?.headline.isNotEmpty == true ? _target!.headline : 'Tap to pick someone in the room',
                          style: T.body(13, color: C.muted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.unfold_more, color: C.muted),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              children: [
                if (_history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_awesome, color: C.green, size: 36),
                        const SizedBox(height: 10),
                        Text(
                          _target == null
                              ? 'Ask for networking tips for this event.'
                              : 'Ask how to start a conversation with ${_target!.fullName.split(' ').first}.',
                          textAlign: TextAlign.center,
                          style: T.body(16, color: C.muted),
                        ),
                      ],
                    ),
                  ),
                for (final m in _history) _bubble(m),
                if (_thinking) _bubble(_Message('assistant', 'Thinking…'), faded: true),
              ],
            ),
          ),
          if (!_thinking)
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final s in _suggestions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8, bottom: 6),
                      child: ActionChip(
                        label: Text(s),
                        backgroundColor: C.surface,
                        side: const BorderSide(color: C.line),
                        shape: const StadiumBorder(),
                        labelStyle: T.body(14, weight: FontWeight.w600),
                        onPressed: () => _send(s),
                      ),
                    ),
                ],
              ),
            ),
          _composer(),
        ],
      ),
    );
  }

  Widget _bubble(_Message m, {bool faded = false}) {
    final mine = m.role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: mine ? C.ink : C.surface,
          border: mine ? null : Border.all(color: C.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: SelectableText(m.content, style: T.body(16, color: mine ? C.bg : (faded ? C.muted : C.ink))),
      ),
    );
  }

  Widget _composer() => Container(
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(top: BorderSide(color: C.line)),
    ),
    padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + MediaQuery.of(context).padding.bottom),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _input,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: _send,
            decoration: const InputDecoration(hintText: 'Ask the assistant…', fillColor: C.bg),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: C.accent,
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            tooltip: 'Send',
            onPressed: _thinking ? null : () => _send(_input.text),
          ),
        ),
      ],
    ),
  );
}
