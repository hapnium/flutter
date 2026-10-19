import 'package:flutter/material.dart';
import 'package:hapnium/hapnium.dart';

/// {@template heartbeat}
/// A widget which adds a heartbeat effect to its contents.
/// 
/// {@endtemplate}
class HeartBeating extends StatefulWidget {
  /// The item to apply the heartbeat effect to.
  final Widget? child;

  /// The number of beats per minutes. Defaults to 70.
  final Integer beatsPerMinute;

  /// {@macro heartbeat}
  HeartBeating({super.key, this.child, this.beatsPerMinute = 70}) {
    assert(beatsPerMinute > 0, 'beatsPerMinute must be greater than 0.');
  }

  @override
  State<StatefulWidget> createState() {
    return _HeartBeatingState();
  }
}

class _HeartBeatingState extends State<HeartBeating> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation _beatForward, _beatBackward;

  @override
  void initState() {
    super.initState();

    // When it comes to calculating the beats per minute. 60000 milliseconds which make up a minute is divided by the number of beatsPerMinute. At the time of this writing it approximately produces the desired effect. It is quite possible that this division might result in a negative number or 0, in that case a default beating of 70bps (857 milliseconds) is applied.
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (60000 ~/ widget.beatsPerMinute).isGreaterThan(0) ? 60000 ~/ widget.beatsPerMinute : 857),
    )..addListener(() {
      setState(() {});
    });

    // Equivalent to zooming in the child at the specified interval.
    _beatForward = Tween(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.30,
          0.65,
          curve: Curves.easeIn,
        ),
      ),
    );

    // Equivalent to zooming out the child at the specified interval.
    _beatBackward = Tween(begin: 1.0, end: 0.8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.65,
          1.00,
          curve: Curves.easeIn,
        ),
      ),
    );

    // Since a heartbeat, so repeats infinitely.
    // _controller.repeat().orCancel;          <---- replaced this with code below
    _controller.forward();
    _controller.repeat();
  }

  @override
  void didUpdateWidget(HeartBeating oldWidget) {
    _controller.reset();
    // _controller.repeat().orCancel;          <---- replaced this with code below
    _controller.forward();
    _controller.repeat();
    
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // First scale up, then scale down.
    return Transform.scale(
      scale: _beatForward.value,
      child: Transform.scale(
        scale: _beatBackward.value,
        child: widget.child,
      ),
    );
  }
}