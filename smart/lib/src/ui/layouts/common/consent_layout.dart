import 'package:flutter/cupertino.dart';
import 'package:hapnium/hapnium.dart';

import '../../export.dart';

/// A widget to display both permission and cookie consent layouts for the user.
///
/// The `ConsentLayout` widget combines both permission and cookie consent layouts.
/// It manages the permissions and cookie consent together in one widget.
/// This allows the app to handle both the user permission requests and cookie preferences in a single layout.
class ConsentLayout extends StatelessWidget {
  /// The widget displayed as the background content of the layout.
  /// This is where the child widget will be placed within the layout.
  final Widget child;

  /// An object representing the cookie consent state.
  /// This object holds the current state of the cookie consent (accepted, rejected, etc.).
  final CookieConsent cookie;

  /// A boolean indicating whether the app is running on a web platform.
  /// Used to modify layout or behavior depending on the platform (web vs mobile).
  final bool isWeb;

  /// A boolean indicating whether the required permissions have been granted.
  /// This helps in determining if the user has already accepted the permission requests.
  final bool isPermissionGranted;

  /// The device sdk version.
  final Integer sdk;

  /// The name of the service or app requesting permission.
  /// This can be used in the UI to personalize the consent messages.
  final String name;

  /// The image resource displayed for the permission consent.
  /// This can be used to show a logo or related image within the permission card.
  final ImageResource permissionImage;

  /// A collection of permission names that the app requires.
  /// Used to display what permissions are being requested to the user.
  final StringCollection permissions;

  /// A function handler to request the required permission access.
  /// Triggered when the user clicks to grant permissions.
  final PermissionAccessHandler requestPermissionAccess;

  /// A callback function that gets called when the user grants permissions.
  /// This can be used for post-permission handling.
  final OnActionInvoked? onPermissionGranted;

  /// The background color of the permission consent card.
  /// Allows customization of the card's appearance.
  final Color? permissionCardColor;

  /// The color of the text displayed in the permission consent card.
  /// This allows adjusting the contrast and readability of the text in the card.
  final Color? permissionTextColor;

  /// The color of the "Grant Permissions" button.
  /// Customizes the appearance of the button used for permission granting.
  final Color? permissionButtonColor;

  /// The color of the text on the "Grant Permissions" button.
  /// This allows customizing the button text to ensure it stands out on the button color.
  final Color? permissionButtonTextColor;

  /// The width of the image displayed for the permission card.
  /// This allows customization of the size of the image within the permission card.
  final double? permissionImageWidth;

  /// The height of the image displayed for the permission card (default is 200).
  /// Adjust the height of the image to better fit the design of the card.
  final double permissionImageHeight;

  /// The width of the "Grant Permissions" button.
  /// Customize the button width to make it larger or smaller based on the layout.
  final double? permissionButtonWidth;

  /// The width of the permission consent card.
  /// This sets the maximum width of the entire permission card.
  final double permissionCardWidth;

  /// The distance from the bottom of the screen where the permission card will be placed.
  /// Allows fine control of where the card appears on the screen vertically.
  final double permissionBottomCardPlacement;

  /// The distance from the left side of the screen where the permission card will be placed.
  /// Customizes the horizontal position of the card on the screen.
  final double? permissionLeftCardPlacement;

  /// The distance from the left side when the permission card is resized.
  /// Used when resizing the card to manage the left margin.
  final double permissionLeftResizedCardPlacement;

  /// The distance from the right side of the screen where the permission card will be placed.
  /// Customizes the horizontal position of the card on the right side of the screen.
  final double permissionRightCardPlacement;

  /// The distance from the right side when the permission card is resized.
  /// Used when resizing the card to manage the right margin.
  final double permissionRightResizedCardPlacement;

  /// The elevation (shadow) of the permission card.
  /// Allows for a 3D effect by modifying the shadow depth of the card.
  final double permissionCardElevation;

  /// The shape of the permission card.
  /// Customizes the card’s borders and corners for a unique style (rounded, square, etc.).
  final ShapeBorder? permissionCardShape;

