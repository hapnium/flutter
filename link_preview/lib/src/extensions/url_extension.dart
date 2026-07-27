import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../link_preview_interface.dart';

/// {@template url_extension}
/// Extension on [LinkPreviewInterface] to provide URL utilities and validation.
///
/// This extension offers methods for URL resolution, validation, SVG handling,
/// and other URL-related operations commonly needed in link preview functionality.
///
/// ### Common actions
///
/// - Resolve relative URLs: `linkPreview.resolveUrl(base, proxy, image)`
/// - Validate URLs: `linkPreview.isValidUrl(url)`
/// - Validate links with options: `linkPreview.isValidLink(url)`
/// - Check SVG validity: `linkPreview.isValidSvg(svgString)`
///
/// ### Usage
///
/// ```dart
/// // Resolve a relative image URL
/// final resolved = linkPreview.resolveUrl(
///   'https://example.com',
///   'https://proxy.example.com',
///   '/images/logo.png',
/// );
///
/// // Validate a URL
/// if (linkPreview.isValidUrl('https://example.com')) {
///   // URL is valid
/// }
/// ```
/// {@endtemplate}
extension UrlExtension on LinkPreviewInterface {
  /// {@template url_extension_resolve_url}
  /// Resolves a relative image URL with a base URL and a proxy URL.
  ///
  /// Combines the base URL, relative image URL, and proxy URL to create
  /// a fully resolved URL. If resolution fails, returns the original image URL.
  ///
  /// ### Parameters
  ///
  /// - [baseUrl]: The base URL for resolving relative URLs. Must be a
  ///   valid URI string (e.g., `'https://example.com'`).
  /// - [proxyUrl]: The proxy URL to prepend to the resolved URL. Must be
  ///   a valid URI string (e.g., `'https://proxy.example.com'`).
  /// - [imageUrl]: The relative image URL to resolve. Can be relative
  ///   (e.g., `'/images/logo.png'`) or absolute.
  ///
  /// ### Return value
  ///
  /// Returns a [String] — the fully resolved URL combining proxy, base,
  /// and image URLs. Returns the original [imageUrl] if resolution fails.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final resolved = linkPreview.resolveUrl(
  ///   'https://example.com',
  ///   'https://proxy.example.com',
  ///   '/images/logo.png',
  /// );
  /// // Returns 'https://proxy.example.com/https://example.com/images/logo.png'
  /// ```
  ///
  /// ```dart
  /// // Fallback on error
  /// final resolved = linkPreview.resolveUrl(
  ///   'not a valid url',
  ///   'https://proxy.example.com',
  ///   '/images/logo.png',
  /// );
  /// // Returns '/images/logo.png' (original imageUrl)
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Prepend a proxy to image URLs for CORS bypass
  /// - Resolve relative image paths from HTML documents
  /// - Handle malformed URLs gracefully
  ///
  /// ### Edge cases
  ///
  /// - If [baseUrl] is invalid, returns [imageUrl] unchanged
  /// - If [proxyUrl] is invalid, returns [imageUrl] unchanged
  /// - If [imageUrl] is already absolute, it is still resolved against [baseUrl]
  /// - The proxy URL wraps the resolved URL as a nested URI
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Use in image loading to bypass CORS
  /// final imageUrl = linkPreview.resolveUrl(
  ///   pageUrl,
  ///   'https://cors-proxy.example.com',
  ///   relativeImagePath,
  /// );
  /// ```
  /// {@endtemplate}
  String resolveUrl(String baseUrl, String proxyUrl, String imageUrl) {
    try {
      // Parse the base and proxy URLs
      final baseUri = Uri.parse(baseUrl);
      final proxyUri = Uri.parse(proxyUrl);

      // Resolve the relative image URL with the base URL
      final resolvedUri = baseUri.resolve(imageUrl);

      // Combine the proxy URL with the resolved URI
      return proxyUri.resolve(resolvedUri.toString()).toString();
    } catch (e) {
      // Return the original image URL if resolution fails
      return imageUrl;
    }
  }

