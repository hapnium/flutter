import 'dart:math';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:hapnium/hapnium.dart';

part 'pin_state.dart';

part 'enums.dart';

part 'widgets/form_field.dart';

part 'widgets/_pin_item.dart';

part 'models/pin_item_config.dart';

part 'models/pin_item.dart';

part 'services/sms_retriever.dart';

part 'services/constants.dart';

part 'services/mixin.dart';

part 'services/selection_gesture_detector_builder.dart';

part 'extensions.dart';

/// Flutter package to create easily customizable Pin code input field, that your designers can't even draw in Figma 🤭
///
/// ## Features:
/// - Animated Decoration Switching
/// - Form validation
/// - SMS Autofill on iOS
/// - SMS Autofill on Android
/// - Standard Cursor
/// - Custom Cursor
/// - Cursor Animation
/// - Copy From Clipboard
/// - Ready For Custom Keyboard
/// - Standard Paste option
/// - Obscuring Character
/// - Obscuring Widget
/// - Haptic Feedback
/// - Close Keyboard After Completion
/// - Beautiful [Examples](https://github.com/Tkko/Flutter_Pin/tree/master/example/lib/demo)
class Pin extends StatefulWidget {
  /// Creates a PinPut widget
  const Pin({
    this.length = PinConstants._defaultLength,
    this.smsRetriever,
    this.defaultPinConfig,
    this.focusedPinConfig,
    this.submittedPinConfig,
    this.followingPinConfig,
    this.disabledPinConfig,
    this.errorPinConfig,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.onTap,
    this.onLongPress,
    this.onTapOutside,
    this.controller,
    this.focusNode,
    this.preFilledWidget,
    this.separatorBuilder,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.pinContentAlignment = Alignment.center,
    this.animationCurve = Curves.easeIn,
    this.animationDuration = PinConstants._animationDuration,
    this.pinAnimationType = PinAnimationType.scale,
    this.enabled = true,
    this.readOnly = false,
    this.useNativeKeyboard = true,
    this.toolbarEnabled = true,
    this.autofocus = false,
    this.obscureText = false,
    this.showCursor = true,
    this.isCursorAnimationEnabled = true,
    this.enableIMEPersonalizedLearning = false,
    this.enableSuggestions = true,
    this.hapticFeedbackType = PinHapticFeedbackType.disabled,
    this.closeKeyboardWhenCompleted = true,
    this.keyboardType = TextInputType.number,
    this.textCapitalization = TextCapitalization.none,
    this.slideTransitionBeginOffset,
    this.cursor,
    this.keyboardAppearance,
    this.inputFormatters = const [],
    this.textInputAction,
    this.autofillHints = const [
      AutofillHints.oneTimeCode,
    ],
    this.obscuringCharacter = '•',
    this.obscuringWidget,
    this.selectionControls,
    this.restorationId,
    this.onClipboardFound,
    this.onAppPrivateCommand,
    this.mouseCursor,
    this.forceErrorState = false,
    this.errorText,
    this.validator,
    this.errorBuilder,
    this.errorTextStyle,
    this.pinputAutovalidateMode = PinAutovalidateMode.onSubmit,
    this.scrollPadding = const EdgeInsets.all(20),
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    super.key,
  })  : assert(obscuringCharacter.length == 1),
        assert(length > 0),
        assert(textInputAction != TextInputAction.newline, 'Pin is not multiline'),
        _builder = null;