  /// Padding inside the permission consent card content.
  /// Allows for the internal padding of the card to provide space between the content and the edges.
  final EdgeInsetsGeometry? permissionCardContentPadding;

  /// A handler for when the user rejects cookies.
  /// Triggered when the user clicks the reject button in the cookie consent card.
  final CookieConsentHandler onCookieRejected;

  /// A handler for when the user accepts cookies.
  /// Triggered when the user clicks the accept button in the cookie consent card.
  final CookieConsentHandler onCookieAccepted;

  /// The background color of the cookie consent card.
  /// Allows customization of the background of the card to match the app’s theme.
  final Color? cookieCardColor;

  /// The color of the text displayed in the cookie consent card.
  /// Customizes the color of the text to match the design of the app.
  final Color? cookieTextColor;

  /// The color of the "Accept Cookies" button.
  /// Customizes the button appearance to indicate the action of accepting cookies.
  final Color? cookieAcceptButtonColor;

  /// The color of the text on the "Accept Cookies" button.
  /// This allows for the customization of the button text color.
  final Color? cookieAcceptButtonTextColor;

  /// The color of the "Reject Cookies" button.
  /// Customizes the button appearance for rejecting cookies.
  final Color? cookieRejectButtonColor;

  /// The color of the text on the "Reject Cookies" button.
  /// Customizes the text color on the reject button.
  final Color? cookieRejectButtonTextColor;

  /// The color of the "Settings" button in the cookie consent card.
  /// Provides a way for the user to configure cookie preferences.
  final Color? cookieSettingsButtonColor;

  /// The color of the text on the "Settings" button.
  /// Customizes the button text color for the settings button in the cookie consent.
  final Color? cookieSettingsButtonTextColor;

  /// The color of the hint text displayed in the cookie consent card.
  /// Used for hint or additional information displayed in the cookie card.
  final Color? cookieHintColor;

  /// The width of the "Accept", "Reject", and "Settings" buttons.
  /// Customizes the width of the buttons in the cookie consent card.
  final double? cookieButtonWidth;

  /// The width of the cookie consent card.
  /// This sets the maximum width of the entire cookie consent card.
  final double cookieCardWidth;

  /// The distance from the bottom of the screen where the cookie consent card will be placed.
  /// Similar to `permissionBottomCardPlacement`, but specifically for the cookie card.
  final double cookieBottomCardPlacement;

  /// The distance from the left side of the screen where the cookie consent card will be placed.
  /// Customizes the horizontal position of the cookie card on the screen.
  final double? cookieLeftCardPlacement;

  /// The distance from the left side when the cookie consent card is resized.
  /// Used when resizing the card to manage the left margin.
  final double cookieLeftResizedCardPlacement;

  /// The distance from the right side of the screen where the cookie consent card will be placed.
  /// Customizes the horizontal position of the cookie card on the right side of the screen.
  final double cookieRightCardPlacement;

  /// The distance from the right side when the cookie consent card is resized.
  /// Used when resizing the card to manage the right margin.
  final double cookieRightResizedCardPlacement;

  /// The elevation (shadow) of the cookie consent card.
  /// Allows for a 3D effect by modifying the shadow depth of the card.
  final double cookieCardElevation;

  /// The shape of the cookie consent card.
  /// Customizes the card’s borders and corners for a unique style (rounded, square, etc.).
  final ShapeBorder? cookieCardShape;

  /// Padding inside the cookie consent card content.
  /// Provides space inside the cookie consent card between its content and edges.
  final EdgeInsetsGeometry? cookieCardContentPadding;

  /// A handler for visiting the cookie policy URL.
  /// Allows users to navigate to a webpage for detailed cookie policies.
  final UrlHandler? visitCookiePolicy;