  /// {@template url_extension_extract_svg_content}
  /// Extracts and decodes SVG content from a Base64-encoded data URI.
  ///
  /// Handles both Base64-encoded and URL-encoded SVG data URIs.
  /// Returns null if decoding fails.
  ///
  /// ### Parameters
  ///
  /// - [data]: The data URI string containing SVG data. Expected formats:
  ///   - `'data:image/svg+xml;base64,...'` (Base64-encoded)
  ///   - `'data:image/svg+xml,...'` (URL-encoded)
  ///
  /// ### Return value
  ///
  /// Returns a [String?] — the decoded SVG content as a string,
  /// or `null` if decoding fails.
  ///
  /// ### Example
  ///
  /// ```dart
  /// final svgContent = linkPreview.extractSvgContent(
  ///   'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDov...',
  /// );
  /// // Returns '<svg xmlns="http://www.w3.org/2000/svg">...</svg>'
  /// ```
  ///
  /// ```dart
  /// final svgContent = linkPreview.extractSvgContent(
  ///   'data:image/svg+xml,%3Csvg%20xmlns%3D...',
  /// );
  /// // Returns decoded SVG string
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Decode inline SVG data URIs from HTML
  /// - Extract SVG content for rendering or validation
  ///
  /// ### Edge cases
  ///
  /// - Returns `null` if the data URI format is invalid
  /// - Returns `null` if Base64 decoding fails
  /// - On web, uses [Uri.decodeComponent]; on native, uses [Uri.decodeFull]
  /// - Logs the error to debug console on failure
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final svgData = 'data:image/svg+xml;base64,...';
  /// final content = linkPreview.extractSvgContent(svgData);
  /// if (content != null) {
  ///   // Parse or render the SVG content
  /// }
  /// ```
  /// {@endtemplate}
  String? extractSvgContent(String data) {
    try {
      if (data.contains('base64,')) {
        final base64String = data.substring(data.indexOf('base64,') + 7);
        return utf8.decode(base64.decode(base64String));
      } else {
        return kIsWeb
            ? Uri.decodeComponent(data.substring('data:image/svg+xml,'.length))
            : Uri.decodeFull(data.substring('data:image/svg+xml,'.length));
      }
    } catch (e) {
      debugPrint('Failed to decode SVG content -> $e');
      return null;
    }
  }

  /// {@template url_extension_is_valid_url}
  /// Checks if a URL is valid.
  ///
  /// Uses [Uri.tryParse] to validate the URL format and checks if
  /// the parsed URI has an absolute path. This is a lightweight
  /// validation that does not check DNS resolution or reachability.
  ///
  /// ### Parameters
  ///
  /// - [url]: The URL string to validate.
  ///
  /// ### Return value
  ///
  /// Returns `true` if the URL is valid and has an absolute path,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isValidUrl('https://example.com'); // true
  /// linkPreview.isValidUrl('not-a-url'); // false
  /// linkPreview.isValidUrl(''); // false
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Validate user-input URLs before fetching
  /// - Check URL format in forms or input fields
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` for empty strings
  /// - Returns `false` for strings that cannot be parsed as URIs
  /// - Does not check if the URL is reachable (network validation)
  /// - Accepts any scheme (http, https, ftp, file, etc.)
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (linkPreview.isValidUrl(userInput)) {
  ///   // Proceed with fetching preview data
  /// }
  /// ```
  /// {@endtemplate}
  bool isValidUrl(String url) {
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasAbsolutePath;
  }

