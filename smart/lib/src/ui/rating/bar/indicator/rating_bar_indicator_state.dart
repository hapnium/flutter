// ignore_for_file: deprecated_member_use

part of 'rating_bar_indicator.dart';

class _RatingBarIndicatorState extends State<RatingBarIndicator> {
  double _ratingFraction = 0.0;
  int _ratingNumber = 0;
  bool _isRTL = false;

  @override
  void initState() {
    super.initState();
    _ratingNumber = widget.rating.truncate() + 1;
    _ratingFraction = widget.rating - _ratingNumber + 1;
  }

  @override
  Widget build(BuildContext context) {
    TextDirection textDirection = widget.textDirection ?? Directionality.of(context);
    _isRTL = textDirection == TextDirection.rtl;
    _ratingNumber = widget.rating.truncate() + 1;
    _ratingFraction = widget.rating - _ratingNumber + 1;

    return SingleChildScrollView(
      scrollDirection: widget.direction,
      physics: widget.physics,
      child: widget.direction == Axis.horizontal ? Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: textDirection,
        children: _children,
      ) : Column(
        mainAxisSize: MainAxisSize.min,
        textDirection: textDirection,
        children: _children,
      ),
    );
  }

  List<Widget> get _children {
    return List.generate(widget.itemCount, (int index) {
      if (widget.textDirection != null) {
        if (widget.textDirection == TextDirection.rtl && Directionality.of(context) != TextDirection.rtl) {
          return Transform(
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            alignment: Alignment.center,
            transformHitTests: false,
            child: _buildItems(index),
          );
        }
      }

      return _buildItems(index);
    });
  }

  Widget _buildItems(int index) {
    return Padding(
      padding: widget.itemPadding,
      child: SizedBox(
        width: widget.itemSize,
        height: widget.itemSize,
        child: Stack(
          fit: StackFit.expand,
          children: [
            FittedBox(
              fit: BoxFit.contain,
              child: index + 1 < _ratingNumber ? widget.itemBuilder(context, index) : ColorFiltered(
                colorFilter: ColorFilter.mode(
                  widget.unratedColor ?? Theme.of(context).disabledColor,
                  BlendMode.srcIn,
                ),
                child: widget.itemBuilder(context, index),
              ),
            ),
            if (index + 1 == _ratingNumber) ...[
              if (_isRTL) ...[
                FittedBox(
                  fit: BoxFit.contain,
                  child: ClipRect(
                    clipper: _IndicatorClipper(
                      ratingFraction: _ratingFraction,
                      rtlMode: _isRTL,
                    ),
                    child: widget.itemBuilder(context, index),
                  ),
                )
              ] else ...[
                FittedBox(
                  fit: BoxFit.contain,
                  child: ClipRect(
                    clipper: _IndicatorClipper(
                      ratingFraction: _ratingFraction,
                    ),
                    child: widget.itemBuilder(context, index),
                  ),
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }
}

class _IndicatorClipper extends CustomClipper<Rect> {
  final double ratingFraction;
  final bool rtlMode;

  _IndicatorClipper({
    required this.ratingFraction,
    this.rtlMode = false,
  });

  @override
  Rect getClip(Size size) {
    return rtlMode ? Rect.fromLTRB(
      size.width - size.width * ratingFraction,
      0.0,
      size.width,
      size.height,
    ) : Rect.fromLTRB(
      0.0,
      0.0,
      size.width * ratingFraction,
      size.height,
    );
  }

  @override
  bool shouldReclip(_IndicatorClipper oldClipper) {
    return ratingFraction != oldClipper.ratingFraction || rtlMode != oldClipper.rtlMode;
  }
}