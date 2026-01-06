import 'package:flutter/material.dart';
import 'package:smart/enums.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/extensions.dart';

import 'pin/pin.dart';

/// A customizable OTP input field widget.
/// 
/// Allows users to enter OTP codes with various styles, such as boxed, filled, or underlined.
/// Users can override default values for sizes, colors, and other configurations.
/// 
/// Example usage:
/// ```dart
/// OtpField(
///   controller: TextEditingController(),
///   focusNode: FocusNode(),
///   onChanged: (code) => print("OTP Changed: \$code"),
///   onCompleted: (code) => print("OTP Completed: \$code"),
///   type: OtpFieldType.box,
/// )
/// ```
class OtpField extends StatelessWidget {
  /// Controller for the OTP input field.
  final TextEditingController? controller;

  /// Focus node for managing input focus.
  final FocusNode? focusNode;

  /// Callback triggered when the OTP field changes.
  final Consumer<String>? onChanged;

  /// Callback triggered when OTP input is completed.
  final Consumer<String>? onCompleted;

  /// Callback triggered when an OTP is copied.
  final Consumer<String>? onCopied;

  /// Callback triggered when an OTP is submitted.
  final Consumer<String>? onSubmitted;

  /// Optional SMS retriever service.
  final SmsRetriever? smsRetriever;

  /// Configuration for the default pin style.
  final PinItemConfig? defaultPinConfig;

  /// Configuration for the focused pin style.
  final PinItemConfig? focusedPinConfig;

  /// Configuration for the submitted pin style.
  final PinItemConfig? submittedPinConfig;

  /// Configuration for the following pin style.
  final PinItemConfig? followingPinConfig;

  /// Configuration for the disabled pin style.
  final PinItemConfig? disabledPinConfig;

  /// Configuration for the error pin style.
  final PinItemConfig? errorPinConfig;

  /// Type of OTP field (e.g., filled, box, bottom underline).
  final OtpFieldType type;

  /// Height of each OTP input box.
  final double? height;

  /// Width of each OTP input box.
  final double? width;

  /// Font size of OTP text.
  final double? fontSize;

  /// Border radius for OTP boxes.
  final double? borderRadius;

  /// Border radius when focused.
  final double? focusedBorderRadius;

  /// Width of the focused border.
  final double? focusedWidth;

  /// Primary color for the OTP field.
  final Color? primaryColor;

  /// Background surface color.
  final Color? surfaceColor;

  /// Border color when focused.
  final Color? focusedBorderColor;

  /// Text color inside OTP fields.
  final Color? textColor;

  /// Whether to show the cursor.
  final bool showCursor;

  /// Custom widget for the cursor.
  final Widget? cursor;

  /// Custom widget for pre-filled elements.
  final Widget? preFilled;

  /// Custom builder function for pin elements.
  final Widget Function(Pin pin, BuildContext context)? builder;

  /// Length of the OTP.
  final int length;

  /// Default constructor for OtpField.
  /// 
  /// Creates a customizable OTP input field that can be modified using optional parameters.
  /// This constructor allows different types like [OtpFieldType.filled], [OtpFieldType.box], and [OtpFieldType.bottom].
  const OtpField({
    super.key,
    this.controller,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.height,
    this.showCursor = true,
    this.onCopied,
    this.onSubmitted,
    this.smsRetriever,
    this.defaultPinConfig,
    this.focusedPinConfig,
    this.submittedPinConfig,
    this.followingPinConfig,
    this.disabledPinConfig,
    this.errorPinConfig,
    required this.type,
    this.width,
    this.fontSize,
    this.borderRadius,
    this.focusedBorderRadius,
    this.focusedWidth,
    this.primaryColor,
    this.surfaceColor,
    this.focusedBorderColor,
    this.textColor,
    this.cursor,
    this.preFilled,
    this.builder
  });

  /// Creates an OTP field with a filled background style.
  /// 
  /// This constructor applies a solid background to the OTP input fields.
  const OtpField.filled({
    super.key,
    this.controller,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.height,
    this.showCursor = true,
    this.onCopied,
    this.onSubmitted,
    this.smsRetriever,
    this.defaultPinConfig,
    this.focusedPinConfig,
    this.submittedPinConfig,
    this.followingPinConfig,
    this.disabledPinConfig,
    this.errorPinConfig,
    this.width,
    this.fontSize,
    this.borderRadius,
    this.focusedBorderRadius,
    this.focusedWidth,
    this.primaryColor,
    this.surfaceColor,
    this.focusedBorderColor,
    this.textColor,
    this.cursor,
    this.preFilled,
    this.builder
  }) : type = OtpFieldType.filled;

