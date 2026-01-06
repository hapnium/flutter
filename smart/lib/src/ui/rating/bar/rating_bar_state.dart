// ignore_for_file: deprecated_member_use

part of 'rating_bar.dart';

class _RatingBarState extends State<RatingBar> {
  double _rating = 0.0;
  bool _isRTL = false;
  double iconRating = 0.0;

  late double _minRating, _maxRating;
  late final ValueNotifier<bool> _glow;

  @override
  void initState() {
    super.initState();
    _glow = ValueNotifier(false);
    _minRating = widget.minRating;
    _maxRating = widget.maxRating ?? widget.itemCount.toDouble();
    _rating = widget.initialRating;
  }

  @override
  void didUpdateWidget(RatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialRating != widget.initialRating) {
      _rating = widget.initialRating;
    }
    _minRating = widget.minRating;
    _maxRating = widget.maxRating ?? widget.itemCount.toDouble();
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textDirection = widget.textDirection ?? Directionality.of(context);
    _isRTL = textDirection == TextDirection.rtl;
    iconRating = 0.0;

    return Material(
      color: Colors.transparent,
      child: Wrap(
        alignment: WrapAlignment.start,
        textDirection: textDirection,
        direction: widget.direction,
        children: widget.itemCount.listGenerator.map((int index) => _buildRating(context, index)).toList(),
      ),
    );
  }

  Widget _buildRating(BuildContext context, int index) {
    RatingBarWidget? child = widget._child;
    Widget? item = widget._itemBuilder.isNotNull ? widget._itemBuilder!(context, index) : null;
    double ratingOffset = widget.allowHalfRating ? 0.5 : 1.0;

    Widget child0;

    if (index >= _rating) {
      child0 = _NoRatingWidget(
        size: widget.itemSize,
        child: child?.empty ?? item!,
        enableMask: child == null,
        unratedColor: widget.unratedColor ?? Theme.of(context).disabledColor,
      );
    } else if (index >= _rating - ratingOffset && widget.allowHalfRating) {
      if (child?.half == null) {
        child0 = _HalfRatingWidget(
          size: widget.itemSize,
          child: item!,
          enableMask: child == null,
          rtlMode: _isRTL,
          unratedColor: widget.unratedColor ?? Theme.of(context).disabledColor,
        );
      } else {
        child0 = SizedBox(
          width: widget.itemSize,
          height: widget.itemSize,
          child: FittedBox(
            fit: BoxFit.contain,
            child: _isRTL ? Transform(
              transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
              alignment: Alignment.center,
              transformHitTests: false,
              child: child!.half,
            ) : child!.half,
          ),
        );
      }
      iconRating += 0.5;
    } else {
      child0 = SizedBox(
        width: widget.itemSize,
        height: widget.itemSize,
        child: FittedBox(
          fit: BoxFit.contain,
          child: child?.full ?? item,
        ),
      );
      iconRating += 1.0;
    }

    return IgnorePointer(
      ignoring: widget.ignoreGestures,
      child: GestureDetector(
        onTapDown: (TapDownDetails details) {
          double value;
          if (index == 0 && (_rating == 1 || _rating == 0.5)) {
            value = 0;
          } else {
            double tappedPosition = details.localPosition.dx;
            bool tappedOnFirstHalf = tappedPosition <= widget.itemSize / 2;
            value = index + (tappedOnFirstHalf && widget.allowHalfRating ? 0.5 : 1.0);
          }

          value = math.max(value, widget.minRating);
          widget.onRatingUpdate(value);
          _rating = value;
          setState(() {});
        },
        onHorizontalDragStart: _isHorizontal ? _onDragStart : null,
        onHorizontalDragEnd: _isHorizontal ? _onDragEnd : null,
        onHorizontalDragUpdate: _isHorizontal ? _onDragUpdate : null,
        onVerticalDragStart: _isHorizontal ? null : _onDragStart,
        onVerticalDragEnd: _isHorizontal ? null : _onDragEnd,
        onVerticalDragUpdate: _isHorizontal ? null : _onDragUpdate,
        child: Padding(
          padding: widget.itemPadding,
          child: ValueListenableBuilder<bool>(
            valueListenable: _glow,
            builder: (BuildContext context, bool glow, Widget? child) {
              if (glow && widget.glow) {
                Color glowColor = widget.glowColor ?? Theme.of(context).colorScheme.secondary;

                return DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: glowColor.withAlpha(30),
                        blurRadius: 10,
                        spreadRadius: widget.glowRadius,
                      ),
                      BoxShadow(
                        color: glowColor.withAlpha(20),
                        blurRadius: 10,
                        spreadRadius: widget.glowRadius,
                      ),
                    ],
                  ),
                  child: child,
                );
              }
              return child!;
            },
            child: child0,
          ),
        ),
      ),
    );
  }

  bool get _isHorizontal => widget.direction == Axis.horizontal;

  void _onDragUpdate(DragUpdateDetails dragDetails) {
    if (!widget.tapOnlyMode) {
      final box = context.findRenderObject() as RenderBox?;
      if (box == null) return;

      final pos = box.globalToLocal(dragDetails.globalPosition);
      double i;
      if (widget.direction == Axis.horizontal) {
        i = pos.dx / (widget.itemSize + widget.itemPadding.horizontal);
      } else {
        i = pos.dy / (widget.itemSize + widget.itemPadding.vertical);
      }

      var currentRating = widget.allowHalfRating ? i : i.round().toDouble();
      if (currentRating > widget.itemCount) {
        currentRating = widget.itemCount.toDouble();
      }

      if (currentRating < 0) {
        currentRating = 0.0;
      }

      if (_isRTL && widget.direction == Axis.horizontal) {
        currentRating = widget.itemCount - currentRating;
      }

      _rating = currentRating.clamp(_minRating, _maxRating);
      if (widget.updateOnDrag) widget.onRatingUpdate(iconRating);

      setState(() {});
    }
  }

  void _onDragStart(DragStartDetails details) {
    _glow.value = true;
  }

  void _onDragEnd(DragEndDetails details) {
    _glow.value = false;
    widget.onRatingUpdate(iconRating);
    iconRating = 0.0;
  }
}

