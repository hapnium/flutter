import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:smart/enums.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/utilities.dart';

import 'export.dart';

/// Represents an image provider that loads and displays images within the app.
///
/// [ImageResource] is used to represent image resources and can be used for displaying images
/// from various sources such as assets, network, or file system. It is typically used
/// in widgets like [Image] to show images in the app interface.
typedef ImageResource = ImageProvider<Object>;

typedef ImageResourceBuilder = ImageResource Function(BuildContext context, String fallback);

typedef ImageDecorationBuilder = Decoration Function(BuildContext context, ImageProvider? image, String fallback, Color? color, ImageErrorListener? listener);

/// A function that builds a widget based on a given value of type [T].
///
/// The [ItemTypeWidgetBuilder] of [T] typedef defines a function signature for
/// functions that construct a [Widget] based on a provided value of type [T]
/// and the current [BuildContext]. This is commonly used to dynamically
/// build UI elements based on different data types or states.
typedef ItemTypeWidgetBuilder<T> = Widget Function(BuildContext context, ItemMetadata<T> metadata);

/// Represents a callback function that is invoked when a screen needs to be popped from the navigation stack.
///
/// * `success`: Indicates whether the pop operation was successful.
/// * `result`: Optional data to be passed back to the previous screen.
typedef PopScreenInvoked = Function(bool success, dynamic result);

/// Represents a callback function that is invoked to handle a specific activity or event within the application.
///
/// The specific actions performed within the handler will vary depending on the context
/// where it is used.
typedef UserActivityHandler = Function(PointerDownEvent? down, PointerMoveEvent? move, PointerUpEvent? up, PointerHoverEvent? hover);

/// Represents a callback function for handling cookie consent updates.
///
/// The function is triggered when the user provides consent for cookies,
/// typically involving the user's decision about essential, advertising, or analytics cookies.
typedef CookieConsentHandler = Consumer<CookieConsent>;

/// Represents a callback function to check if a specific permission is granted or denied.
///
/// This function returns a boolean value indicating whether the user has granted or denied access
/// to a specific feature or permission (e.g., location, camera).
typedef PermissionAccessHandler = Supplier<Future<Boolean>>;

/// Represents a callback function that is triggered when an action is invoked.
///
/// This function typically handles the execution of a certain action, such as
/// a user event or a system-triggered event within the application.
typedef OnActionInvoked = Function();

/// Represents a function that resolves the appropriate icon for a given rating value.
///
/// This typedef defines a function that takes a [double] representing the rating value
/// and a [RatingIconConfig] object containing configuration options as input.
/// It returns an [IconData] object representing the icon to be displayed for the given rating.
///
/// This function is typically used in rating systems to dynamically
/// display different icons based on the rating value.
/// For example, it could be used to display star icons with different fill levels
/// depending on the rating.
typedef RatingIconResolver = IconData Function(double rating, RatingIconConfig config);

/// A callback function that is invoked when the selected country changes.
///
/// This typedef represents a function that takes a [Country] object as a parameter
/// and is typically used to handle the event of a country selection change.
/// The function can be used to update the UI, trigger other actions, or perform any necessary logic
/// based on the newly selected country.
typedef SelectedCountryChanged = void Function(Country country);

/// A callback function that is invoked when the entered phone number changes.
///
/// This typedef represents a function that takes a [PhoneNumber] object as a parameter
/// and is typically used to handle the event of a phone number change.
/// The function can be used to update the UI, validate the phone number,
/// or perform other actions based on the changes made to the phone number.
typedef PhoneNumberChanged = void Function(PhoneNumber phoneNumber);

/// A typedef for a function that builds a widget for a given country.
///
/// This typedef represents a function that takes three arguments:
///
/// * [context]: The build context of the widget.
/// * [metadata]: The [ItemMetadata] of the current [Country] item.
///
/// The function is responsible for building a widget to represent the given `Country` object within the UI.
typedef CountryItemBuilder = Widget Function(BuildContext context, ItemMetadata<Country> metadata);

/// A function signature for modifying a [SafeAreaConfig] instance.
///
/// This typedef represents a function that takes a [SafeAreaConfig] object as input
/// and returns a modified or new [SafeAreaConfig] object.
///
/// ## Example Usage:
/// ```dart
/// SafeAreaConfiguration customConfig = (SafeAreaConfig config) {
///   return config.copyWith(top: false, bottom: false);
/// };
///
/// SafeAreaConfig initialConfig = SafeAreaConfig();
/// SafeAreaConfig updatedConfig = customConfig(initialConfig);
/// print(updatedConfig); // SafeAreaConfig(left: true, top: false, right: true, bottom: false, ...)
/// ```
///
/// This is useful for dynamically modifying [SafeAreaConfig] settings before applying them.
typedef SafeAreaConfigBuilder = SafeAreaConfig Function(SafeAreaConfig config);

