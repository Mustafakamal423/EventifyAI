import 'package:flutter/material.dart';

import '../../api/api_client.dart';
import '../../api/models.dart';
import '../../config.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'chapa_checkout_screen.dart';
import 'payment_result_screen.dart';

/// UC05 - Buy tickets (design: mobile-07 Checkout).
///
/// 1. The attendee picks a ticket type and quantity (max 10, BR-05).
/// 2. POST /tickets/initiate reserves the seats atomically and asks Chapa for a
///    hosted checkout page (or confirms straight away for free tickets).
/// 3. Chapa's page opens inside the app; when Chapa sends the user back, the
///    result screen asks the server to verify the payment (UC06).
class CheckoutScreen extends StatefulWidget {
  final EventItem event;
  const CheckoutScreen({super.key, required this.event});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late TicketType? _selected = widget.event.ticketTypes.where((t) => !t.soldOut).firstOrNull;
  int _qty = 1;

  int get _maxQty => (_selected?.remaining ?? 1).clamp(1, 10);
  double get _total => (_selected?.price ?? 0) * _qty;

  Future<void> _pay() async {
    final res = await api.post('/tickets/initiate', {'ticket_type_id': _selected!.id, 'quantity': _qty});
    final orderRef = '${res['order_ref']}';
    if (!mounted) return;

    if (res['free'] == true) {
      // Free tickets are confirmed by the server without Chapa
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PaymentResultScreen(orderRef: orderRef)));
      return;
    }

    final url = '${res['checkout_url']}';
    final returned = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ChapaCheckoutScreen(checkoutUrl: url.startsWith('http') ? url : '${AppConfig.baseUrl}$url', orderRef: orderRef),
      ),
    );
    if (!mounted) return;
    // Whether Chapa redirected back or the user closed the page, ask the server
    // for the real status: the result screen polls /payments/verify.
    if (returned != null) {
      await Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => PaymentResultScreen(orderRef: orderRef)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Get tickets', style: T.display(26)),
            Text('${e.title} · ${Fmt.shortDate(e.start)}', style: T.body(15, color: C.muted)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          for (final t in e.ticketTypes) _typeOption(t),
          const SizedBox(height: 6),
          SurfaceCard(
            child: Row(
              children: [
                Expanded(
                  child: Text('Quantity', style: T.body(18, weight: FontWeight.w700)),
                ),
                _qtyButton(Icons.remove, _qty > 1 ? () => setState(() => _qty--) : null),
                SizedBox(
                  width: 48,
                  child: Text(
                    '$_qty',
                    textAlign: TextAlign.center,
                    style: T.body(20, weight: FontWeight.w700),
                  ),
                ),
                _qtyButton(Icons.add, _selected != null && _qty < _maxQty ? () => setState(() => _qty++) : null),
              ],
            ),
          ),
          if (_qty > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                "Buying for friends? After paying, send each extra ticket from My Tickets. They get their own QR code.",
                style: T.body(14, color: C.muted),
              ),
            ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: C.fill, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: Text('${_selected?.name ?? '-'} × $_qty', style: T.body(16))),
                    Text(Fmt.money(_total, freeWord: false), style: T.mono(16)),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: C.line),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text('Total', style: T.body(18, weight: FontWeight.w700)),
                    ),
                    Text(Fmt.money(_total), style: T.display(28)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_outline, color: C.green, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _total == 0 ? 'Free tickets are confirmed straight away. Your QR ticket appears in My Tickets.' : "You'll finish payment securely on Chapa with telebirr, CBE Birr, M-Pesa or card. Your QR ticket appears here as soon as Chapa confirms.",
                  style: T.body(15, color: C.ink2),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: BusyButton(
          label: _selected == null ? 'Sold out' : (_total == 0 ? 'Get free ticket${_qty > 1 ? 's' : ''}' : 'Pay ${Fmt.money(_total)} with Chapa'),
          onPressed: _selected == null ? null : _pay,
        ),
      ),
    );
  }

  Widget _typeOption(TicketType t) {
    final selected = _selected?.id == t.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Opacity(
        opacity: t.soldOut ? 0.5 : 1,
        child: Material(
          color: C.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: selected ? C.ink : C.line, width: selected ? 2.5 : 1.5),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: t.soldOut
                ? null
                : () => setState(() {
                    _selected = t;
                    _qty = _qty.clamp(1, _maxQty);
                  }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(selected ? Icons.radio_button_checked : Icons.radio_button_off, color: selected ? C.accent : C.line, size: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.name, style: T.body(18, weight: FontWeight.w700)),
                        if ((t.description ?? '').isNotEmpty) Text(t.description!, style: T.body(15, color: C.muted)),
                        if (t.soldOut)
                          Text(
                            'Sold out',
                            style: T.body(14, color: C.danger, weight: FontWeight.w700),
                          )
                        else if (t.fewLeft)
                          Text(
                            'Only ${t.remaining} left',
                            style: T.body(14, color: C.accent, weight: FontWeight.w700),
                          ),
                      ],
                    ),
                  ),
                  Text(Fmt.money(t.price), style: T.mono(16, weight: FontWeight.w700)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback? onTap) => Material(
    color: C.fill,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: C.line),
    ),
    child: IconButton(icon: Icon(icon), onPressed: onTap, color: C.ink, disabledColor: C.line),
  );
}
