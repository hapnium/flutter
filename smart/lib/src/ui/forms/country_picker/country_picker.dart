import 'package:flutter/material.dart';
import 'package:smart/src/utilities/country/country_data.dart';
import 'package:smart/utilities.dart';
import 'package:hapnium/hapnium.dart';

import '../../export.dart';

part 'country_picker_state.dart';

/// The default route for the country selector.
String _defaultRoute = "/country_selector";

/// A widget that provides a country selection UI.
class CountryPicker extends StatefulWidget {
  /// A list of available countries.
  final List<Country> countries;

  /// The currently selected country.
  final Country? selected;

  /// A callback function that gets called when a country is selected.
  final SelectedCountryChanged? onChanged;

  /// Placeholder text for the search field.
  final String? placeholder;

  /// Determines whether the country picker appears as a dialog.
  final Boolean isDialog;

  /// Determines whether a search field should be displayed.
  final Boolean showSearchFormField;

  /// Determines if the country flag should be displayed as an emoji.
  final Boolean useFlagEmoji;

  /// Padding for the dialog container.
  final EdgeInsets? dialogPadding;

  /// Background color of the country picker.
  final Color? backgroundColor;

  /// Surface tint color for the country picker.
  final Color? surfaceTintColor;

  /// Color for the country name text.
  final Color? itemNameColor;

  /// Color for the country code text.
  final Color? itemCodeColor;

  /// Color for the country flag icon.
  final Color? itemFlagColor;

  /// Color for the country dial code text.
  final Color? itemDialCodeColor;

  /// Color for the item background.
  final Color? itemBackgroundColor;

  /// The color of the form background.
  final Color? formBackgroundColor;

  /// Padding for the body of the country picker.
  final EdgeInsetsGeometry? bodyPadding;

  /// Configuration builder for the input field.
  final FieldInputConfigBuilder? inputConfigBuilder;

  /// Configuration builder for field decoration.
  final FieldDecorationConfigBuilder? decorationConfigBuilder;

  /// Builder for rendering item separators.
  final CountryItemBuilder? itemSeparatorBuilder;

  /// Builder for rendering country list items.
  final CountryItemBuilder? itemBuilder;

  /// Builder for rendering the search form field.
  final CountrySearchFormFieldBuilder? searchFormFieldBuilder;

  /// Builder for rendering a search field using [Field] widget
  final CountrySearchFieldBuilder? searchFieldBuilder;

  /// Spacing between items in the body.
  final Double? bodySpacing;

  /// Size of the separator between items.
  final Double? itemSeparatorSize;

  /// Font size for country names.
  final Double? itemNameSize;

  /// Font size for country codes.
  final Double? itemCodeSize;

  /// Font size for country flags.
  final Double? itemFlagSize;

  /// Font size for country dial codes.
  final Double? itemDialCodeSize;

  /// Border radius for the form field.
  final Double? formBorderRadius;

  /// Font weight for country names.
  final FontWeight? itemNameWeight;

  /// Font weight for country codes.
  final FontWeight? itemCodeWeight;

  /// Font weight for country flags.
  final FontWeight? itemFlagWeight;

  /// Font weight for country dial codes.
  final FontWeight? itemDialCodeWeight;

  /// Duration of the dialog animation.
  final Duration? dialogAnimationDuration;

  /// Curve for the dialog animation.
  final Curve? dialogAnimationCurve;

  /// Shape of the dialog.
  final ShapeBorder? dialogShape;

  /// Border radius for the bottom sheet.
  final BorderRadiusGeometry? bottomSheetBorderRadius;

  /// Main axis size for the country picker.
  final MainAxisSize? mainAxisSize;

  /// A widget displayed as an indicator.
  final Widget? indicator;

  /// A widget displayed as an icon.
  final Widget? icon;

  /// The height of the modal sheet.
  final Double? height;

  /// UI Config to override other settings
  ///
  /// Defaults to null
  final UiConfig? uiConfig;

  /// This specifies that when `sheetPadding` is not null, default border radius will be applied
  ///
  /// Can be overriden by making this false
  final Boolean useDefaultBorderRadius;

  /// Private constructor for the country picker.
  CountryPicker._({
    required this.placeholder,
    required this.countries,
    required this.onChanged,
    required this.selected,
    required this.isDialog,
    required this.searchFieldBuilder,
    required this.showSearchFormField,
    required this.useFlagEmoji,
    required this.dialogPadding,
    required this.backgroundColor,
    required this.surfaceTintColor,
    required this.itemNameColor,
    required this.itemCodeColor,
    required this.itemFlagColor,
    required this.itemDialCodeColor,
    required this.itemBackgroundColor,
    required this.formBackgroundColor,
    required this.bodyPadding,
    required this.inputConfigBuilder,
    required this.decorationConfigBuilder,
    required this.itemSeparatorBuilder,
    required this.itemBuilder,
    required this.searchFormFieldBuilder,
    required this.bodySpacing,
    required this.itemSeparatorSize,
    required this.itemNameSize,
    required this.itemCodeSize,
    required this.itemFlagSize,
    required this.itemDialCodeSize,
    required this.formBorderRadius,
    required this.itemNameWeight,
    required this.itemCodeWeight,
    required this.itemFlagWeight,
    required this.itemDialCodeWeight,
    required this.dialogAnimationDuration,
    required this.dialogAnimationCurve,
    required this.dialogShape,
    required this.bottomSheetBorderRadius,
    required this.mainAxisSize,
    required this.indicator,
    required this.icon,
    this.height,
    this.uiConfig,
    this.useDefaultBorderRadius = true
  });

