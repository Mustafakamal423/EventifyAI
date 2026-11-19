import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../utils/share.dart';
import '../../widgets/common.dart';
import 'attendee_shell.dart';
import 'ticket_qr_screen.dart';

/// UC06 - Payment result (design: mobile-08 "You're in.").
///
/// Polls GET /payments/verify/:orderRef. The server asks Chapa for the real
/// status itself, so the tickets are confirmed even if Chapa's webhook is late.
class PaymentResultScreen extends StatefulWidget {
  final String orderRef;
  const PaymentResultScreen({super.key, required this.orderRef});

  @override
  State<PaymentResultScreen> createState() => _PaymentResultScreenState();
}

class _PaymentResultScreenState extends State<PaymentResultScreen> {
  String _status = 'pending';
  List<Ticket> _tickets = [];
  Timer? _timer;
  int _tries = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _check();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _check() async {
    try {
      final res = await api.get('/payments/verify/${Uri.encodeComponent(widget.orderRef)}');
      if (!mounted) return;
      setState(() {
        _status = '${res['status']}';
        _tickets = (res['tickets'] as List? ?? []).map((t) => Ticket.fromJson(t)).toList();
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
    // Keep asking every 3 s for up to 2 minutes while Chapa is still processing
    if (_status == 'pending' && _tries++ < 40 && mounted) {
      _timer = Timer(const Duration(seconds: 3), _check);
    }
  }

  /// Opens Google Calendar with the event filled in.
  void _addToCalendar(EventItem e) {
    String g(DateTime d) => '${d.toUtc().toIso8601String().replaceAll(RegExp(r'[-:]'), '').split('.').first}Z';
    final uri = Uri.https('calendar.google.com', '/calendar/render', {
      'action': 'TEMPLATE',
      'text': e.title,
      'dates': '${g(e.start)}/${g(e.end)}',
      'location': [e.venueName, e.venueAddress].whereType<String>().join(', '),
    });
    launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 20),
          child: _status == 'confirmed' && _tickets.isNotEmpty ? _confirmed(context) : _waiting(context),
        ),
      ),
    );
  }

  Widget _confirmed(BuildContext context) {
    final t = _tickets.first;
    final email = context.read<Session>().user?.email ?? 'your email';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: C.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check, color: Colors.white, size: 34),
                ),
              ),
              const SizedBox(height: 20),
              Text("You're in.", style: T.display(48)),
              const SizedBox(height: 10),
              Text(
                t.price == 0
                    ? 'Your free ticket is confirmed. We also emailed it to $email.'
                    : 'Chapa confirmed your payment. We also emailed your ticket to $email.',
                style: T.body(17, color: C.muted),
              ),
              const SizedBox(height: 24),
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  color: C.ink,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const TibebStrip(height: 10),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${t.typeName.toUpperCase()} · ${Fmt.plural(_tickets.length, 'TICKET')}', style: T.eyebrow(color: C.gold)),
                            const SizedBox(height: 6),
                            Text(t.event.title, style: T.display(26, color: C.bg)),
                            const SizedBox(height: 4),
                            Text('${Fmt.dateTime(t.event.start)} · ${t.event.place}', style: T.body(15, color: C.darkMuted)),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: C.darkLine),
                            ),
                            Row(
                              children: [
                                if (t.qrImage != null)
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(14)),
                                    child: Image.memory(base64Decode(t.qrImage!.split(',').last), width: 72, height: 72),
                                  ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Attendee', style: T.body(14, color: C.darkMuted)),
                                      Text(
                                        context.read<Session>().user?.fullName ?? '',
                                        style: T.body(18, color: C.bg, weight: FontWeight.w700),
                                      ),
                                      Text(
                                        t.code,
                                        style: T.mono(13, color: C.darkMuted, weight: FontWeight.w500),
                                      ),
                                    ],
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
              ),
              if (_tickets.length > 1) ...[
                const SizedBox(height: 16),
                Text('Going with friends? Open My Tickets and use "Send to a friend" on each extra ticket.', style: T.body(15, color: C.muted)),
              ],
            ],
          ),
        ),
        FilledButton(
          onPressed: () {
            AttendeeTabs.go(context, AttendeeTabs.tickets);
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => TicketQrScreen(ticketId: t.id)));
          },
          child: Text(_tickets.length > 1 ? 'Open my tickets' : 'Open ticket'),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(onPressed: () => _addToCalendar(t.event), child: const Text('Add to calendar')),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => shareEvent(t.event),
                icon: const Icon(Icons.ios_share, size: 18),
                label: const Text('Invite friends'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _waiting(BuildContext context) {
    final pending = _status == 'pending';
    final stillPolling = pending && _tries <= 40;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        if (stillPolling)
          const Center(
            child: SizedBox(width: 56, height: 56, child: CircularProgressIndicator(color: C.accent, strokeWidth: 4)),
          )
        else
          Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: C.accentSoft, shape: BoxShape.circle),
              child: Icon(pending ? Icons.hourglass_bottom : Icons.close, color: C.accent, size: 34),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          stillPolling ? 'Confirming with Chapa…' : (pending ? 'Still waiting for Chapa' : 'Payment not completed'),
          textAlign: TextAlign.center,
          style: T.display(30),
        ),
        const SizedBox(height: 10),
        Text(
          stillPolling
              ? 'This usually takes a few seconds. Please keep the app open.'
              : pending
              ? "Chapa hasn't confirmed yet. If you paid, your tickets will appear in My Tickets as soon as it does."
              : 'No money was taken, or it will be refunded. Your seats were released.',
          textAlign: TextAlign.center,
          style: T.body(16, color: C.muted),
        ),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: T.body(14, color: C.danger),
          ),
        ],
        const Spacer(),
        if (!stillPolling) ...[
          if (pending)
            FilledButton(
              onPressed: () {
                setState(() => _tries = 0);
                _check();
              },
              child: const Text('Check again'),
            ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: () => AttendeeTabs.go(context, AttendeeTabs.tickets), child: const Text('Go to My Tickets')),
        ],
      ],
    );
  }
}
