import 'package:flutter/material.dart';

import '../api/models.dart';
import '../config.dart';
import '../theme.dart';
import '../utils/format.dart';
import 'common.dart';

/// The banner block at the top of a featured card / event detail: the event's
/// uploaded banner image, or a terracotta block with the title (design default).
class EventBanner extends StatelessWidget {
  final EventItem event;
  final double height;
  final bool showTitle;
  final Widget? overlay;
  const EventBanner({super.key, required this.event, this.height = 180, this.showTitle = true, this.overlay});

  @override
  Widget build(BuildContext context) {
    final url = AppConfig.mediaUrl(event.banner);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: C.accent),
          if (url != null) Image.network(url, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
          if (url != null)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x22000000), Color(0xAA000000)]),
              ),
            ),
          if (showTitle)
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Text(
                event.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: T.display(height > 200 ? 40 : 34, color: Colors.white),
              ),
            ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

/// Big "Picked for you" card (design: mobile-05).
class FeaturedEventCard extends StatelessWidget {
  final EventItem event;
  final VoidCallback onTap;
  const FeaturedEventCard({super.key, required this.event, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EventBanner(
            event: event,
            overlay: Stack(
              children: [
                Positioned(
                  left: 18,
                  top: 16,
                  child: Text((event.category ?? '').toUpperCase(), style: T.eyebrow(color: Colors.white)),
                ),
                Positioned(
                  right: 14,
                  top: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: C.surface, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(Fmt.month(event.start), style: T.mono(11, weight: FontWeight.w700)),
                        Text(Fmt.day(event.start), style: T.display(22)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const TibebStrip(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(event.title, style: T.body(19, weight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      Fmt.priceFrom(event.minPrice, event.maxPrice),
                      style: T.body(16, color: event.maxPrice == 0 ? C.green : C.accent, weight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('${Fmt.shortDate(event.start)}, ${Fmt.time(event.start)} · ${event.place}', style: T.body(15, color: C.muted)),
                if (event.reason != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.reason!,
                    style: T.body(15, color: C.green, weight: FontWeight.w700),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact list row with the coloured date tile ("Coming up").
class EventRowCard extends StatelessWidget {
  final EventItem event;
  final int index;
  final VoidCallback onTap;
  final Widget? trailing;
  const EventRowCard({super.key, required this.event, required this.onTap, this.index = 0, this.trailing});

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          DateTile(date: event.start, index: index),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (event.isLive)
                  Text('● LIVE NOW', style: T.eyebrow(color: C.accent))
                else if (event.category != null)
                  Text(event.category!.toUpperCase(), style: T.eyebrow()),
                const SizedBox(height: 2),
                Text(
                  event.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(17, weight: FontWeight.w700),
                ),
                Text(
                  '${Fmt.time(event.start)} · ${event.place}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: T.body(14, color: C.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing ??
              Text(
                Fmt.priceFrom(event.minPrice, event.maxPrice),
                textAlign: TextAlign.right,
                style: T.body(15, color: event.maxPrice == 0 ? C.green : C.accent, weight: FontWeight.w700),
              ),
        ],
      ),
    );
  }
}