/// A function signature for modifying a [FieldDecorationConfig] instance.
///
/// This typedef represents a function that takes a [FieldDecorationConfig] object as input
/// and returns a modified or new [FieldDecorationConfig] object.
///
/// ## Example Usage:
/// ```dart
/// FieldConfiguration customConfig = (FieldConfig config) {
///   return config.copyWith(useNotEnabled: false);
/// };
///
/// FieldConfig initialConfig = FieldConfig();
/// FieldConfig updatedConfig = customConfig(initialConfig);
/// print(updatedConfig); // FieldConfig(..)
/// ```
///
/// This is useful for dynamically modifying [FieldDecorationConfig] settings before applying them.
typedef FieldDecorationConfigBuilder = FieldDecorationConfig Function(FieldDecorationConfig config);

/// A function type definition for building a custom field input configuration.
typedef FieldInputConfigBuilder = FieldInputConfig Function(FieldInputConfig config);

/// A function type definition for validating form field input.
typedef FieldValidator = String? Function(String? value);

/// Represents a callback function that handles a URL.
///
/// This typedef defines a function that takes a [String] representing a URL as input
/// and performs a specific action. The exact behavior of the function will depend
/// on the context in which it is used.
///
/// For example:
///
/// ```dart
/// void openUrl(String url) {
///   // Handle the URL, e.g., launch in a web browser
/// }
/// ```
typedef UrlHandler = Consumer<String>;

/// Represents a callback function that handles a URI.
///
/// This typedef defines a function that takes a [Uri] object as input
/// and performs a specific action. The exact behavior of the function will depend
/// on the context in which it is used.
///
/// For example:
///
/// ```dart
/// void handleUri(Uri uri) {
///   // Handle the URI, e.g., navigate to a different screen
/// }
/// ```
typedef UriHandler = Function(Uri uri);

/// A type definition for a function that selects and builds app details.
///
/// This typedef represents a function that consumes a [DomainAppLink] object
/// and returns the value of the app details.
typedef AppDetailsSelector = Consumer<DomainAppLink>;

/// A function type definition for building a custom country search form field.
///
/// This allows users to provide a custom widget that can replace the default search field
/// while still maintaining the country filtering logic from the [CountryPicker] class.
typedef CountrySearchFormFieldBuilder = Widget Function(Consumer<String> onChanged);

/// A builder function that creates a widget for displaying the country flag.
///
/// **Parameters:**
///
/// * [context]: The build context.
/// * [country]: The selected country object.
/// * [onCountryChanged]: A callback function that is called when the selected country changes.
typedef PhoneFlagBuilder = Widget Function(BuildContext context, Country country, SelectedCountryChanged onCountryChanged);

/// A builder function that creates a widget for the phone number field.
///
/// **Parameters:**
///
/// * [context]: The build context.
/// * [country]: The selected country object.
/// * [hasCountryList]: Whether the country list is visible.
/// * [onCountryChanged]: A callback function that is called when the selected country changes.
/// * [onPhoneChanged]: A callback function that is called when the phone number changes.
/// * [validator]: A function that validates the phone number.
/// * [onSaved]: A callback function that is called when the form is saved.
typedef PhoneFieldBuilder<T extends Field> = T Function(
  BuildContext context,
  Country country,
  bool hasCountryList,
  SelectedCountryChanged onCountryChanged,
  Consumer<String> onPhoneChanged,
  String? Function(String?) validator,
  Consumer<String> onSaved
);

/// A function that validates a phone number.
///
/// **Parameters:**
/// * [phoneNumber]: The phone number to be validated.
/// **Returns:**
/// An error message if the phone number is invalid, otherwise null.
typedef PhoneNumberValidator = FutureOr<String?> Function(PhoneNumber? phoneNumber);

/// A builder function that creates a widget for each [FieldItem]
///
/// **Parameters:**
///
/// * [context]: The build context.
/// * [metadata]: The [ItemMetadata] object.
/// * [field]: The [Field] widget to use.
typedef JustFieldItemBuilder = Widget Function(BuildContext context, Field field, ItemMetadata<FieldItem> metadata);

/// A callback function that is triggered when a preference is selected.
///
/// This function is called with the newly selected preference values.
///
/// **Parameters:**
/// * [gender]: The newly selected gender.
/// * [theme]: The newly selected theme.
/// * [preference]: The newly selected preference option.
/// * [schedule]: The newly selected schedule time.
/// * [security]: The newly selected security level.
///
/// **Returns:**
///
/// A [FutureOr] of [bool] indicating whether the preference selection was successful.
typedef PreferenceSelectorCallback = FutureOr<bool> Function(Gender gender, ThemeType theme, PreferenceOption preference, ScheduleTime schedule, SecurityType security);

