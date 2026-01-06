import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:smart/enums.dart';
import 'package:smart/extensions.dart';
import 'package:hapnium/hapnium.dart';
import 'package:smart/src/assets/social_assets.dart';
import 'package:smart/ui.dart';

import './domain_app_link.dart';

/// {@template link_utils}
/// A collection of links relevant to the Hapnium platform.
///
/// This class provides access to various URLs, including the base URL for the
/// platform, links to legal documents, and links to the Hapnium apps for
/// different user types (Nearby, User, Provider, Business).
/// 
/// {@endtemplate}
class LinkUtils {
  LinkUtils._();

  /// Singleton instance of [LinkUtils].
  /// 
  /// {@macro link_utils}
  static final LinkUtils instance = LinkUtils._();

  /// The domain used for building Hapnium URLs.
  final String _domain = "hapnium";

  /// Constructs a URL based on an alias.
  String _urlBuilder(String alias) => "https://$alias.$_domain.com";

  /// Constructs a Play Store URL for a given package name.
  String _playStoreBaseUrl(String packageName) => "https://play.google.com/store/apps/details?id=com.$_domain.$packageName";

  /// The base URL for the Hapnium platform.
  String get baseUrl => _urlBuilder("www");

  /// Constructs an email address for a given alias.
  String _emailAddress(String alias) => "$alias@hapnium.com";

  /// The endpoint for the community guidelines.
  ///
  /// This URL provides access to the legal community guidelines for the platform.
  String get communityGuidelines => "$baseUrl/hub/legal/community-guidelines";

  /// The endpoint for the non-discrimination policy.
  ///
  /// This URL provides access to the legal non-discrimination policy.
  String get nonDiscriminationPolicy => "$baseUrl/hub/legal/non-discrimination-policy";

  /// The endpoint for the privacy policy.
  ///
  /// This URL provides access to the privacy policy of the platform.
  String get privacyPolicy => "$baseUrl/hub/legal/privacy-policy";

  /// The endpoint for the cookie policy.
  ///
  /// This URL provides access to the cookie policy of the platform.
  String get cookiePolicy => "$baseUrl/hub/legal/cookie-policy";

  /// The endpoint for terms and conditions.
  ///
  /// This URL provides access to the platform's terms and conditions.
  String get termsAndConditions => "$baseUrl/hub/legal/terms-and-conditions";

  /// The endpoint for the zero-tolerance policy.
  ///
  /// This URL provides access to the zero-tolerance policy of the platform.
  String get zeroTolerancePolicy => "$baseUrl/hub/legal/zero-tolerance-policy";

  /// The endpoint for the business category.
  ///
  /// This URL provides access to the business category of the platform.
  String get businessCategory => "$baseUrl/business";

  /// The endpoint for the associate category.
  ///
  /// This URL provides access to the associate category of the platform.
  String get associateCategory => "$baseUrl/provider/associate";

  /// The endpoint for the provider category.
  ///
  /// This URL provides access to the provider category of the platform.
  String get providerCategory => "$baseUrl/provider";

  /// The endpoint for the user category.
  ///
  /// This URL provides access to the user category of the platform.
  String get userCategory => "$baseUrl/user";

  /// The endpoint for the nearby category.
  ///
  /// This URL provides access to the nearby category of the platform.
  String get nearbyCategory => "$baseUrl/nearby";

  /// Links to the Hapnium Nearby app for different platforms.
  /// 
  /// {@macro domain_app_link}
  DomainAppLink get nearby => DomainAppLink(
    web: _urlBuilder("nearby"),
    android: _playStoreBaseUrl('drive'),
    ios: "",
  );

  /// Links to the Hapnium User app for different platforms.
  /// 
  /// {@macro domain_app_link}
  DomainAppLink get user => DomainAppLink(
    web: _urlBuilder('user'),
    android: _playStoreBaseUrl('user'),
    ios: "",
  );

  /// Links to the Hapnium Provider app for different platforms.
  /// 
  /// {@macro domain_app_link}
  DomainAppLink get provider => DomainAppLink(
    web: _urlBuilder('provider'),
    android: _playStoreBaseUrl('partner'),
    ios: "",
  );

  /// Links to the Hapnium Business app for different platforms.
  /// 
  /// {@macro domain_app_link}
  DomainAppLink get business => DomainAppLink(
    web: _urlBuilder('business'),
    android: _playStoreBaseUrl('enterprise'),
    ios: "",
  );

  /// The URL for the help center.
  String get helpCenter => _urlBuilder("help");

  /// The email address for account-related inquiries.
  String get accountEmailAddress => _emailAddress("account");

  /// The email address for team-related inquiries.
  String get teamEmailAddress => _emailAddress("team");

  /// The support phone number.
  String supportPhoneNumber = "+18445871030";

  /// The Safe-Guard community WhatsApp link.
  String safeGuardUrl = "https://chat.whatsapp.com/IPWEBQi7HRG7jJQiOWdcJT";