  /// Creates a PinPut widget with custom pin item builder
  /// This gives you full control over the pin item widget
  Pin.builder({
    required PinItemWidgetBuilder builder,
    this.smsRetriever,
    this.length = PinConstants._defaultLength,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.onTap,
    this.onLongPress,
    this.onTapOutside,
    this.controller,
    this.focusNode,
    this.separatorBuilder,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.enabled = true,
    this.readOnly = false,
    this.useNativeKeyboard = true,
    this.toolbarEnabled = true,
    this.autofocus = false,
    this.enableIMEPersonalizedLearning = false,
    this.enableSuggestions = true,
    this.hapticFeedbackType = PinHapticFeedbackType.disabled,
    this.closeKeyboardWhenCompleted = true,
    this.keyboardType = TextInputType.number,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardAppearance,
    this.inputFormatters = const [],
    this.textInputAction,
    this.autofillHints,
    this.selectionControls,
    this.restorationId,
    this.onClipboardFound,
    this.onAppPrivateCommand,
    this.mouseCursor,
    this.forceErrorState = false,
    this.validator,
    this.pinputAutovalidateMode = PinAutovalidateMode.onSubmit,
    this.scrollPadding = const EdgeInsets.all(20),
    this.contextMenuBuilder = _defaultContextMenuBuilder,
    super.key,
  })  : assert(length > 0),
        assert(textInputAction != TextInputAction.newline, 'Pin is not multiline'),
        _builder = _PinItemBuilder(
          itemBuilder: builder,
        ),
        defaultPinConfig = null,
        focusedPinConfig = null,
        submittedPinConfig = null,
        followingPinConfig = null,
        disabledPinConfig = null,
        errorPinConfig = null,
        preFilledWidget = null,
        pinContentAlignment = Alignment.center,
        animationCurve = Curves.easeIn,
        animationDuration = PinConstants._animationDuration,
        pinAnimationType = PinAnimationType.scale,
        obscureText = false,
        showCursor = false,
        isCursorAnimationEnabled = false,
        slideTransitionBeginOffset = null,
        cursor = null,
        obscuringCharacter = '•',
        obscuringWidget = null,
        errorText = null,
        errorBuilder = null,
        errorTextStyle = null;

