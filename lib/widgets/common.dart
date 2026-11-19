import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../theme.dart';
import '../utils/format.dart';

/// The green-and-gold zigzag strip ("tibeb" border) that runs along banners,
/// tickets and live cards in the design.
class TibebStrip extends StatelessWidget {
  final double height;
  const TibebStrip({super.key, this.height = 12});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(painter: _TibebPainter()),
  );
}

class _TibebPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.green);
    final gold = Paint()..color = C.gold;
    final w = size.height; // one tooth per square
    final path = Path()..moveTo(0, size.height);
    for (double x = 0; x < size.width + w; x += w) {
      path
        ..lineTo(x + w / 2, size.height * 0.35)
        ..lineTo(x + w, size.height);
    }
    path
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    canvas.drawPath(path, gold);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Round avatar: the profile photo when there is one, otherwise coloured initials.
class Avatar extends StatelessWidget {
  final String name;
  final String? photo;
  final double size;
  final bool square;
  const Avatar({super.key, required this.name, this.photo, this.size = 44, this.square = false});

  static const _colors = [C.accent, C.green, C.gold, C.ink2];

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.mediaUrl(photo);
    final bg = _colors[name.codeUnits.fold<int>(0, (a, b) => a + b) % _colors.length];
    final radius = BorderRadius.circular(square ? size * 0.28 : size);
    return ClipRRect(
      borderRadius: radius,
      child: Container(
        width: size,
        height: size,
        color: bg,
        alignment: Alignment.center,
        child: url != null ? Image.network(url, width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, _, _) => _letters(bg)) : _letters(bg),
      ),
    );
  }

  Widget _letters(Color bg) => Text(
    Fmt.initials(name),
    style: T.body(size * 0.36, color: bg == C.gold ? C.ink : Colors.white, weight: FontWeight.w700),
  );
}

/// The coloured date block on event cards ("OCT / 30").
class DateTile extends StatelessWidget {
  final DateTime date;
  final int index;
  final double size;
  const DateTile({super.key, required this.date, this.index = 0, this.size = 72});

  @override
  Widget build(BuildContext context) {
    const palette = [C.green, C.gold, C.ink, C.accent];
    final bg = palette[index % palette.length];
    final fg = bg == C.gold ? C.ink : Colors.white;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            Fmt.month(date),
            style: T.mono(12, color: fg, weight: FontWeight.w700),
          ),
          Text(Fmt.day(date), style: T.display(size * 0.4, color: fg)),
        ],
      ),
    );
  }
}

/// Small rounded label ("Published", "VIP", "Few left").
class Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const Pill(this.text, {super.key, this.bg = C.fill, this.fg = C.ink});

  factory Pill.status(String status) {
    switch (status) {
      case 'active':
        return const Pill('Live now', bg: C.accentSoft, fg: C.accent);
      case 'published':
        return const Pill('Published', bg: C.greenSoft, fg: C.greenInk);
      case 'completed':
        return const Pill('Ended');
      case 'cancelled':
        return const Pill('Cancelled', bg: C.accentSoft, fg: C.danger);
      default:
        return const Pill('Draft');
    }
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
    child: Text(
      text,
      style: T.body(13, color: fg, weight: FontWeight.w700),
    ),
  );
}

/// A cream card with the thin border used everywhere in the design.
class SurfaceCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(18), this.onTap, this.color = C.surface});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(18);
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: color == C.surface ? const BorderSide(color: C.line) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const SectionTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 12),
    child: Row(
      children: [
        Expanded(child: Text(text, style: T.display(22))),
        if (trailing != null) trailing!,
      ],
    ),
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(color: C.fill, shape: BoxShape.circle),
          child: Icon(icon, color: C.muted, size: 30),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: T.body(18, weight: FontWeight.w700),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: T.body(15, color: C.muted),
          ),
        ],
        if (action != null) ...[const SizedBox(height: 18), action!],
      ],
    ),
  );
}

/// Loads data with [load] and shows a spinner, an error with "Try again", or
/// the result built by [builder]. Pull-to-refresh is supported through [reload].
/// Almost every screen is built on this, so loading/error handling is the same
/// everywhere.
class AsyncView<D> extends StatefulWidget {
  final Future<D> Function() load;
  final Widget Function(BuildContext context, D data, Future<void> Function() reload) builder;
  const AsyncView({super.key, required this.load, required this.builder});

  @override
  State<AsyncView<D>> createState() => AsyncViewState<D>();
}

class AsyncViewState<D> extends State<AsyncView<D>> {
  D? _data;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    reload();
  }

  Future<void> reload() async {
    if (_data == null) setState(() => _loading = true);
    try {
      final d = await widget.load();
      if (!mounted) return;
      setState(() {
        _data = d;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _data == null) return const Center(child: CircularProgressIndicator(color: C.accent));
    if (_data == null) return ErrorView(error: _error, onRetry: reload);
    return widget.builder(context, _data as D, reload);
  }
}

class ErrorView extends StatelessWidget {
  final Object? error;
  final VoidCallback onRetry;
  const ErrorView({super.key, this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: EmptyState(
      icon: Icons.cloud_off_outlined,
      title: 'Could not load this',
      message: error is ApiException ? '$error' : 'Something went wrong. Please try again.',
      action: OutlinedButton(
        onPressed: onRetry,
        style: OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
        child: const Text('Try again'),
      ),
    ),
  );
}

/// Shows an error (or any message) at the bottom of the screen.
void toast(BuildContext context, Object message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text('$message')));
}

/// A filled button that shows a spinner while [onPressed] runs and reports
/// API errors as a toast. Prevents double taps (e.g. paying twice).
class BusyButton extends StatefulWidget {
  final String label;
  final Future<void> Function()? onPressed;
  final IconData? icon;
  final Color? color;
  const BusyButton({super.key, required this.label, required this.onPressed, this.icon, this.color});

  @override
  State<BusyButton> createState() => _BusyButtonState();
}

class _BusyButtonState extends State<BusyButton> {
  bool _busy = false;

  Future<void> _run() async {
    setState(() => _busy = true);
    try {
      await widget.onPressed!();
    } catch (e) {
      if (mounted) toast(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _busy
        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[Icon(widget.icon, size: 20), const SizedBox(width: 8)],
              Flexible(child: Text(widget.label, overflow: TextOverflow.ellipsis)),
            ],
          );
    return FilledButton(
      style: widget.color != null ? FilledButton.styleFrom(backgroundColor: widget.color) : null,
      onPressed: widget.onPressed == null || _busy ? null : _run,
      child: child,
    );
  }
}

/// Round icon button on a light circle (back / share / bookmark on banners).
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final Color bg;
  final Color fg;
  const CircleIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.bg = C.surface, this.fg = C.ink});

  @override
  Widget build(BuildContext context) => Material(
    color: bg,
    shape: const CircleBorder(),
    child: IconButton(
      icon: Icon(icon, color: fg),
      tooltip: tooltip,
      onPressed: onPressed,
    ),
  );
}

/// Chips list for skills / interests / goals.
class TagWrap extends StatelessWidget {
  final List<String> tags;
  final Color bg;
  final Color fg;
  const TagWrap(this.tags, {super.key, this.bg = C.fill, this.fg = C.ink});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [for (final t in tags) Pill(t, bg: bg, fg: fg)],
  );
}