  /// {@template url_extension_is_svg_data_uri}
  /// Checks if the input is a Base64-encoded SVG data URI.
  ///
  /// Performs a simple string contains check for the SVG data URI
  /// prefix. Does not validate the actual SVG content.
  ///
  /// ### Parameters
  ///
  /// - [data]: The data URI string to check.
  ///
  /// ### Return value
  ///
  /// Returns `true` if the string contains `'data:image/svg+xml'`,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isSvgDataUri('data:image/svg+xml;base64,...'); // true
  /// linkPreview.isSvgDataUri('data:image/png;base64,...'); // false
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Identify SVG data URIs before decoding
  /// - Route SVG data to appropriate handling logic
  ///
  /// ### Edge cases
  ///
  /// - Returns `true` even if the SVG data is malformed
  /// - Only checks for the prefix, not the actual content validity
  /// - Case-sensitive match
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (linkPreview.isSvgDataUri(imageUrl)) {
  ///   final content = linkPreview.extractSvgContent(imageUrl);
  ///   if (content != null && linkPreview.isValidSvg(content)) {
  ///     // Render SVG
  ///   }
  /// }
  /// ```
  /// {@endtemplate}
  bool isSvgDataUri(String data) {
    return data.contains('data:image/svg+xml');
  }

  /// {@template url_extension_is_valid_svg}
  /// Checks if the input is a valid SVG string.
  ///
  /// Parses the SVG string as XML, verifies the root element is 'svg',
  /// validates the viewBox attribute if present, and recursively checks
  /// for at least one graphical element.
  ///
  /// ### Parameters
  ///
  /// - [svgString]: The SVG string to validate. Must be valid XML.
  ///
  /// ### Return value
  ///
  /// Returns `true` if the SVG is valid with a proper structure,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isValidSvg('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><circle cx="50" cy="50" r="40"/></svg>'); // true
  /// linkPreview.isValidSvg('<div>Not an SVG</div>'); // false
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Validate SVG content before rendering
  /// - Ensure SVG has graphical elements
  /// - Verify viewBox attribute format
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` if the root element is not 'svg'
  /// - Returns `false` if the viewBox attribute has incorrect format
  /// - Returns `false` if no graphical elements (circle, rect, path, etc.) are found
  /// - Returns `false` for malformed XML
  /// - Returns `false` for empty SVGs without graphical content
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final svgContent = linkPreview.extractSvgContent(dataUri);
  /// if (svgContent != null && linkPreview.isValidSvg(svgContent)) {
  ///   // Safe to render the SVG
  /// }
  /// ```
  /// {@endtemplate}
  bool isValidSvg(String svgString) {
    try {
      final document = XmlDocument.parse(svgString);
      final svgElement = document.rootElement;

      // Check if root element is 'svg'
      if (svgElement.name.local != 'svg') {
        return false;
      }

      // Validate 'viewBox' attribute if necessary
      final viewBox = svgElement.getAttribute('viewBox');
      if (viewBox != null) {
        final parts = viewBox.split(RegExp(r'\s+'));
        if (parts.length != 4 || parts.any((v) => double.tryParse(v) == null)) {
          return false; // 'viewBox' is incorrectly specified
        }
      }

      // Recursively check for at least one graphical element
      return _containsGraphicContent(svgElement);
    } catch (e) {
      // XML parsing error or other exception
      return false;
    }
  }

  /// {@template url_extension_is_svg_and_valid}
  /// Checks if the image URL is a valid SVG data URI.
  ///
  /// Extracts SVG content from the data URI and validates it.
  /// This is a convenience method that combines [isSvgDataUri],
  /// [extractSvgContent], and [isValidSvg] into a single call.
  ///
  /// ### Parameters
  ///
  /// - [imageUrl]: The image URL to check. Can be a data URI or a regular URL.
  ///
  /// ### Return value
  ///
  /// Returns `true` if the URL is a valid SVG data URI with valid content,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// if (linkPreview.isSvgAndValid(svgDataUri)) {
  ///   // Safe to use as SVG image
  /// }
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Validate SVG data URIs before rendering
  /// - Determine if an image URL should be handled as SVG
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` if the URL is not a data URI
  /// - Returns `false` if the SVG content cannot be decoded
  /// - Returns `false` if the decoded SVG is invalid
  /// - Logs validation status to debug console
  ///
  /// ### Usage
  ///
  /// ```dart
  /// final imageUrl = metadata['image'];
  /// if (imageUrl != null && linkPreview.isSvgAndValid(imageUrl)) {
  ///   // Render as SVG
  /// } else {
  ///   // Use fallback image
  /// }
  /// ```
  /// {@endtemplate}
  bool isSvgAndValid(String imageUrl) {
    final svgContent = extractSvgContent(imageUrl);
    if (svgContent != null) {
      debugPrint('Valid SVG data found.');
      return isValidSvg(svgContent);
    }

    debugPrint('Invalid SVG data; using fallback image.');
    return false;
  }

  /// {@template url_extension_is_url}
  /// Checks if the string is a URL.
  ///
  /// Validates the URL against protocol, hash, query params, path,
  /// authentication, hostname, and other URL components. This is a
  /// comprehensive validation that checks multiple URL aspects.
  ///
  /// ### Parameters
  ///
  /// - [input]: The string to check. Can be `null`.
  /// - [options]: Optional validation options map. Supports:
  ///   - `'protocols'`: List of allowed protocols (default: `['http', 'https', 'ftp']`)
  ///   - `'require_tld'`: Whether to require a TLD (default: `true`)
  ///   - `'require_protocol'`: Whether to require a protocol (default: `false`)
  ///   - `'allow_underscores'`: Whether to allow underscores in domain (default: `false`)
  ///
  /// ### Return value
  ///
  /// Returns `true` if the string is a valid URL according to the options,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isURL('https://example.com'); // true
  /// linkPreview.isURL('example.com'); // true (protocol not required)
  /// linkPreview.isURL(null); // false
  /// linkPreview.isURL(''); // false
  /// ```
  ///
  /// ```dart
  /// // With custom options
  /// linkPreview.isURL(
  ///   'ftp://files.example.com',
  ///   {'protocols': ['http', 'https']},
  /// ); // false (ftp not allowed)
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Comprehensive URL validation
  /// - Check URL components (protocol, host, path, query, hash)
  /// - Validate authentication in URLs
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` for `null` or empty strings
  /// - Returns `false` for strings longer than 2083 characters
  /// - Returns `false` for `mailto:` URLs
  /// - Returns `false` if protocol is not in the allowed list
  /// - Returns `false` if hostname is not a valid IP, FQDN, or 'localhost'
  /// - Returns `false` if port is outside 1-65535 range
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Basic validation
  /// if (linkPreview.isURL(userInput)) {
  ///   // Valid URL
  /// }
  ///
  /// // Custom validation with options
  /// if (linkPreview.isURL(input, {
  ///   'protocols': ['https'],
  ///   'require_tld': false,
  /// })) {
  ///   // HTTPS-only validation
  /// }
  /// ```
  /// {@endtemplate}
  bool isURL(String? input, [Map<String, Object>? options]) {
    var str = input;
    if (str == null || str.isEmpty || str.length > 2083 || str.indexOf('mailto:') == 0) {
      return false;
    }

    final defaultUrlOptions = {
      'protocols': ['http', 'https', 'ftp'],
      'require_tld': true,
      'require_protocol': false,
      'allow_underscores': false,
    };

    options = _merge(options, defaultUrlOptions);

    // check protocol
    var split = str.split('://');
    if (split.length > 1) {
      final protocol = _shift(split);
      final protocols = options['protocols'] as List<String>;
      if (!protocols.contains(protocol)) {
        return false;
      }
    } else if (options['require_protocol'] == true) {
      return false;
    }
    str = split.join('://');

    // check hash
    split = str.split('#');
    str = _shift(split);
    final hash = split.join('#');
    if (hash.isNotEmpty && RegExp(r'\s').hasMatch(hash)) {
      return false;
    }

    // check query params
    split = str?.split('?') ?? [];
    str = _shift(split);
    final query = split.join('?');
    if (query != "" && RegExp(r'\s').hasMatch(query)) {
      return false;
    }

    // check path
    split = str?.split('/') ?? [];
    str = _shift(split);
    final path = split.join('/');
    if (path != "" && RegExp(r'\s').hasMatch(path)) {
      return false;
    }

    // check auth type urls
    split = str?.split('@') ?? [];
    if (split.length > 1) {
      final auth = _shift(split);
      if (auth != null && auth.contains(':')) {
        // final auth = auth.split(':');
        final parts = auth.split(':');
        final user = _shift(parts);
        if (user == null || !RegExp(r'^\S+$').hasMatch(user)) {
          return false;
        }
        final pass = parts.join(':');
        if (!RegExp(r'^\S*$').hasMatch(pass)) {
          return false;
        }
      }
    }

    // check hostname
    final hostname = split.join('@');
    split = hostname.split(':');
    final host = _shift(split);
    if (split.isNotEmpty) {
      final portStr = split.join(':');
      final port = int.tryParse(portStr, radix: 10);
      if (!RegExp(r'^[0-9]+$').hasMatch(portStr) ||
          port == null ||
          port <= 0 ||
          port > 65535) {
        return false;
      }
    }

    if (host == null || !isIP(host) && !isFQDN(host, options) && host != 'localhost') {
      return false;
    }

    return true;
  }

  /// {@template url_extension_is_ip}
  /// Checks if the string is an IP (version 4 or 6).
  ///
  /// Validates the string against IPv4 or IPv6 address formats.
  /// When no version is specified, checks against both formats.
  ///
  /// ### Parameters
  ///
  /// - [str]: The string to check.
  /// - [version]: Optional IP version — `'4'` for IPv4, `'6'` for IPv6,
  ///   or `null` to check both.
  ///
  /// ### Return value
  ///
  /// Returns `true` if the string is a valid IP address of the specified version,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isIP('192.168.1.1'); // true (IPv4)
  /// linkPreview.isIP('2001:db8::1'); // true (IPv6)
  /// linkPreview.isIP('192.168.1.1', '4'); // true (IPv4 only)
  /// linkPreview.isIP('192.168.1.1', '6'); // false (not IPv6)
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Validate IP addresses in URLs
  /// - Check if a host is an IP address
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` for empty strings
  /// - IPv4 validation checks each octet is 0-255
  /// - IPv6 validation uses regex pattern matching
  /// - Version parameter accepts both String and int types
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (linkPreview.isIP(host)) {
  ///   // Host is an IP address
  /// }
  /// ```
  /// {@endtemplate}
  bool isIP(String str, [Object? version]) {
    assert(version == null || version is String || version is int);
    version = version.toString();
    if (version == 'null') {
      return isIP(str, 4) || isIP(str, 6);
    } else if (version == '4') {
      if (!_ipv4Maybe.hasMatch(str)) {
        return false;
      }
      var parts = str.split('.');
      parts.sort((a, b) => int.parse(a) - int.parse(b));
      return int.parse(parts[3]) <= 255;
    }
    return version == '6' && _ipv6.hasMatch(str);
  }

  /// {@template url_extension_is_fqdn}
  /// Checks if the string is a fully qualified domain name (e.g., domain.com).
  ///
  /// Validates the domain name against FQDN rules including TLD validation
  /// and character restrictions.
  ///
  /// ### Parameters
  ///
  /// - [str]: The string to check.
  /// - [options]: Optional validation options map. Supports:
  ///   - `'require_tld'`: Whether to require a TLD (default: `true`)
  ///   - `'allow_underscores'`: Whether to allow underscores in domain (default: `false`)
  ///
  /// ### Return value
  ///
  /// Returns `true` if the string is a valid FQDN, `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isFQDN('example.com'); // true
  /// linkPreview.isFQDN('sub.example.com'); // true
  /// linkPreview.isFQDN('localhost'); // false (no TLD)
  /// linkPreview.isFQDN('example', {'require_tld': false}); // true
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Validate domain names in URLs
  /// - Check TLD validity
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` if TLD is missing and `require_tld` is true
  /// - Returns `false` if domain parts contain double underscores
  /// - Returns `false` if domain starts or ends with a hyphen
  /// - Returns `false` if domain contains triple hyphens (---)
  /// - TLD must be at least 2 characters and lowercase letters only
  ///
  /// ### Usage
  ///
  /// ```dart
  /// if (linkPreview.isFQDN(hostname)) {
  ///   // Valid fully qualified domain name
  /// }
  /// ```
  /// {@endtemplate}
  bool isFQDN(String str, [Map<String, Object>? options]) {
    final defaultFqdnOptions = {'require_tld': true, 'allow_underscores': false};

    options = _merge(options, defaultFqdnOptions);
    final parts = str.split('.');
    if (options['require_tld'] as bool) {
      var tld = parts.removeLast();
      if (parts.isEmpty || !RegExp(r'^[a-z]{2,}$').hasMatch(tld)) {
        return false;
      }
    }

    for (final part in parts) {
      if (options['allow_underscores'] as bool) {
        if (part.contains('__')) {
          return false;
        }
      }
      if (!RegExp(r'^[a-z\\u00a1-\\uffff0-9-]+$').hasMatch(part)) {
        return false;
      }
      if (part[0] == '-' ||
          part[part.length - 1] == '-' ||
          part.contains('---')) {
        return false;
      }
    }
    return true;
  }

  /// {@template url_extension_is_valid_link}
  /// Checks if the provided URL link is a valid link.
  ///
  /// Combines multiple validation options to check if a link is valid
  /// according to the specified protocols, host restrictions, and other settings.
  /// This is a higher-level convenience method that wraps [isURL] with
  /// named parameters for common validation scenarios.
  ///
  /// ### Parameters
  ///
  /// - [link]: The link string to validate. Must not be empty.
  /// - [protocols]: Allowed protocols. Defaults to `['http', 'https', 'ftp']`.
  /// - [hostWhitelist]: Optional list of allowed hosts. If non-empty,
  ///   only these hosts are allowed.
  /// - [hostBlacklist]: Optional list of disallowed hosts. If non-empty,
  ///   these hosts are rejected.
  /// - [requireTld]: Whether to require a TLD. Defaults to `true`.
  /// - [requireProtocol]: Whether to require a protocol. Defaults to `false`.
  /// - [allowUnderscore]: Whether to allow underscores in domain. Defaults to `false`.
  ///
  /// ### Return value
  ///
  /// Returns `true` if the link is valid according to the options,
  /// `false` otherwise.
  ///
  /// ### Example
  ///
  /// ```dart
  /// linkPreview.isValidLink('https://example.com'); // true
  /// linkPreview.isValidLink('ftp://files.example.com'); // true
  /// linkPreview.isValidLink('http://example.com', protocols: ['https']); // false
  /// ```
  ///
  /// ```dart
  /// // With host restrictions
  /// linkPreview.isValidLink(
  ///   'https://api.example.com',
  ///   hostWhitelist: ['api.example.com', 'cdn.example.com'],
  /// ); // true
  /// ```
  ///
  /// ### Common actions
  ///
  /// - Validate links with custom protocol restrictions
  /// - Apply host whitelisting or blacklisting
  /// - Validate links in user-generated content
  ///
  /// ### Edge cases
  ///
  /// - Returns `false` for empty strings
  /// - Returns `false` if protocol is not in the allowed list
  /// - Returns `false` if host is in the blacklist
  /// - Returns `false` if host is not in the whitelist (when whitelist is non-empty)
  /// - Empty whitelist/blacklist means no restrictions
  ///
  /// ### Usage
  ///
  /// ```dart
  /// // Validate external links
  /// if (linkPreview.isValidLink(userLink, protocols: ['https'])) {
  ///   // Safe to open
  /// }
  ///
  /// // Restrict to specific domains
  /// if (linkPreview.isValidLink(
  ///   url,
  ///   hostWhitelist: ['example.com', 'cdn.example.com'],
  /// )) {
  ///   // Safe to load
  /// }
  /// ```
  /// {@endtemplate}
  bool isValidLink(String link, {
    List<String> protocols = const ['http', 'https', 'ftp'],
    List<String> hostWhitelist = const [],
    List<String> hostBlacklist = const [],
    bool requireTld = true,
    bool requireProtocol = false,
    bool allowUnderscore = false,
  }) {
    if (link.isEmpty) return false;
    final options = <String, Object>{
      'require_tld': requireTld,
      'require_protocol': requireProtocol,
      'allow_underscores': allowUnderscore,
      // 'require_port': false,
      // 'require_valid_protocol': true,
      // 'allow_trailing_dot': false,
      // 'allow_protocol_relative_urls': false,
      // 'allow_fragments': true,
      // 'allow_query_components': true,
      // 'disallow_auth': false,
      // 'validate_length': true
    };
    if (protocols.isNotEmpty) options['protocols'] = protocols;
    if (hostWhitelist.isNotEmpty) options['host_whitelist'] = hostWhitelist;
    if (hostBlacklist.isNotEmpty) options['host_blacklist'] = hostBlacklist;

    return isURL(link, options);
  }
}

/// {@template contains_graphic_content}
/// Recursively checks if an XML node contains any graphical SVG elements.
///
/// Looks for elements like circle, ellipse, line, path, polygon, polyline,
/// rect, and text. Returns true if any such element is found.
///
/// ### Parameters
///
/// - [node]: The XML node to search recursively.
///
/// ### Return value
///
/// Returns `true` if any graphical element is found in the node tree,
/// `false` otherwise.
///
/// ### Example
///
/// ```dart
/// // Used internally by isValidSvg
/// final hasGraphics = _containsGraphicContent(svgElement);
/// ```
///
/// ### Edge cases
///
/// - Returns `false` for non-element nodes (text, comments)
/// - Returns `false` for empty SVGs
/// - Handles deeply nested SVG structures
/// {@endtemplate}
bool _containsGraphicContent(XmlNode node) {
  if (node is XmlElement) {
    // Check if the current element is a graphical element
    if ([
      'circle',
      'ellipse',
      'line',
      'path',
      'polygon',
      'polyline',
      'rect',
      'text',
    ].contains(node.name.local)) {
      return true;
    }

    // Recursively check child elements
    for (final child in node.children) {
      if (_containsGraphicContent(child)) {
        return true;
      }
    }
  }

  return false;
}

/// {@template shift}
/// Helper function to remove and return the first element from a list.
///
/// Returns null if the list is empty. Used internally for parsing
/// URL components by sequentially extracting parts.
///
/// ### Parameters
///
/// - [elements]: The list of strings to extract from. Modified in place.
///
/// ### Return value
///
/// Returns a [String?] — the first element of the list, or `null`
/// if the list is empty.
///
/// ### Example
///
/// ```dart
/// final parts = ['http', '://', 'example.com'];
/// final protocol = _shift(parts); // 'http'
/// // parts is now [':', 'example.com']
/// ```
///
/// ### Edge cases
///
/// - Returns `null` for empty lists
/// - Modifies the original list by removing the first element
/// {@endtemplate}
String? _shift(List<String> elements) {
  if (elements.isEmpty) return null;
  return elements.removeAt(0);
}

/// {@template merge}
/// Helper function to merge two maps, using defaults for missing keys.
///
/// If [obj] is null, returns [defaults]. Otherwise, adds missing keys
/// from [defaults] to [obj] without overwriting existing values.
///
/// ### Parameters
///
/// - [obj]: The options map to merge into. Can be `null`.
/// - [defaults]: The default values to use for missing keys.
///
/// ### Return value
///
/// Returns a [Map<String, Object>] — the merged map with all keys
/// from both maps present.
///
/// ### Example
///
/// ```dart
/// final options = {'require_tld': false};
/// final defaults = {'require_tld': true, 'require_protocol': false};
/// final merged = _merge(options, defaults);
/// // {'require_tld': false, 'require_protocol': false}
/// ```
///
/// ### Edge cases
///
/// - If [obj] is `null`, returns [defaults] unchanged
/// - Does not overwrite existing keys in [obj]
/// - Modifies the [obj] map in place
/// {@endtemplate}
Map<String, Object> _merge(Map<String, Object>? obj, Map<String, Object> defaults) {
  if (obj == null) {
    return defaults;
  }
  defaults.forEach((key, val) => obj.putIfAbsent(key, () => val));
  return obj;
}

/// {@template ipv4_regex}
/// Regular expression pattern for matching IPv4 addresses.
///
/// Matches patterns like '192.168.1.1' or '0.0.0.0'.
/// Each octet can be 1-3 digits.
///
/// ### Example patterns
///
/// - `'192.168.1.1'` — valid match
/// - `'0.0.0.0'` — valid match
/// - `'255.255.255.255'` — valid match
/// - `'999.999.999.999'` — matches regex but fails octet validation in [isIP]
/// {@endtemplate}
RegExp _ipv4Maybe = RegExp(r'^(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)\.(\d?\d?\d)$');

/// {@template ipv6_regex}
/// Regular expression pattern for matching IPv6 addresses.
///
/// Matches standard IPv6 formats including compressed forms with '::'.
///
/// ### Example patterns
///
/// - `'::1'` — valid match (loopback)
/// - `'2001:db8::1'` — valid match
/// - `'fe80::1%lo0'` — may match depending on regex support
/// - `'::ffff:192.168.1.1'` — valid match (IPv4-mapped)
/// {@endtemplate}
RegExp _ipv6 = RegExp(r'^::|^::1|^([a-fA-F0-9]{1,4}::?){1,7}([a-fA-F0-9]{1,4})$');