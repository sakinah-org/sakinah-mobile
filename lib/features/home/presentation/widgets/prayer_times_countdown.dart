import 'dart:async';

import 'package:flutter/material.dart';

/// Ticking `h:mm:ss` countdown to [target], recomputed once per second.
/// Isolated from the rest of the prayer card so only this subtree rebuilds
/// each tick (specs/002-home-page/research.md §8).
class PrayerTimesCountdown extends StatefulWidget {
  const PrayerTimesCountdown({
    super.key,
    required this.target,
    required this.style,
  });

  final DateTime target;
  final TextStyle style;

  @override
  State<PrayerTimesCountdown> createState() => _PrayerTimesCountdownState();
}

class _PrayerTimesCountdownState extends State<PrayerTimesCountdown> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = _computeRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = _computeRemaining());
    });
  }

  @override
  void didUpdateWidget(covariant PrayerTimesCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      setState(() => _remaining = _computeRemaining());
    }
  }

  Duration _computeRemaining() {
    final diff = widget.target.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }

  String _format(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    final seconds = d.inSeconds % 60;
    String two(int n) => n.toString().padLeft(2, '0');
    return '$hours:${two(minutes)}:${two(seconds)}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Text(
        _format(_remaining),
        key: ValueKey(_remaining.inSeconds),
        style: widget.style,
      ),
    );
  }
}