  /// A widget to display both permission and cookie consent layouts for the user.
  ///
  /// The `ConsentLayout` widget combines both permission and cookie consent layouts.
  /// It manages the permissions and cookie consent together in one widget.
  /// This allows the app to handle both the user permission requests and cookie preferences in a single layout.
  const ConsentLayout({
    required this.child,
    required this.cookie,
    required this.isWeb,
    required this.onCookieRejected,
    required this.onCookieAccepted,
    required this.isPermissionGranted,
    required this.sdk,
    required this.requestPermissionAccess,
    this.onPermissionGranted,
    this.name = "Hapnium",
    required this.permissionImage,
    required this.permissions,
    this.permissionCardColor,
    this.permissionTextColor,
    this.permissionImageWidth,
    this.permissionImageHeight = 200,
    this.permissionButtonWidth,
    this.permissionCardWidth = 440,
    this.permissionLeftCardPlacement,
    this.permissionLeftResizedCardPlacement = 6,
    this.permissionBottomCardPlacement = 10,
    this.permissionRightCardPlacement = 16,
    this.permissionRightResizedCardPlacement = 6,
    this.cookieCardColor,
    this.cookieTextColor,
    this.cookieButtonWidth,
    this.cookieCardWidth = 540,
    this.cookieLeftCardPlacement,
    this.cookieLeftResizedCardPlacement = 6,
    this.cookieBottomCardPlacement = 10,
    this.cookieRightCardPlacement = 16,
    this.cookieRightResizedCardPlacement = 6,
    this.permissionCardElevation = 4,
    this.cookieCardElevation = 4,
    this.permissionCardShape,
    this.cookieCardShape,
    this.permissionCardContentPadding,
    this.cookieCardContentPadding,
    this.permissionButtonColor,
    this.permissionButtonTextColor,
    this.cookieAcceptButtonColor,
    this.cookieAcceptButtonTextColor,
    this.cookieRejectButtonColor,
    this.cookieRejectButtonTextColor,
    this.cookieSettingsButtonColor,
    this.cookieSettingsButtonTextColor,
    this.cookieHintColor,
    this.visitCookiePolicy
  });

  @override
  Widget build(BuildContext context) {
    return PermissionConsentLayout(
      isGranted: isPermissionGranted,
      isWeb: isWeb,
      sdk: sdk,
      requestAccess: requestPermissionAccess,
      image: permissionImage,
      permissions: permissions,
      name: name,
      cardColor: permissionCardColor,
      textColor: permissionTextColor,
      imageWidth: permissionImageWidth,
      imageHeight: permissionImageHeight,
      buttonWidth: permissionButtonWidth,
      cardWidth: permissionCardWidth,
      bottomCardPlacement: permissionBottomCardPlacement,
      leftCardPlacement: permissionLeftCardPlacement,
      leftResizedCardPlacement: permissionLeftResizedCardPlacement,
      rightCardPlacement: permissionRightCardPlacement,
      rightResizedCardPlacement: permissionRightResizedCardPlacement,
      onPermissionGranted: onPermissionGranted,
      cardElevation: permissionCardElevation,
      cardShape: permissionCardShape,
      cardContentPadding: permissionCardContentPadding,
      child: CookieConsentLayout(
        child: child,
        cookie: cookie,
        isWeb: isWeb,
        onCookieRejected: onCookieRejected,
        onCookieAccepted: onCookieAccepted,
        cardColor: cookieCardColor,
        textColor: cookieTextColor,
        buttonWidth: cookieButtonWidth,
        cardWidth: cookieCardWidth,
        bottomCardPlacement: cookieBottomCardPlacement,
        leftCardPlacement: cookieLeftCardPlacement,
        leftResizedCardPlacement: cookieLeftResizedCardPlacement,
        rightCardPlacement: cookieRightCardPlacement,
        rightResizedCardPlacement: cookieRightResizedCardPlacement,
        cardElevation: cookieCardElevation,
        cardShape: cookieCardShape,
        cardContentPadding: cookieCardContentPadding,
        visitCookiePolicy: visitCookiePolicy,
        acceptButtonColor: cookieAcceptButtonColor,
        acceptButtonTextColor: cookieAcceptButtonTextColor,
        rejectButtonColor: cookieRejectButtonColor,
        rejectButtonTextColor: cookieRejectButtonTextColor,
        settingsButtonColor: cookieSettingsButtonColor,
        settingsButtonTextColor: cookieSettingsButtonTextColor,
        hintColor: cookieHintColor,
      ),
    );
  }
}