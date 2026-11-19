import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../api/api_client.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/// Chapa's hosted checkout page inside the app (UC05 step 4, SDD 3.9).
///
/// The app never sees card or mobile-money details: the attendee pays on
/// Chapa's own page. When Chapa finishes it sends the browser to our
/// return_url (/payment/return?order=...); we catch that navigation, close
/// this screen and let the result screen verify the payment with the server.
/// Returns true when Chapa redirected back, false when the user closed the page.
class ChapaCheckoutScreen extends StatefulWidget {
  final String checkoutUrl;
  final String orderRef;
  const ChapaCheckoutScreen({super.key, required this.checkoutUrl, required this.orderRef});

  @override
  State<ChapaCheckoutScreen> createState() => _ChapaCheckoutScreenState();
}

class _ChapaCheckoutScreenState extends State<ChapaCheckoutScreen> {
  late final WebViewController _web;
  int _progress = 0;
  bool _done = false;

  bool get _isMock => widget.checkoutUrl.contains('/payments/mock-checkout/');

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(C.bg)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (p) => mounted ? setState(() => _progress = p) : null,
          onNavigationRequest: (req) {
            final url = req.url;
            // Back from Chapa: close the web page and verify in the app
            if (url.contains('/payment/return')) {
              _finish(true);
              return NavigationDecision.prevent;
            }
            // Bank / wallet apps (telebirr, CBE Birr...) open outside the WebView
            if (!url.startsWith('http')) {
              launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    if (!_isMock) _web.loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _finish(bool returned) {
    if (_done) return;
    _done = true;
    Navigator.of(context).pop(returned);
  }

  Future<bool> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave payment?'),
        content: const Text('If you already paid, we will still check with Chapa and your tickets will appear.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Stay')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Leave')),
        ],
      ),
    );
    return leave == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _confirmLeave() && mounted) _finish(false);
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close',
            onPressed: () async {
              if (await _confirmLeave() && mounted) _finish(false);
            },
          ),
          title: Row(
            children: [
              const Icon(Icons.lock, size: 18, color: C.green),
              const SizedBox(width: 8),
              Text(_isMock ? 'Test checkout' : 'Pay with Chapa', style: T.body(18, weight: FontWeight.w700)),
            ],
          ),
          bottom: _progress < 100 && !_isMock
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(3),
                  child: LinearProgressIndicator(value: _progress / 100, color: C.accent, backgroundColor: C.fill, minHeight: 3),
                )
              : null,
        ),
        body: _isMock ? _mockCheckout() : WebViewWidget(controller: _web),
      ),
    );
  }

  /// Mock mode (server has no Chapa key): a stand-in for Chapa's page so the
  /// whole flow can be tested and demonstrated without real money.
  Widget _mockCheckout() => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Test mode', style: T.eyebrow(color: C.accent)),
        const SizedBox(height: 8),
        Text('Simulate the Chapa payment', style: T.display(30)),
        const SizedBox(height: 10),
        Text('The server is running without a Chapa key. Choose what Chapa would answer.', style: T.body(16, color: C.muted)),
        const Spacer(),
        BusyButton(
          label: 'Payment succeeds',
          color: C.green,
          onPressed: () async {
            await api.post('/payments/mock/${Uri.encodeComponent(widget.orderRef)}', {'outcome': 'success'});
            _finish(true);
          },
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: () async {
            try {
              await api.post('/payments/mock/${Uri.encodeComponent(widget.orderRef)}', {'outcome': 'failed'});
            } catch (e) {
              if (mounted) toast(context, e);
            }
            _finish(true);
          },
          child: const Text('Payment fails'),
        ),
      ],
    ),
  );
}
