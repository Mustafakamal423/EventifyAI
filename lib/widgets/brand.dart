import 'package:flutter/material.dart';

import '../theme.dart';

/// The Eventify AI logo: a diamond made of four coloured squares + wordmark.
class BrandMark extends StatelessWidget {
  final double size;
  final bool onDark;
  const BrandMark({super.key, this.size = 22, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final gap = size * 0.1;
    final cell = (size - gap) / 2;
    Widget sq(Color c) => Container(width: cell, height: cell, color: c);
    final diamond = Transform.rotate(
      angle: 0.785398, // 45 degrees
      child: SizedBox(
        width: size,
        height: size,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [sq(C.accent), sq(C.gold)]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [sq(C.green), sq(onDark ? C.bg : C.ink)]),
          ],
        ),
      ),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        diamond,
        SizedBox(width: size * 0.55),
        Text('Eventify', style: T.display(size * 1.05, color: onDark ? C.bg : C.ink)),
        Text(' AI', style: T.display(size * 1.05, color: C.gold)),
      ],
    );
  }
}