  /// Opens the country picker as a dialog.
  /// 
  /// This uses the `CountryPicker` fields to build a dialog of `CountryPicker`.
  /// It also returns a value instance of `Country`. But always check for this 
  /// instance before accessing or using it.
  static Future<T?> openAsDialog<T>({
    required BuildContext context,
    Country? selected,
    SelectedCountryChanged? onChanged,
    List<Country> countries = const [],
    String? placeholder,
    Boolean showSearchFormField = true,
    Boolean useFlagEmoji = false,
    EdgeInsets? dialogPadding,
    Color? backgroundColor,
    Color? surfaceTintColor,
    Color? itemNameColor,
    Color? itemCodeColor,
    Color? itemFlagColor,
    Color? itemDialCodeColor,
    Color? itemBackgroundColor,
    Color? formBackgroundColor,
    EdgeInsetsGeometry? bodyPadding,
    FieldInputConfigBuilder? inputConfigBuilder,
    FieldDecorationConfigBuilder? decorationConfigBuilder,
    CountryItemBuilder? itemSeparatorBuilder,
    CountryItemBuilder? itemBuilder,
    CountrySearchFormFieldBuilder? searchFormFieldBuilder,
    Double? bodySpacing,
    Double? itemSeparatorSize,
    Double? itemNameSize,
    Double? itemCodeSize,
    Double? itemFlagSize,
    Double? itemDialCodeSize,
    Double? formBorderRadius,
    FontWeight? itemNameWeight,
    FontWeight? itemCodeWeight,
    FontWeight? itemFlagWeight,
    FontWeight? itemDialCodeWeight,
    Duration? dialogAnimationDuration,
    Curve? dialogAnimationCurve,
    ShapeBorder? dialogShape,
    MainAxisSize? mainAxisSize,
    Widget? indicator,
    Widget? icon,
    String? route,
    bool barrierDismissible = true,
    Color? barrierColor,
    bool useSafeArea = true,
    bool useRootNavigator = true,
    Offset? anchorPoint,
    TraversalEdgeBehavior? traversalEdgeBehavior,
    CountrySearchFieldBuilder? searchFieldBuilder,
  }) async {
    route ??= _defaultRoute;

    return await showDialog(
      context: context,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      anchorPoint: anchorPoint,
      traversalEdgeBehavior: traversalEdgeBehavior,
      routeSettings: RouteSettings(name: route),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => CountryPicker._(
          placeholder: placeholder,
          countries: countries,
          selected: selected,
          isDialog: true,
          onChanged: (Country country) {
            if(onChanged.isNotNull) {
              onChanged!(country);
            }

            setState(() {});
          },
          showSearchFormField: showSearchFormField,
          searchFieldBuilder: searchFieldBuilder,
          useFlagEmoji: useFlagEmoji,
          dialogPadding: dialogPadding,
          backgroundColor: backgroundColor,
          surfaceTintColor: surfaceTintColor,
          itemNameColor: itemNameColor,
          itemCodeColor: itemCodeColor,
          itemFlagColor: itemFlagColor,
          itemDialCodeColor: itemDialCodeColor,
          itemBackgroundColor: itemBackgroundColor,
          formBackgroundColor: formBackgroundColor,
          bodyPadding: bodyPadding,
          inputConfigBuilder: inputConfigBuilder,
          decorationConfigBuilder: decorationConfigBuilder,
          itemSeparatorBuilder: itemSeparatorBuilder,
          itemBuilder: itemBuilder,
          searchFormFieldBuilder: searchFormFieldBuilder,
          bodySpacing: bodySpacing,
          itemSeparatorSize: itemSeparatorSize,
          itemNameSize: itemNameSize,
          itemCodeSize: itemCodeSize,
          itemFlagSize: itemFlagSize,
          itemDialCodeSize: itemDialCodeSize,
          formBorderRadius: formBorderRadius,
          itemNameWeight: itemNameWeight,
          itemCodeWeight: itemCodeWeight,
          itemFlagWeight: itemFlagWeight,
          itemDialCodeWeight: itemDialCodeWeight,
          dialogAnimationDuration: dialogAnimationDuration,
          dialogAnimationCurve: dialogAnimationCurve,
          dialogShape: dialogShape,
          bottomSheetBorderRadius: null,
          mainAxisSize: mainAxisSize,
          indicator: indicator,
          icon: icon
        ),
      ),
    );
  }

  /// Opens the country picker as a bottom sheet.
  /// 
  /// This uses the `CountryPicker` fields to build a bottom sheet of `CountryPicker`.
  /// It also returns a value instance of `Country`. But always check for this 
  /// instance before accessing or using it.
  static Future<T?> openAsBottomSheet<T>({
    required BuildContext context,
    Country? selected,
    SelectedCountryChanged? onChanged,
    List<Country> countries = const [],
    String? placeholder,
    Boolean showSearchFormField = true,
    Boolean useFlagEmoji = false,
    EdgeInsets? dialogPadding,
    Color? backgroundColor,
    Color? itemNameColor,
    Color? itemCodeColor,
    Color? itemFlagColor,
    Color? itemDialCodeColor,
    Color? itemBackgroundColor,
    Color? formBackgroundColor,
    EdgeInsetsGeometry? bodyPadding,
    FieldInputConfigBuilder? inputConfigBuilder,
    FieldDecorationConfigBuilder? decorationConfigBuilder,
    CountryItemBuilder? itemSeparatorBuilder,
    CountryItemBuilder? itemBuilder,
    CountrySearchFormFieldBuilder? searchFormFieldBuilder,
    Double? bodySpacing,
    Double? itemSeparatorSize,
    Double? itemNameSize,
    Double? itemCodeSize,
    Double? itemFlagSize,
    Double? itemDialCodeSize,
    Double? formBorderRadius,
    FontWeight? itemNameWeight,
    FontWeight? itemCodeWeight,
    FontWeight? itemFlagWeight,
    FontWeight? itemDialCodeWeight,
    ShapeBorder? shape,
    BorderRadiusGeometry? bottomSheetBorderRadius,
    MainAxisSize? mainAxisSize,
    Widget? indicator,
    Widget? icon,
    String? route,
    AnimationController? transitionAnimationController,
    Offset? anchorPoint,
    AnimationStyle? sheetAnimationStyle,
    BoxConstraints? constraints,
    Color? barrierColor,
    bool isScrollControlled = false,
    bool useRootNavigator = false,
    bool isDismissible = true,
    bool enableDrag = true,
    bool? showDragHandle,
    bool useSafeArea = false,
    double? elevation,
    UiConfig? uiConfig,
    Double? height,
    Boolean? useDefaultBorderRadius,
    CountrySearchFieldBuilder? searchFieldBuilder,
  }) async {
    route ??= _defaultRoute;
    
    return await showModalBottomSheet(
      context: context,
      enableDrag: enableDrag,
      elevation: elevation,
      useRootNavigator: useRootNavigator,
      useSafeArea: useSafeArea,
      barrierColor: barrierColor,
      anchorPoint: anchorPoint,
      showDragHandle: showDragHandle,
      isScrollControlled: isScrollControlled,
      shape: shape,
      backgroundColor: backgroundColor,
      transitionAnimationController: transitionAnimationController,
      sheetAnimationStyle: sheetAnimationStyle,
      routeSettings: RouteSettings(name: route),
      builder: (context) => StatefulBuilder(
        builder: (ctx, setState) => CountryPicker._(
          placeholder: placeholder,
          countries: countries,
          selected: selected,
          isDialog: false,
          onChanged: (Country country) {
            if(onChanged case final onChanged?) {
              onChanged(country);
            }

            setState(() {});
          },
          showSearchFormField: showSearchFormField,
          searchFieldBuilder: searchFieldBuilder,
          useFlagEmoji: useFlagEmoji,
          dialogPadding: dialogPadding,
          backgroundColor: backgroundColor,
          surfaceTintColor: null,
          itemNameColor: itemNameColor,
          itemCodeColor: itemCodeColor,
          itemFlagColor: itemFlagColor,
          itemDialCodeColor: itemDialCodeColor,
          itemBackgroundColor: itemBackgroundColor,
          formBackgroundColor: formBackgroundColor,
          bodyPadding: bodyPadding,
          inputConfigBuilder: inputConfigBuilder,
          decorationConfigBuilder: decorationConfigBuilder,
          itemSeparatorBuilder: itemSeparatorBuilder,
          itemBuilder: itemBuilder,
          searchFormFieldBuilder: searchFormFieldBuilder,
          bodySpacing: bodySpacing,
          itemSeparatorSize: itemSeparatorSize,
          itemNameSize: itemNameSize,
          itemCodeSize: itemCodeSize,
          itemFlagSize: itemFlagSize,
          itemDialCodeSize: itemDialCodeSize,
          formBorderRadius: formBorderRadius,
          itemNameWeight: itemNameWeight,
          itemCodeWeight: itemCodeWeight,
          itemFlagWeight: itemFlagWeight,
          itemDialCodeWeight: itemDialCodeWeight,
          dialogAnimationDuration: null,
          dialogAnimationCurve: null,
          dialogShape: null,
          bottomSheetBorderRadius: bottomSheetBorderRadius,
          mainAxisSize: mainAxisSize,
          indicator: indicator,
          icon: icon,
          height: height,
          uiConfig: uiConfig,
          useDefaultBorderRadius: useDefaultBorderRadius ?? true
        ),
      ),
    );
  }

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}