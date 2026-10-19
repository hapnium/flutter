import 'dart:io' as io;

/// {@template io_cookie_jar}
/// A minimal, in-memory RFC 6265 cookie store for the dart:io HTTP engine.
///
/// dart:io's [io.HttpClient] exposes `Set-Cookie` headers and lets you attach
/// cookies to requests, but stores nothing and matches nothing by itself —
/// every major HTTP stack (browsers, OkHttp, `package:http` with `IOClient`
/// wrappers) performs this bookkeeping. Without a jar, server sessions built
/// on cookies silently break on every request after the first.
///
/// ### Matching (simplified RFC 6265 §5)
///
/// - **Domain**: host-only cookies (no `Domain` attribute) match their origin
///   host exactly; domain cookies match the origin and its subdomains. Cookies
///   whose `Domain` does not domain-match the origin are rejected (cookie
///   poisoning guard).
/// - **Path**: prefix match on path segment boundaries (`/api` matches
///   `/api/x` but not `/apiary`).
/// - **Secure**: `Secure` cookies are only sent over `https`.
/// - **Expiry**: expired cookies are dropped lazily on access; a `Set-Cookie`
///   that is already expired acts as a deletion directive.
///
/// The jar is in-memory only and scoped to one HTTP client instance — it is
/// not persisted to disk.
/// {@endtemplate}
class IoCookieJar {
  /// Stored cookies keyed by `name|domain|path` (the RFC 6265 storage key).
  final Map<String, _StoredCookie> _cookies = {};

  /// Stores cookies from a `Set-Cookie` response header set.
  ///
  /// Expired cookies act as deletion directives for an existing entry.
  void save(Uri url, List<io.Cookie> setCookies) {
    final originHost = url.host.toLowerCase();

    for (final cookie in setCookies) {
      final attrDomain = cookie.domain?.trim().toLowerCase().replaceFirst(RegExp(r'^\.'), '');
      final hostOnly = attrDomain == null || attrDomain.isEmpty;
      final domain = hostOnly ? originHost : attrDomain;

      // Reject cookies the server tried to plant on a foreign domain.
      if (!hostOnly && originHost != domain && !originHost.endsWith('.$domain')) {
        continue;
      }

      var path = cookie.path;
      if (path == null || path.isEmpty || !path.startsWith('/')) {
        path = _defaultPath(url.path);
      }

      final key = '${cookie.name}|$domain|$path';
      if (cookie.expires != null && cookie.expires!.isBefore(DateTime.now())) {
        _cookies.remove(key);
        continue;
      }

      _cookies[key] = _StoredCookie(
        name: cookie.name,
        value: cookie.value,
        domain: domain,
        hostOnly: hostOnly,
        path: path,
        secure: cookie.secure,
        expires: cookie.expires,
      );
    }
  }

  /// Returns the cookies that must be attached to a request to [url].
  List<io.Cookie> cookiesFor(Uri url) {
    final now = DateTime.now();
    _cookies.removeWhere((_, c) => c.expires != null && c.expires!.isBefore(now));

    final host = url.host.toLowerCase();
    final path = url.path.isEmpty ? '/' : url.path;

    return _cookies.values.where((c) {
      final domainOk = c.hostOnly
          ? host == c.domain
          : (host == c.domain || host.endsWith('.${c.domain}'));
      if (!domainOk) return false;
      if (!_pathMatches(path, c.path)) return false;
      if (c.secure && url.scheme != 'https') return false;
      return true;
    }).map((c) => io.Cookie(c.name, c.value)).toList();
  }

  /// Removes every stored cookie.
  void clear() => _cookies.clear();

  /// The number of cookies currently stored (test/introspection aid).
  int get length => _cookies.length;

  /// The default cookie path per RFC 6265 §5.1.4: the request path up to,
  /// but not including, the last `/`.
  String _defaultPath(String requestPath) {
    final index = requestPath.lastIndexOf('/');
    if (index <= 0) return '/';
    return requestPath.substring(0, index);
  }

  /// Path-match per RFC 6265 §5.1.4: exact match, `/` prefix, or segment
  /// boundary prefix (`/api` matches `/api/x`, not `/apiary`).
  bool _pathMatches(String requestPath, String cookiePath) {
    if (cookiePath == '/') return true;
    if (requestPath == cookiePath) return true;
    if (!requestPath.startsWith(cookiePath)) return false;
    return requestPath[cookiePath.length] == '/';
  }
}

/// Internal representation of a stored cookie with its normalization applied.
class _StoredCookie {
  const _StoredCookie({
    required this.name,
    required this.value,
    required this.domain,
    required this.hostOnly,
    required this.path,
    required this.secure,
    required this.expires,
  });

  final String name;
  final String value;

  /// The effective domain: the origin host for host-only cookies, or the
  /// normalized `Domain` attribute (leading dot stripped).
  final String domain;

  /// Whether the cookie was set without a `Domain` attribute and must only
  /// ever match the exact origin host.
  final bool hostOnly;

  final String path;
  final bool secure;
  final DateTime? expires;
}
