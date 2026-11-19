import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../api/api_client.dart';
import '../../theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import 'organizer_shell.dart';

/// UC07 - Scan tickets at the door (design: mobile-19 valid, mobile-20 used).
///
/// The camera reads the QR text and sends it to POST /checkin/scan. All the
/// security is on the server: it decrypts the AES payload, checks it matches
/// the stored ticket, and locks the ticket row (SELECT ... FOR UPDATE) so two
/// door phones scanning the same code at once can't both admit it (BR-08).
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

/// What the result panel shows after a scan.
class _ScanResult {
  final String kind; // valid | used | invalid
  final String title;
  final String message;
  final Map<String, dynamic>? attendee;
  final Map<String, dynamic>? ticket;
  final DateTime? at;
  _ScanResult(this.kind, this.title, this.message, {this.attendee, this.ticket, this.at});
}

class _ScannerScreenState extends State<ScannerScreen> {
  final _camera = MobileScannerController(detectionSpeed: DetectionSpeed.noDuplicates, formats: [BarcodeFormat.qrCode]);
  _ScanResult? _result;
  bool _busy = false;
  int? _checkedIn;
  int? _sold;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  Future<void> _loadCounts() async {
    final e = doorEvent.value;
    if (e == null) return;
    try {
      final res = await api.get('/events/${e.id}/attendance');
      if (mounted) {
        setState(() {
          _checkedIn = (res['checked_in'] as num?)?.toInt();
          _sold = (res['sold'] as num?)?.toInt();
        });
      }
    } catch (_) {}
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.map((b) => b.rawValue).whereType<String>().firstOrNull;
    // Ignore new codes while a result is showing; "Scan next" resumes
    if (code == null || _busy || _result != null) return;
    setState(() => _busy = true);
    try {
      final res = await api.post('/checkin/scan', {'qr_payload': code, if (doorEvent.value != null) 'event_id': doorEvent.value!.id});
      HapticFeedback.mediumImpact();
      final counts = res['counts'];
      setState(() {
        if (counts is Map) {
          _checkedIn = (counts['checked_in'] as num?)?.toInt();
          _sold = (counts['sold'] as num?)?.toInt();
        }
        _result = _ScanResult(
          'valid',
          'Checked in',
          '',
          attendee: Map<String, dynamic>.from(res['attendee']),
          ticket: Map<String, dynamic>.from(res['ticket']),
          at: DateTime.tryParse('${res['checked_in_at']}'),
        );
      });
    } on ApiException catch (e) {
      HapticFeedback.heavyImpact();
      final d = e.details;
      setState(() {
        if (d['result'] == 'already_used') {
          final at = DateTime.tryParse('${d['checked_in_at']}');
          _result = _ScanResult(
            'used',
            'Already checked in',
            "This ticket was used${at != null ? ' at ${Fmt.time(at)}' : ''}. Don't admit a second person on the same code.",
            attendee: d['attendee'] is Map ? Map<String, dynamic>.from(d['attendee']) : null,
            ticket: d['ticket'] is Map ? Map<String, dynamic>.from(d['ticket']) : null,
          );
        } else {
          final title = d['result'] == 'wrong_event'
              ? 'Wrong event'
              : d['result'] == 'not_open'
              ? 'Not open yet'
              : 'Invalid ticket';
          _result = _ScanResult('invalid', title, e.message);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _next() => setState(() => _result = null);

  Color get _frameColor => switch (_result?.kind) {
    'valid' => const Color(0xFF5DBB8F),
    'used' || 'invalid' => const Color(0xFFE8754F),
    _ => C.bg,
  };

  @override
  Widget build(BuildContext context) {
    final event = doorEvent.value;
    return Scaffold(
      backgroundColor: const Color(0xFF15120F),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _camera,
              onDetect: _onDetect,
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                        ? 'Camera permission is needed to scan tickets. Allow it in your phone settings.'
                        : 'The camera could not start (${error.errorCode.name}).',
                    textAlign: TextAlign.center,
                    style: T.body(16, color: C.bg),
                  ),
                ),
              ),
            ),
          ),
          // Viewfinder corners
          Center(
            child: SizedBox(width: 260, height: 260, child: CustomPaint(painter: _CornersPainter(_frameColor))),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleIconButton(
                        icon: Icons.close,
                        tooltip: 'Close scanner',
                        bg: Colors.black54,
                        fg: C.bg,
                        onPressed: () => organizerTab.value = OrganizerTabs.events,
                      ),
                      const Spacer(),
                      if (_checkedIn != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(99)),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '$_checkedIn',
                                  style: T.body(17, color: C.bg, weight: FontWeight.w700),
                                ),
                                TextSpan(
                                  text: ' / ${_sold ?? '-'} in',
                                  style: T.body(17, color: C.darkMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const Spacer(),
                      CircleIconButton(
                        icon: Icons.flashlight_on_outlined,
                        tooltip: 'Torch',
                        bg: Colors.black54,
                        fg: C.bg,
                        onPressed: () => _camera.toggleTorch(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event != null ? 'Scanning for ${event.title}' : 'Scanning for all your events',
                    textAlign: TextAlign.center,
                    style: T.body(14, color: C.darkMuted),
                  ),
                ],
              ),
            ),
          ),
          if (_busy) const Center(child: CircularProgressIndicator(color: C.gold)),
          if (_result != null) Align(alignment: Alignment.bottomCenter, child: _resultPanel(_result!)),
        ],
      ),
    );
  }

  Widget _resultPanel(_ScanResult r) {
    final bg = switch (r.kind) {
      'valid' => C.green,
      'used' => const Color(0xFF8F2A10),
      _ => const Color(0xFF6B2412),
    };
    final card = switch (r.kind) {
      'valid' => const Color(0xFF2B6A54),
      _ => const Color(0xFFA33A1E),
    };
    final a = r.attendee;
    final t = r.ticket;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(22, 24, 22, 20 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: C.bg,
                child: Icon(r.kind == 'valid' ? Icons.check : Icons.close, color: bg, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(r.title, style: T.display(30, color: C.bg)),
              ),
            ],
          ),
          if (r.message.isNotEmpty) ...[const SizedBox(height: 12), Text(r.message, style: T.body(16, color: C.bg))],
          if (a != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  Avatar(name: '${a['full_name']}', photo: a['profile_photo'], size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${a['full_name']}',
                          style: T.body(19, color: C.bg, weight: FontWeight.w700),
                        ),
                        Text(
                          [a['job_title'], a['company']].where((s) => s != null && '$s'.isNotEmpty).join(' · '),
                          style: T.body(14, color: C.bg.withValues(alpha: 0.85)),
                        ),
                      ],
                    ),
                  ),
                  if (t != null) Pill('${t['type_name']}', bg: C.gold, fg: C.ink),
                ],
              ),
            ),
          ],
          if (t != null) ...[
            const SizedBox(height: 12),
            Text(
              '${t['ticket_code']}${r.at != null ? ' · ${Fmt.time(r.at!)}' : ''}',
              style: T.mono(14, color: C.bg.withValues(alpha: 0.85), weight: FontWeight.w500),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: C.bg, foregroundColor: C.ink),
            onPressed: _next,
            child: const Text('Scan next'),
          ),
        ],
      ),
    );
  }
}

/// Draws the four rounded corners of the viewfinder.
class _CornersPainter extends CustomPainter {
  final Color color;
  _CornersPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    const len = 48.0, r = 16.0;
    final w = size.width, h = size.height;
    void corner(double x, double y, double sx, double sy) {
      canvas.drawPath(
        Path()
          ..moveTo(x, y + sy * len)
          ..lineTo(x, y + sy * r)
          ..quadraticBezierTo(x, y, x + sx * r, y)
          ..lineTo(x + sx * len, y),
        p,
      );
    }

    corner(0, 0, 1, 1);
    corner(w, 0, -1, 1);
    corner(0, h, 1, -1);
    corner(w, h, -1, -1);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter old) => old.color != color;
}
