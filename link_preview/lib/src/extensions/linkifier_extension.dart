import 'package:linkify/linkify.dart' as linkify;

import '../link_preview_interface.dart';
import '../v1/url_linkifier.dart';

/// {@template linkifier_extension}
/// Extension on [LinkPreviewInterface] to provide linkification utilities
/// for parsing and identifying different types of links within text.
///
/// This extension provides instances of various linkifiers that can be
/// used to identify URLs, email addresses, phone numbers, and user tags
/// within text content. Each linkifier is returned as a fresh instance
/// on each access.
///
/// ### Common actions
///
/// - Identify URLs in text: `linkPreview.urlLinkifier`
/// - Identify emails in text: `linkPreview.emailLinkifier`
/// - Identify phone numbers: `linkPreview.phoneNumberLinkifier`
/// - Identify user tags: `linkPreview.userTagLinkifier`
///
/// ### Usage
///
/// ```dart
/// final linkifier = Linkify(
///   linkifiers: [
///     linkPreview.urlLinkifier,
///     linkPreview.emailLinkifier,
///   ],
/// );
/// final results = linkifier.linkify('Visit https://example.com or email test@example.com');
/// ```
/// {@endtemplate}
extension LinkifierExtension on LinkPreviewInterface {
  /// {@template linkifier_extension_custom_url_linkifier}
  /// Returns an instance of the custom URL linkifier.
  ///
  /// This is a custom implementation that may provide specialized
  /// URL detection behavior, potentially handling edge cases or
  /// URL formats that the standard [linkify.UrlLinkifier] does not support.
  ///
  /// ### Return value
  ///
  /// Returns a [UrlLinkifier] instance configured for custom URL detection.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final customLinkifier = linkPreview.customUrlLinkifier;
  /// final results = linkify('Check https://example.com', linkifiers: [customLinkifier]);
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Parse text with custom URL detection rules
  /// - Handle non-standard URL formats
  ///
  /// ### Edge cases
  ///
  /// - Returns a new instance on each access (not cached)
  /// - May behave differently from the standard [linkify.UrlLinkifier]
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Use when standard URL detection is insufficient
  /// final linkifier = linkPreview.customUrlLinkifier;
  /// final results = linkify.linkify(text, linkifiers: [linkifier]);
  /// ```
  /// {@endtemplate}
  UrlLinkifier get customUrlLinkifier => UrlLinkifier();

  /// {@template linkifier_extension_email_linkifier}
  /// Returns an instance of the email linkifier.
  ///
  /// This linkifier identifies email addresses within text and
  /// converts them into clickable links. It handles standard email
  /// formats including addresses with subdomains and special characters.
  ///
  /// ### Return value
  ///
  /// Returns a [linkify.EmailLinkifier] instance for email detection.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final emailLinkifier = linkPreview.emailLinkifier;
  /// final results = linkify('Contact us at support@example.com', linkifiers: [emailLinkifier]);
  /// // results[0].url == 'mailto:support@example.com'
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Identify email addresses in user-generated content
  /// - Convert email text into mailto: links
  ///
  /// ### Edge cases
  ///
  /// - Returns a new instance on each access
  /// - Does not validate whether the email actually exists
  /// - Handles emails with dots, hyphens, and plus signs in local part
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Extract and linkify emails
  /// final linkifier = linkPreview.emailLinkifier;
  /// final results = linkify.linkify(text, linkifiers: [linkifier]);
  /// for (final result in results) {
  ///   if (result is EmailElement) {
  ///     print('Found email: ${result.url}');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  linkify.EmailLinkifier get emailLinkifier => linkify.EmailLinkifier();

  /// {@template linkifier_extension_phone_number_linkifier}
  /// Returns an instance of the phone number linkifier.
  ///
  /// This linkifier identifies phone numbers within text and
  /// converts them into clickable links. It supports various
  /// international phone number formats.
  ///
  /// ### Return value
  ///
  /// Returns a [linkify.PhoneNumberLinkifier] instance for phone number detection.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final phoneLinkifier = linkPreview.phoneNumberLinkifier;
  /// final results = linkify('Call us at +1-555-123-4567', linkifiers: [phoneLinkifier]);
  /// // results[0].url == 'tel:+15551234567'
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Identify phone numbers in text content
  /// - Convert phone number text into tel: links
  ///
  /// ### Edge cases
  ///
  /// - Returns a new instance on each access
  /// - May not correctly identify all international formats
  /// - Does not validate whether the phone number is reachable
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Extract and linkify phone numbers
  /// final linkifier = linkPreview.phoneNumberLinkifier;
  /// final results = linkify.linkify(text, linkifiers: [linkifier]);
  /// for (final result in results) {
  ///   if (result is PhoneNumberElement) {
  ///     print('Found phone: ${result.url}');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  linkify.PhoneNumberLinkifier get phoneNumberLinkifier => linkify.PhoneNumberLinkifier();

  /// {@template linkifier_extension_user_tag_linkifier}
  /// Returns an instance of the user tag linkifier.
  ///
  /// This linkifier identifies user tags (e.g., @username) within text
  /// and converts them into clickable links. Common in social media
  /// and messaging applications.
  ///
  /// ### Return value
  ///
  /// Returns a [linkify.UserTagLinkifier] instance for user tag detection.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final tagLinkifier = linkPreview.userTagLinkifier;
  /// final results = linkify('Hello @john_doe!', linkifiers: [tagLinkifier]);
  /// // results[0].url == '@john_doe'
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Identify @mentions in text content
  /// - Convert user tags into profile links
  ///
  /// ### Edge cases
  ///
  /// - Returns a new instance on each access
  /// - Does not validate whether the user exists
  /// - Handles usernames with underscores, dots, and hyphens
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Extract and linkify user mentions
  /// final linkifier = linkPreview.userTagLinkifier;
  /// final results = linkify.linkify(text, linkifiers: [linkifier]);
  /// for (final result in results) {
  ///   if (result is UserTagElement) {
  ///     print('Found mention: ${result.value}');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  linkify.UserTagLinkifier get userTagLinkifier => linkify.UserTagLinkifier();

  /// {@template linkifier_extension_url_linkifier}
  /// Returns an instance of the standard URL linkifier.
  ///
  /// This linkifier identifies standard URLs within text and
  /// converts them into clickable links. It handles common URL
  /// formats including http, https, ftp, and other protocols.
  ///
  /// ### Return value
  ///
  /// Returns a [linkify.UrlLinkifier] instance for standard URL detection.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final urlLinkifier = linkPreview.urlLinkifier;
  /// final results = linkify('Visit https://example.com for more', linkifiers: [urlLinkifier]);
  /// // results[0].url == 'https://example.com'
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Identify URLs in text content
  /// - Convert URL text into clickable links
  ///
  /// ### Edge cases
  ///
  /// - Returns a new instance on each access
  /// - Does not validate whether the URL is reachable
  /// - Handles URLs with ports, paths, query strings, and fragments
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Extract and linkify URLs
  /// final linkifier = linkPreview.urlLinkifier;
  /// final results = linkify.linkify(text, linkifiers: [linkifier]);
  /// for (final result in results) {
  ///   if (result is UrlElement) {
  ///     print('Found URL: ${result.url}');
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  linkify.UrlLinkifier get urlLinkifier => linkify.UrlLinkifier();
}