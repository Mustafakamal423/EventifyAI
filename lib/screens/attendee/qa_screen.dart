import 'dart:async';

import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// UC11 - Live Q&A (design: mobile-16, FR-17..20). Attendees ask questions
/// (optionally anonymous) and upvote others; the host pins and answers them
/// from the web dashboard. The list refreshes every 5 seconds.
class QaScreen extends StatefulWidget {
  final int eventId;
  const QaScreen({super.key, required this.eventId});

  @override
  State<QaScreen> createState() => _QaScreenState();
}

class _QaScreenState extends State<QaScreen> {
  final _input = TextEditingController();
  String _sort = 'top';
  bool _anonymous = false;
  bool _open = true;
  String _title = '';
  List<Question> _questions = [];
  bool _loading = true;
  Object? _error;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _input.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final res = await api.get('/qa/questions', query: {'event_id': widget.eventId, 'sort': _sort});
      if (!mounted) return;
      setState(() {
        _title = '${res['event']['title']}';
        _open = res['event']['qa_enabled'] == true;
        _questions = (res['questions'] as List).map((q) => Question.fromJson(q)).toList();
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

  Future<void> _upvote(Question q) async {
    try {
      await api.patch('/qa/questions/${q.id}/upvote');
      await _load();
    } catch (e) {
      if (mounted) toast(context, e);
    }
  }

  Future<void> _ask() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    await api.post('/qa/questions', {'event_id': widget.eventId, 'question_text': text, 'is_anonymous': _anonymous});
    _input.clear();
    if (mounted) FocusScope.of(context).unfocus();
    await _load();
    if (mounted) toast(context, 'Question sent to the panel.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Q&A'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _open ? const Pill('LIVE', bg: C.accent, fg: Colors.white) : const Pill('Paused'),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: C.accent))
                : _error != null && _questions.isEmpty
                ? ErrorView(error: _error, onRetry: _load)
                : RefreshIndicator(
                    color: C.accent,
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(color: C.ink, borderRadius: BorderRadius.circular(20)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('ASK THE PANEL', style: T.eyebrow(color: C.gold)),
                              const SizedBox(height: 4),
                              Text(
                                _title,
                                style: T.body(19, color: C.bg, weight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            for (final s in const [('top', 'Top'), ('newest', 'Newest'), ('mine', 'Mine')])
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(s.$2),
                                  selected: _sort == s.$1,
                                  showCheckmark: false,
                                  selectedColor: C.ink,
                                  backgroundColor: C.surface,
                                  side: const BorderSide(color: C.line),
                                  shape: const StadiumBorder(),
                                  labelStyle: T.body(15, weight: FontWeight.w600, color: _sort == s.$1 ? C.bg : C.ink),
                                  onSelected: (_) {
                                    setState(() => _sort = s.$1);
                                    _load();
                                  },
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        if (_questions.isEmpty)
                          EmptyState(
                            icon: Icons.forum_outlined,
                            title: _sort == 'mine' ? "You haven't asked anything yet" : 'No questions yet',
                            message: _open ? 'Be the first to ask the panel.' : null,
                          ),
                        for (final q in _questions) _questionCard(q),
                      ],
                    ),
                  ),
          ),
          _composer(),
        ],
      ),
    );
  }

  Widget _questionCard(Question q) {
    final answered = q.status == 'answered';
    final voted = q.upvotedByMe;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SurfaceCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upvote button: tap again to take the vote back; answered questions are closed
            Material(
              color: voted ? C.accent : C.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: voted ? C.accent : C.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: answered ? null : () => _upvote(q),
                child: SizedBox(
                  width: 54,
                  height: 76,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.arrow_upward, color: voted ? Colors.white : C.ink, size: 22),
                      Text(
                        '${q.upvotes}',
                        style: T.body(17, weight: FontWeight.w700, color: voted ? Colors.white : C.ink),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(q.text, style: T.body(17)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('${q.isMine ? 'You' : q.author} · ${Fmt.ago(q.submittedAt)}', style: T.body(14, color: C.muted)),
                      if (answered) const Pill('Answered', bg: C.greenSoft, fg: C.greenInk),
                      if (q.pinned) const Pill('On screen', bg: C.goldSoft, fg: C.goldInk),
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

  Widget _composer() => Container(
    decoration: const BoxDecoration(
      color: C.surface,
      border: Border(top: BorderSide(color: C.line)),
    ),
    padding: EdgeInsets.fromLTRB(16, 10, 16, 8 + MediaQuery.of(context).padding.bottom),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                enabled: _open,
                maxLength: 500,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _open ? 'Ask the panel a question…' : 'The host is not taking questions right now',
                  fillColor: C.bg,
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(width: 56, height: 56, child: _SendButton(onPressed: _open ? _ask : null)),
          ],
        ),
        Row(
          children: [
            Checkbox(value: _anonymous, activeColor: C.accent, onChanged: _open ? (v) => setState(() => _anonymous = v ?? false) : null),
            Expanded(
              child: Text('Ask anonymously. Visible only to people at this event.', style: T.body(13, color: C.muted)),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SendButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  const _SendButton({required this.onPressed});

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => Material(
    color: widget.onPressed == null ? C.line : C.accent,
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: widget.onPressed == null || _busy
          ? null
          : () async {
              setState(() => _busy = true);
              try {
                await widget.onPressed!();
              } catch (e) {
                if (context.mounted) toast(context, e);
              } finally {
                if (mounted) setState(() => _busy = false);
              }
            },
      child: Center(
        child: _busy
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
            : const Icon(Icons.send, color: Colors.white),
      ),
    ),
  );
}