/// A typedef for building custom poll metadata.
///
/// This function takes an instance of [SmartPollMetadata] and returns a [Widget]
/// that represents the metadata at the bottom of the poll.
typedef SmartPollMetadataBuilder = Widget Function(SmartPollMetadata meta);

/// A typedef for building custom poll options.
///
/// This function takes a [BuildContext] and an instance of [ItemMetadata] for
/// a [SmartPollOption], and returns a [Widget] representing the poll option.
typedef SmartPollOptionBuilder = Widget Function(BuildContext context, ItemMetadata<SmartPollOption> metadata);

/// A typedef for handling voting in the poll.
///
/// This function is triggered when the user votes for a poll option. It receives the
/// selected [SmartPollOption] and the new total vote count. The function should return
/// a [Future<bool>] indicating whether the vote was successfully recorded.
typedef SmartPollVotingCallback = Future<bool> Function(SmartPollOption option, int newTotalVotes);

/// A function that builds a custom [SmartPollOptionConfig] based on an existing configuration.
///
/// The [SmartPollOptionConfigBuilder] typedef defines a function signature for
/// functions that receive a [SmartPollOptionConfig] as input and return a
/// modified [SmartPollOptionConfig] object. This allows for flexible and
/// customizable configuration of [SmartPollOption] objects.
typedef SmartPollOptionConfigBuilder = SmartPollOptionConfig Function(SmartPollOptionConfig config, int index);

/// A builder function for creating custom share item widgets in the [SmartShare] widget.
///
/// This typedef defines a function that takes a `BuildContext` and an [ItemMetadata<SmartShareItem>]
/// object as parameters and returns a `Widget`. It allows developers to customize the
/// appearance and behavior of each share item in the `SmartShare` widget.
///
/// **Parameters:**
///
/// * `context`: The build context.
/// * `metadata`: Metadata containing information about the share item, such as its index
///   and whether it is the first or last item.
///
/// **Returns:**
///
/// A `Widget` representing the custom share item.
typedef SmartShareItemBuilder = Widget Function(BuildContext context, ItemMetadata<SmartShareItem> metadata);

/// A configuration function for customizing the [SmartShareItemConfig] of share items.
///
/// This typedef defines a function that takes a [SmartShareItemConfig] object and an index
/// as parameters and returns a modified [SmartShareItemConfig] object. It allows developers
/// to apply global configurations or modify individual item configurations based on their
/// index.
///
/// **Parameters:**
///
/// * `config`: The original [SmartShareItemConfig] object.
/// * [index]: The index of the share item.
///
/// **Returns:**
///
/// A modified [SmartShareItemConfig] object.
typedef SmartShareItemConfigurer = SmartShareItemConfig Function(SmartShareItemConfig config, int index);

/// A callback function that is triggered when a share item is clicked in the [SmartShare] widget.
///
/// This typedef defines a function that takes a [SmartShareItem] object and a content string
/// as parameters and returns void. It allows developers to handle the click event of each
/// share item and access the item's data and the content to be shared.
///
/// **Parameters:**
///
/// * `item`: The [SmartShareItem] object that was clicked.
/// * `content`: The content string to be shared.
typedef SmartShareItemCallback = void Function(SmartShareItem item, String content);

/// A builder function for customizing the list of share items in the [SmartShare] widget.
///
/// This typedef defines a function that takes a list of [SmartShareItem] objects as input
/// and returns a modified list of [SmartShareItem] objects. It allows developers to
/// dynamically alter the share items displayed in the [SmartShare] widget.
///
/// **Parameters:**
///
/// * [items]: The original list of [SmartShareItem] objects.
///
/// **Returns:**
///
/// A modified list of [SmartShareItem] objects.
///
/// **Usage:**
///
/// This typedef is used to provide a hook for customizing the share items before they
/// are displayed in the [SmartShare] widget. For example, you can use it to reorder,
/// add, remove, or modify the share items based on specific conditions or user preferences.
///
/// **Example:**
///
/// ```dart
/// SmartShareListItemBuilder customShareItems = (List<SmartShareItem> items) {
///   // Reorder the items to put WhatsApp at the top
///   items.sort((a, b) {
///     if (a.isWhatsApp) return -1;
///     if (b.isWhatsApp) return 1;
///     return 0;
///   });
///   return items;
/// };
/// ```
typedef SmartShareListItemBuilder = List<SmartShareItem> Function(List<SmartShareItem> items);