class _HalfRatingWidget extends StatelessWidget {
  final Widget child;
  final double size;
  final bool enableMask;
  final bool rtlMode;
  final Color unratedColor;

  _HalfRatingWidget({
    required this.size,
    required this.child,
    required this.enableMask,
    required this.rtlMode,
    required this.unratedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: enableMask ? Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.contain,
            child: _NoRatingWidget(
              child: child,
              size: size,
              unratedColor: unratedColor,
              enableMask: enableMask,
            ),
          ),
          FittedBox(
            fit: BoxFit.contain,
            child: ClipRect(
              clipper: _HalfClipper(
                rtlMode: rtlMode,
              ),
              child: child,
            ),
          ),
        ],
      ) : FittedBox(
        child: child,
        fit: BoxFit.contain,
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  final bool rtlMode;
  _HalfClipper({required this.rtlMode});

  @override
  Rect getClip(Size size) => rtlMode ? Rect.fromLTRB(
    size.width / 2,
    0.0,
    size.width,
    size.height,
  ) : Rect.fromLTRB(
    0.0,
    0.0,
    size.width / 2,
    size.height,
  );

  @override
  bool shouldReclip(CustomClipper<Rect> oldClipper) => true;
}

class _NoRatingWidget extends StatelessWidget {
  final double size;
  final Widget child;
  final bool enableMask;
  final Color unratedColor;

  _NoRatingWidget({
    required this.size,
    required this.child,
    required this.enableMask,
    required this.unratedColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: FittedBox(
        fit: BoxFit.contain,
        child: enableMask ? ColorFiltered(
          colorFilter: ColorFilter.mode(
            unratedColor,
            BlendMode.srcIn,
          ),
          child: child,
        ) : child,
      ),
    );
  }
}