  Pin copyWith({
    PinItemConfig? defaultPinConfig,
    PinItemConfig? focusedPinConfig,
    PinItemConfig? submittedPinConfig,
    PinItemConfig? followingPinConfig,
    PinItemConfig? disabledPinConfig,
    PinItemConfig? errorPinConfig,
    bool? closeKeyboardWhenCompleted,
    int? length,
    SmsRetriever? smsRetriever,
    ValueChanged<String>? onCompleted,
    ValueChanged<String>? onChanged,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    TextEditingController? controller,
    FocusNode? focusNode,
    Widget? preFilledWidget,
    JustIndexedWidgetBuilder? separatorBuilder,
    CrossAxisAlignment? crossAxisAlignment,
    MainAxisAlignment? mainAxisAlignment,
    AlignmentGeometry? pinContentAlignment,
    Curve? animationCurve,
    Duration? animationDuration,
    PinAnimationType? pinAnimationType,
    Offset? slideTransitionBeginOffset,
    bool? enabled,
    bool? readOnly,
    bool? autofocus,
    bool? useNativeKeyboard,
    bool? toolbarEnabled,
    bool? showCursor,
    bool? isCursorAnimationEnabled,
    bool? enableIMEPersonalizedLearning,
    Widget? cursor,
    Brightness? keyboardAppearance,
    List<TextInputFormatter>? inputFormatters,
    TextInputType? keyboardType,
    String? obscuringCharacter,
    Widget? obscuringWidget,
    bool? obscureText,
    TextCapitalization? textCapitalization,
    TextInputAction? textInputAction,
    Iterable<String>? autofillHints,
    bool? enableSuggestions,
    TextSelectionControls? selectionControls,
    String? restorationId,
    ValueChanged<String>? onClipboardFound,
    PinHapticFeedbackType? hapticFeedbackType,
    AppPrivateCommandCallback? onAppPrivateCommand,
    MouseCursor? mouseCursor,
    bool? forceErrorState,
    String? errorText,
    TextStyle? errorTextStyle,
    PinErrorBuilder? errorBuilder,
    FormFieldValidator<String>? validator,
    PinAutovalidateMode? pinputAutovalidateMode,
    EdgeInsets? scrollPadding,
    EditableTextContextMenuBuilder? contextMenuBuilder,
    TapRegionCallback? onTapOutside,
  }) {
    return Pin(
      length: length ?? this.length,
      smsRetriever: smsRetriever ?? this.smsRetriever,
      defaultPinConfig: defaultPinConfig ?? this.defaultPinConfig,
      focusedPinConfig: focusedPinConfig ?? this.focusedPinConfig,
      submittedPinConfig: submittedPinConfig ?? this.submittedPinConfig,
      followingPinConfig: followingPinConfig ?? this.followingPinConfig,
      disabledPinConfig: disabledPinConfig ?? this.disabledPinConfig,
      errorPinConfig: errorPinConfig ?? this.errorPinConfig,
      onChanged: onChanged ?? this.onChanged,
      onCompleted: onCompleted ?? this.onCompleted,
      onSubmitted: onSubmitted ?? this.onSubmitted,
      onTap: onTap ?? this.onTap,
      onLongPress: onLongPress ?? this.onLongPress,
      onTapOutside: onTapOutside ?? this.onTapOutside,
      controller: controller ?? this.controller,
      focusNode: focusNode ?? this.focusNode,
      preFilledWidget: preFilledWidget ?? this.preFilledWidget,
      separatorBuilder: separatorBuilder ?? this.separatorBuilder,
      mainAxisAlignment: mainAxisAlignment ?? this.mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment ?? this.crossAxisAlignment,
      pinContentAlignment: pinContentAlignment ?? this.pinContentAlignment,
      animationCurve: animationCurve ?? this.animationCurve,
      animationDuration: animationDuration ?? this.animationDuration,
      pinAnimationType: pinAnimationType ?? this.pinAnimationType,
      enabled: enabled ?? this.enabled,
      readOnly: readOnly ?? this.readOnly,
      useNativeKeyboard: useNativeKeyboard ?? this.useNativeKeyboard,
      toolbarEnabled: toolbarEnabled ?? this.toolbarEnabled,
      autofocus: autofocus ?? this.autofocus,
      obscureText: obscureText ?? this.obscureText,
      showCursor: showCursor ?? this.showCursor,
      isCursorAnimationEnabled: isCursorAnimationEnabled ?? this.isCursorAnimationEnabled,
      enableIMEPersonalizedLearning: enableIMEPersonalizedLearning ?? this.enableIMEPersonalizedLearning,
      enableSuggestions: enableSuggestions ?? this.enableSuggestions,
      hapticFeedbackType: hapticFeedbackType ?? this.hapticFeedbackType,
      closeKeyboardWhenCompleted: closeKeyboardWhenCompleted ?? this.closeKeyboardWhenCompleted,
      keyboardType: keyboardType ?? this.keyboardType,
      textCapitalization: textCapitalization ?? this.textCapitalization,
      slideTransitionBeginOffset: slideTransitionBeginOffset ?? this.slideTransitionBeginOffset,
      cursor: cursor ?? this.cursor,
      keyboardAppearance: keyboardAppearance ?? this.keyboardAppearance,
      inputFormatters: inputFormatters ?? this.inputFormatters,
      textInputAction: textInputAction ?? this.textInputAction,
      autofillHints: autofillHints ?? this.autofillHints,
      obscuringCharacter: obscuringCharacter ?? this.obscuringCharacter,
      obscuringWidget: obscuringWidget ?? this.obscuringWidget,
      selectionControls: selectionControls ?? this.selectionControls,
      restorationId: restorationId ?? this.restorationId,
      onClipboardFound: onClipboardFound ?? this.onClipboardFound,
      onAppPrivateCommand: onAppPrivateCommand ?? this.onAppPrivateCommand,
      mouseCursor: mouseCursor ?? this.mouseCursor,
      forceErrorState: forceErrorState ?? this.forceErrorState,
      errorText: errorText ?? this.errorText,
      validator: validator ?? this.validator,
      errorBuilder: errorBuilder ?? this.errorBuilder,
      errorTextStyle: errorTextStyle ?? this.errorTextStyle,
      pinputAutovalidateMode: pinputAutovalidateMode ?? this.pinputAutovalidateMode,
      scrollPadding: scrollPadding ?? this.scrollPadding,
      contextMenuBuilder: contextMenuBuilder ?? this.contextMenuBuilder,
    );
  }

  /// Config of the pin in default state
  final PinItemConfig? defaultPinConfig;

  /// Config of the pin in focused state
  final PinItemConfig? focusedPinConfig;

  /// Config of the pin in submitted state
  final PinItemConfig? submittedPinConfig;

  /// Config of the pin in following state
  final PinItemConfig? followingPinConfig;

  /// Config of the pin in disabled state
  final PinItemConfig? disabledPinConfig;

  /// Config of the pin in error state
  final PinItemConfig? errorPinConfig;

  /// If true keyboard will be closed
  final bool closeKeyboardWhenCompleted;

  /// Displayed fields count. PIN code length.
  final int length;

  /// By default Android autofill is Disabled, you can enable it by passing [smsRetriever]
  /// SmsRetriever exposes methods to listen for incoming SMS and extract code from it
  /// Recommended package to get sms code on Android is smart_auth https://pub.dev/packages/smart_auth
  final SmsRetriever? smsRetriever;

  /// Fires when user completes pin input
  final ValueChanged<String>? onCompleted;