  /// Creates an OTP field with a boxed style.
  /// 
  /// This constructor applies bordered boxes around the OTP input fields.
  const OtpField.box({
    super.key,
    this.controller,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.height,
    this.showCursor = true,
    this.onCopied,
    this.onSubmitted,
    this.smsRetriever,
    this.defaultPinConfig,
    this.focusedPinConfig,
    this.submittedPinConfig,
    this.followingPinConfig,
    this.disabledPinConfig,
    this.errorPinConfig,
    this.width,
    this.fontSize,
    this.borderRadius,
    this.focusedBorderRadius,
    this.focusedWidth,
    this.primaryColor,
    this.surfaceColor,
    this.focusedBorderColor,
    this.textColor,
    this.cursor,
    this.preFilled,
    this.builder
  }) : type = OtpFieldType.box;

  /// Creates an OTP field with a bottom underline style.
  /// 
  /// This constructor displays an underline beneath each OTP digit.
  const OtpField.bottom({
    super.key,
    this.controller,
    this.focusNode,
    this.onCompleted,
    this.onChanged,
    this.length = 6,
    this.height,
    this.showCursor = true,
    this.onCopied,
    this.onSubmitted,
    this.smsRetriever,
    this.defaultPinConfig,
    this.focusedPinConfig,
    this.submittedPinConfig,
    this.followingPinConfig,
    this.disabledPinConfig,
    this.errorPinConfig,
    this.width,
    this.fontSize,
    this.borderRadius,
    this.focusedBorderRadius,
    this.focusedWidth,
    this.primaryColor,
    this.surfaceColor,
    this.focusedBorderColor,
    this.textColor,
    this.cursor,
    this.preFilled,
    this.builder
  }) : type = OtpFieldType.bottom;

  @override
  Widget build(BuildContext context) {
    final double borderRadius = this.borderRadius ?? 10;

    final config = PinItemConfig(
      width: width ?? 60,
      height: height ?? 45,
      textStyle: TextStyle(
        fontSize: fontSize ?? 20,
        color: textColor ?? Theme.of(context).primaryColor
      ),
    );

    Pin getPin() => Pin(
      length: length,
      controller: controller,
      focusNode: focusNode,
      defaultPinConfig: defaultPinConfig ?? config,
      showCursor: showCursor,
      focusedPinConfig: focusedPinConfig,
      submittedPinConfig: submittedPinConfig,
      followingPinConfig: followingPinConfig,
      disabledPinConfig: disabledPinConfig,
      errorPinConfig: errorPinConfig,
      onCompleted: onCompleted,
      onClipboardFound: onCopied,
      onSubmitted: onSubmitted,
      onChanged: onChanged,
    );

    if(builder.isNotNull) {
      return builder!(getPin(), context);
    } else if(type.isFilled) {
      return _buildFilled(getPin(), context, config, borderRadius);
    } else if(type.isBox) {
      return _buildBox(getPin(), context, config, borderRadius);
    } else {
      return _buildBottom(getPin(), context, config, borderRadius);
    }
  }

  Pin _buildFilled(Pin pin, BuildContext context, PinItemConfig config, double borderRadius) {
    Pin pin0 = pin;

    if(defaultPinConfig.isNull) {
      pin0 = pin0.copyWith(defaultPinConfig: config.copyWith(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: surfaceColor ?? Theme.of(context).colorScheme.surface
        ),
      ));
    }

    if(focusedPinConfig.isNull) {
      pin0 = pin0.copyWith(focusedPinConfig: config.copyWith(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(focusedBorderRadius ?? borderRadius),
          border: Border.all(
            color: focusedBorderColor ?? primaryColor ?? Theme.of(context).primaryColor,
            width: focusedWidth ?? 2
          )
        ),
      ));
    }

    return pin0;
  }

  Pin _buildBox(Pin pin, BuildContext context, PinItemConfig config, double borderRadius) {
    Pin pin0 = pin;

    if(defaultPinConfig.isNull) {
      pin0 = pin0.copyWith(defaultPinConfig: config.copyWith(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: primaryColor ?? Theme.of(context).primaryColor)
        ),
      ));
    }

    if(focusedPinConfig.isNull) {
      pin0 = pin0.copyWith(focusedPinConfig: config.copyWith(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(focusedBorderRadius ?? borderRadius),
          border: Border.all(
            color: focusedBorderColor ?? primaryColor ?? Theme.of(context).primaryColor,
            width: focusedWidth ?? 2
          )
        ),
      ));
    }

    return pin0;
  }

  Widget _buildBottom(Pin pin, BuildContext context, PinItemConfig config, double borderRadius) {
    final defaultCursor = cursor ?? Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );

    final defaultPrefilled = preFilled ?? Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 56,
          height: 3,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );

    return pin.copyWith(
      cursor: defaultCursor,
      preFilledWidget: defaultPrefilled,
    );
  }
}