  /// This comprises of all the legal links Hapnium provides the user as a means of guidelines.
  List<ButtonView> get legalLinks => [
    ButtonView(
      header: "Community Guidelines",
      icon: Icons.people_rounded,
      path: communityGuidelines,
    ),
    ButtonView(
      header: "Non-Discrimination Policy",
      icon: Icons.warning_rounded,
      path: nonDiscriminationPolicy,
    ),
    ButtonView(
      header: "Privacy Policy",
      icon: Icons.privacy_tip_rounded,
      path: privacyPolicy,
    ),
    ButtonView(
      header: "Terms and Condition",
      icon: Icons.confirmation_number_rounded,
      path: termsAndConditions,
    ),
    ButtonView(
      header: "Zero Tolerance Policy",
      icon: Icons.not_interested_rounded,
      path: zeroTolerancePolicy,
    ),
  ];

  /// A list of help and support options.
  List<ButtonView> helpAndSupport({
    bool showSafeGuard = false,
    String? emailAddress,
    String? supportPhoneNumber,
    String? safeGuardUrl,
    String? helpCenter,
  }) => [
    ButtonView(
      header: "Mail",
      body: "Send us an email when it is your best option.",
      icon: CupertinoIcons.bubble_left_bubble_right_fill,
      path: emailAddress ?? accountEmailAddress,
      index: 0
    ),
    ButtonView(
      header: "Call us",
      body: "Get all the help you need with a live assistant.",
      icon: CupertinoIcons.phone_circle,
      path: supportPhoneNumber ?? this.supportPhoneNumber,
      index: 1
    ),
    if(showSafeGuard) ...[
      ButtonView(
        header: "Safe-Guard Community",
        body: "Join Hapnium SG Community and help us improve our safety measures.",
        image: SmartSocialAssets.whatsapp,
        path: safeGuardUrl ?? this.safeGuardUrl,
        index: 2
      )
    ],
    ButtonView(
      header: "Visit help center",
      body: "Browse our help documentation to find possible solutions",
      image: SmartSocialAssets.asterisk,
      path: helpCenter ?? this.helpCenter,
      index: 3
    ),
  ];

  /// A list of account-related support options.
  List<ButtonView> get accountIssue => [
    ButtonView(
      header: "Hapnium Community Guidelines",
      body: "Understand the community you thrive in.",
      icon: Icons.rule_rounded,
      index: 0,
      path: communityGuidelines
    ),
    ButtonView(
      header: "Hapnium Non-Discrimination Policy",
      body: "Read our policy to avoid issues.",
      icon: Icons.polymer_sharp,
      index: 1,
      path: nonDiscriminationPolicy
    ),
    ButtonView(
      header: "Start account recovery process",
      index: 2,
      body: "Speak to the team to recover your account.",
      icon: Icons.send_time_extension_rounded,
      path: teamEmailAddress
    ),
  ];

  /// A list of social media link options.
  List<ButtonView> media({String? domain}) {
    domain ??= _domain;

    return [
      ButtonView(header: "LinkedIn", image: SmartSocialAssets.linkedin, path: "https://www.linkedin.com/company/$domain"),
      ButtonView(header: "Instagram", image: SmartSocialAssets.instagram, path: "https://www.instagram.com/$domain"),
      ButtonView(header: "X", image: SmartSocialAssets.twitter, path: "https://www.x.com/$domain"),
      ButtonView(header: "YouTube", image: SmartSocialAssets.youtube, path: "https://www.youtube.com/@$domain"),
      ButtonView(header: "TikTok", image: SmartSocialAssets.tiktok, path: "https://www.tiktok.com/@$domain"),
    ];
  }

  /// List of support when a platform error occurs
  List<ButtonView> platformErrorSupport({
    bool showWebApp = false,
    required SmartApp app,
    String? helpCenter,
    String? teamEmailAddress,
    String? baseUrl,
  }) => [
    ButtonView(
      header: "Hapnium Help Center",
      body: "Learn why you might be getting platform error.",
      icon: Icons.rule_rounded,
      index: 0,
      path: helpCenter ?? this.helpCenter
    ),
    ButtonView(
      header: "Reach out to the team",
      body: "Let the team know if this is an abnormal behaviour.",
      icon: Icons.polymer_sharp,
      index: 1,
      path: teamEmailAddress ?? this.teamEmailAddress
    ),
    if(showWebApp.isFalse) ...[
      ButtonView(
        header: "Head to www.hapnium.com",
        body: "Understand more about Hapnium and why we value safety.",
        icon: Icons.web_stories,
        index: 2,
        path: baseUrl ?? this.baseUrl
      ),
    ] else ...[
      ButtonView(
        header: "Check out ${app.type} on web",
        body: "Try it out in the browser.",
        icon: Icons.open_in_browser_rounded,
        index: 3,
        path: app.isBusiness ? business.web : app.isProvider ? provider.web : app.isUser ? user.web : nearby.web,
      ),
    ]
  ];
}