  /// Called every time input value changes.
  final ValueChanged<String>? onChanged;

  /// See [EditableText.onSubmitted]
  final ValueChanged<String>? onSubmitted;

  /// Called when user clicks on PinPut
  final VoidCallback? onTap;

  /// Triggered when a pointer has remained in contact with the Pin at the
  /// same location for a long period of time.
  final VoidCallback? onLongPress;

  /// Used to get, modify PinPut value and more.
  /// Don't forget to dispose controller
  /// ``` dart
  ///   @override
  ///   void dispose() {
  ///     controller.dispose();
  ///     super.dispose();
  ///   }
  /// ```
  final TextEditingController? controller;

  /// Defines the keyboard focus for this
  /// To give the keyboard focus to this widget, provide a [focusNode] and then
  /// use the current [FocusScope] to request the focus:
  /// Don't forget to dispose focusNode
  /// ``` dart
  ///   @override
  ///   void dispose() {
  ///     focusNode.dispose();
  ///     super.dispose();
  ///   }
  /// ```
  final FocusNode? focusNode;

  /// Widget that is displayed before field submitted.
  final Widget? preFilledWidget;

  /// Builds a [Pin] separator
  /// If null SizedBox(width: 8) will be used
  final JustIndexedWidgetBuilder? separatorBuilder;

  /// Builds a [Pin] item
  /// If null the default _PinItem will be used
  final _PinItemBuilder? _builder;

  /// Defines how [Pin] fields are being placed inside [Row]
  final MainAxisAlignment mainAxisAlignment;

  /// Defines how [Pin] and ([errorText] or [errorBuilder]) are being placed inside [Column]
  final CrossAxisAlignment crossAxisAlignment;

  /// Defines how each [Pin] field are being placed within the container
  final AlignmentGeometry pinContentAlignment;

  /// curve of every [Pin] Animation
  final Curve animationCurve;

  /// Duration of every [Pin] Animation
  final Duration animationDuration;

  /// Animation Type of each [Pin] field
  /// options:
  /// none, scale, fade, slide, rotation
  final PinAnimationType pinAnimationType;

  /// Begin Offset of ever [Pin] field when [pinAnimationType] is slide
  final Offset? slideTransitionBeginOffset;

  /// Defines [Pin] state
  final bool enabled;

  /// See [EditableText.readOnly]
  final bool readOnly;

  /// See [EditableText.autofocus]
  final bool autofocus;

  /// Whether to use Native keyboard or custom one
  /// when flag is set to false [Pin] wont be focusable anymore
  /// so you should set value of [Pin]'s [TextEditingController] programmatically
  final bool useNativeKeyboard;

  /// If true, paste button will appear on longPress event
  final bool toolbarEnabled;

  /// Whether show cursor or not
  /// Default cursor '|' or [cursor]
  final bool showCursor;

  /// Whether to enable cursor animation
  final bool isCursorAnimationEnabled;

  /// Whether to enable that the IME update personalized data such as typing history and user dictionary data.
  //
  // This flag only affects Android. On iOS, there is no equivalent flag.
  //
  // Defaults to false. Cannot be null.
  final bool enableIMEPersonalizedLearning;

  /// If [showCursor] true the focused field will show passed Widget
  final Widget? cursor;

  /// The appearance of the keyboard.
  /// This setting is only honored on iOS devices.
  /// If unset, defaults to [ConfigData.brightness].
  final Brightness? keyboardAppearance;

  /// See [EditableText.inputFormatters]
  final List<TextInputFormatter> inputFormatters;

  /// See [EditableText.keyboardType]
  final TextInputType keyboardType;

  /// Provide any symbol to obscure each [Pin] pin
  /// Recommended ●
  final String obscuringCharacter;

  /// IF [obscureText] is true typed text will be replaced with passed Widget
  final Widget? obscuringWidget;

  /// Whether hide typed pin or not
  final bool obscureText;

  /// See [EditableText.textCapitalization]
  final TextCapitalization textCapitalization;

  /// The type of action button to use for the keyboard.
  ///
  /// Defaults to [TextInputAction.newline] if [keyboardType] is
  /// [TextInputType.multiline] and [TextInputAction.done] otherwise.
  final TextInputAction? textInputAction;

  /// See [EditableText.autofillHints]
  final Iterable<String>? autofillHints;

  /// See [EditableText.enableSuggestions]
  final bool enableSuggestions;

  /// See [EditableText.selectionControls]
  final TextSelectionControls? selectionControls;

  /// See [TextField.restorationId]
  final String? restorationId;

  /// Fires when clipboard has text of Pin's length
  final ValueChanged<String>? onClipboardFound;

  /// Use haptic feedback everytime user types on keyboard
  /// See more details in [HapticFeedback]
  final PinHapticFeedbackType hapticFeedbackType;

  /// See [EditableText.onAppPrivateCommand]
  final AppPrivateCommandCallback? onAppPrivateCommand;

  /// See [EditableText.mouseCursor]
  final MouseCursor? mouseCursor;

  /// If true [errorPinConfig] will be applied and [errorText] will be displayed under the Pin
  final bool forceErrorState;

  /// Text displayed under the Pin if Pin is invalid
  final String? errorText;

  /// Style of error text
  final TextStyle? errorTextStyle;

  /// If [Pin] has error and [errorBuilder] is passed it will be rendered under the Pin
  final PinErrorBuilder? errorBuilder;

  /// Return null if pin is valid or any String otherwise
  final FormFieldValidator<String>? validator;

  /// Return null if pin is valid or any String otherwise
  final PinAutovalidateMode pinputAutovalidateMode;

  /// When this widget receives focus and is not completely visible (for example scrolled partially
  /// off the screen or overlapped by the keyboard)
  /// then it will attempt to make itself visible by scrolling a surrounding [Scrollable], if one is present.
  /// This value controls how far from the edges of a [Scrollable] the TextField will be positioned after the scroll.
  final EdgeInsets scrollPadding;

  /// {@macro flutter.widgets.EditableText.contextMenuBuilder}
  ///
  /// If not provided, will build a default menu based on the platform.
  ///
  /// See also:
  ///
  ///  * [AdaptiveTextSelectionToolbar], which is built by default.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// A callback to be invoked when a tap is detected outside of this [TapRegion]
  /// The [PointerDownEvent] passed to the function is the event that caused the
  /// notification. If this region is part of a group
  /// then it's possible that the event may be outside of this immediate region,
  /// although it will be within the region of one of the group members.
  /// This is useful if you want to un-focus the [Pin] when user taps outside of it
  final TapRegionCallback? onTapOutside;

  static Widget _defaultContextMenuBuilder(
    BuildContext context,
    EditableTextState editableTextState,
  ) {
    return AdaptiveTextSelectionToolbar.editableText(
      editableTextState: editableTextState,
    );
  }

  @override
  State<Pin> createState() => _PinState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PinItemConfig>('defaultPinConfig', defaultPinConfig, defaultValue: null));
    properties.add(DiagnosticsProperty<PinItemConfig>('focusedPinConfig', focusedPinConfig, defaultValue: null));
    properties.add(DiagnosticsProperty<PinItemConfig>('submittedPinConfig', submittedPinConfig, defaultValue: null));
    properties.add(DiagnosticsProperty<PinItemConfig>('followingPinConfig', followingPinConfig, defaultValue: null));
    properties.add(DiagnosticsProperty<PinItemConfig>('disabledPinConfig', disabledPinConfig, defaultValue: null));
    properties.add(DiagnosticsProperty<PinItemConfig>('errorPinConfig', errorPinConfig, defaultValue: null));
    properties.add(DiagnosticsProperty<TextEditingController>('controller', controller, defaultValue: null));
    properties.add(DiagnosticsProperty<FocusNode>('focusNode', focusNode, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true));
    properties.add(DiagnosticsProperty<bool>('closeKeyboardWhenCompleted', closeKeyboardWhenCompleted, defaultValue: true));
    properties.add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: TextInputType.number));
    properties.add(DiagnosticsProperty<int>('length', length, defaultValue: PinConstants._defaultLength));
    properties.add(DiagnosticsProperty<ValueChanged<String>?>('onCompleted', onCompleted, defaultValue: null));
    properties.add(DiagnosticsProperty<ValueChanged<String>?>('onChanged', onChanged, defaultValue: null));
    properties.add(DiagnosticsProperty<ValueChanged<String>?>('onClipboardFound', onClipboardFound, defaultValue: null));
    properties.add(DiagnosticsProperty<VoidCallback?>('onTap', onTap, defaultValue: null));
    properties.add(DiagnosticsProperty<VoidCallback?>('onLongPress', onLongPress, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('preFilledWidget', preFilledWidget, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('cursor', cursor, defaultValue: null));
    properties.add(DiagnosticsProperty<JustIndexedWidgetBuilder?>('separatorBuilder', separatorBuilder, defaultValue: PinConstants._defaultSeparator));
    properties.add(DiagnosticsProperty<_PinItemBuilder>('_builder', _builder, defaultValue: null));
    properties.add(DiagnosticsProperty<Widget?>('obscuringWidget', obscuringWidget, defaultValue: null));
    properties.add(DiagnosticsProperty<MainAxisAlignment>('mainAxisAlignment', mainAxisAlignment, defaultValue: MainAxisAlignment.center));
    properties.add(DiagnosticsProperty<AlignmentGeometry>('pinContentAlignment', pinContentAlignment, defaultValue: Alignment.center));
    properties.add(DiagnosticsProperty<Curve>('animationCurve', animationCurve, defaultValue: Curves.easeIn));
    properties.add(DiagnosticsProperty<Duration>('animationDuration', animationDuration, defaultValue: PinConstants._animationDuration));
    properties.add(DiagnosticsProperty<PinAnimationType>('pinAnimationType', pinAnimationType, defaultValue: PinAnimationType.scale));
    properties.add(DiagnosticsProperty<Offset?>('slideTransitionBeginOffset', slideTransitionBeginOffset, defaultValue: null));
    properties.add(DiagnosticsProperty<bool>('enabled', enabled, defaultValue: true));
    properties.add(DiagnosticsProperty<bool>('readOnly', readOnly, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('autofocus', autofocus, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('useNativeKeyboard', useNativeKeyboard, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('toolbarEnabled', toolbarEnabled, defaultValue: true));
    properties.add(DiagnosticsProperty<bool>('showCursor', showCursor, defaultValue: true));
    properties.add(DiagnosticsProperty<String>('obscuringCharacter', obscuringCharacter,  defaultValue: '•'));
    properties.add(DiagnosticsProperty<bool>('obscureText', obscureText, defaultValue: false));
    properties.add(DiagnosticsProperty<bool>('enableSuggestions', enableSuggestions, defaultValue: true));
    properties.add(DiagnosticsProperty<List<TextInputFormatter>>('inputFormatters', inputFormatters, defaultValue: const <TextInputFormatter>[]));
    properties.add(EnumProperty<TextInputAction>('textInputAction', textInputAction, defaultValue: TextInputAction.done));
    properties.add(EnumProperty<TextCapitalization>('textCapitalization', textCapitalization, defaultValue: TextCapitalization.none));
    properties.add(DiagnosticsProperty<Brightness>('keyboardAppearance', keyboardAppearance, defaultValue: null));
    properties.add(DiagnosticsProperty<TextInputType>('keyboardType', keyboardType, defaultValue: TextInputType.number));
    properties.add(DiagnosticsProperty<Iterable<String>?>('autofillHints', autofillHints, defaultValue: null));
    properties.add(DiagnosticsProperty<TextSelectionControls?>('selectionControls', selectionControls, defaultValue: null));
    properties.add(DiagnosticsProperty<String?>('restorationId', restorationId, defaultValue: null));
    properties.add(DiagnosticsProperty<AppPrivateCommandCallback?>('onAppPrivateCommand', onAppPrivateCommand,  defaultValue: null));
    properties.add(DiagnosticsProperty<MouseCursor?>('mouseCursor', mouseCursor, defaultValue: null));
    properties.add(DiagnosticsProperty<TextStyle?>('errorTextStyle', errorTextStyle, defaultValue: null));
    properties.add(DiagnosticsProperty<PinErrorBuilder?>('errorBuilder', errorBuilder, defaultValue: null));
    properties.add(DiagnosticsProperty<FormFieldValidator<String>?>('validator', validator, defaultValue: null));
    properties.add(DiagnosticsProperty<PinAutovalidateMode>('pinputAutovalidateMode', pinputAutovalidateMode, defaultValue: PinAutovalidateMode.onSubmit));
    properties.add(DiagnosticsProperty<PinHapticFeedbackType>('hapticFeedbackType', hapticFeedbackType, defaultValue: PinHapticFeedbackType.disabled));
    properties.add(DiagnosticsProperty<EditableTextContextMenuBuilder?>('contextMenuBuilder', contextMenuBuilder, defaultValue: _defaultContextMenuBuilder));
  }
}