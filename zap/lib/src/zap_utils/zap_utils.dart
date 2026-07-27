import 'package:flutter/foundation.dart' show Uint8List;

import '../core/zap_inst.dart';
import '../definitions.dart';
import '../models/location/location_information.dart';
import '../models/zap_config.dart';
import '../http/utils/http_status.dart';
import '../core/zap.dart';
import '../core/zap_interface.dart';

/// {@template zap_utils}
/// A centralized singleton facade providing utility methods for common third-party 
/// API integrations (Geolocation, Distance Matrix, IP Resolution, and Binary Asset fetching).
///
/// **Architectural Context:**
/// Modern applications frequently need to communicate with external services outside 
/// of their primary backend (e.g., Google Maps, OpenStreetMap, Ipify). Instead of 
/// littering the presentation or domain layers with raw HTTP calls and ad-hoc 
/// configurations, [ZapUtils] encapsulates these operations. 
/// 
/// It utilizes an isolated [ZapClient] configured specifically for external, 
/// potentially slow third-party APIs (featuring extended 30-second timeouts and 
/// automated redirect following) while ensuring unified error handling and logging.
/// {@endtemplate}
final class ZapUtils {
  /// {@macro zap_utils}
  /// 
  /// The internal singleton instance.
  static final ZapUtils _instance = ZapUtils._internal();

  /// Private constructor enforcing the singleton pattern.
  ZapUtils._internal();

  /// Access point for the [ZapUtils] singleton.
  /// 
  /// **Usage:**
  /// ```dart
  /// final ip = await ZapUtils.instance.fetchIpAddress();
  /// ```
  static ZapUtils get instance => _instance;
  
  /// Generates a [ZapInterface] tailored for external utility requests.
  /// 
  /// **Configuration Notes:**
  /// - Extended `timeout` (30 seconds) accommodates slow 3rd-party APIs.
  /// - `followRedirects` is enabled, as public CDNs (for images) and mapping APIs 
  ///   frequently utilize `301/302` redirects for load balancing.
  ZapInterface get _client => Zap(
    zapConfig: ZapConfig(
      timeout: const Duration(seconds: 30),
      followRedirects: true,
      maxRedirects: 3,
    ),
  );

  /// Resolves the current public IPv4 address of the device.
  ///
  /// **Architectural Use Case:**
  /// Useful for audit logging, fraud prevention (detecting unexpected geo-hops), 
  /// or providing localized defaults before full GPS permissions are granted.
  /// 
  /// This method queries the `api64.ipify.org` service. It is designed to fail 
  /// gracefully: if the network is down or the API is unreachable, it swallows 
  /// the exception and returns an empty string, preventing app crashes.
  ///
  /// - [log]: If `true`, network failures are printed to the console.
  ///
  /// ### Returns:
  /// A `Future<String>` containing the IP (e.g., `"192.168.1.1"`), or `""` on failure.
  Future<String> fetchIpAddress([bool log = true]) async {
    try {
      final response = await _client.get<Map<String, dynamic>>(
        "https://api64.ipify.org?format=json",
        decoder: (data) => data as Map<String, dynamic>,
      );

      if (response.status == HttpStatus.OK && response.body?['ip'] != null) {
        return response.body!['ip'] as String;
      }
    } catch (e) {
      if (log) {
        Z.log('ZapUtils: Failed to fetch IP address - $e');
      }
    }

    return "";
  }

  /// Downloads raw binary image data from a remote [url] via a callback-driven flow.
  ///
  /// **Use Case:**
  /// Ideal for legacy integration patterns or reactive streams where `onSuccess` 
  /// and `onError` callbacks are preferred over `async/await` Futures. Useful 
  /// when caching images to the local file system or passing raw bytes to a 
  /// native platform channel.
  ///
  /// ### Parameters:
  /// - [url]: The absolute URL of the image asset.
  /// - [onSuccess]: Triggered with the raw `Uint8List` byte array upon HTTP 200.
  /// - [onError]: Triggered with a descriptive string if the network, decoding, 
  ///   or HTTP status fails.
  /// - [log]: If `true`, exceptions are piped to the console logger.
  Future<void> fetchImageData({
    required String url,
    required Function(Uint8List) onSuccess,
    required Function(String) onError,
    bool log = true,
  }) async {
    try {
      final response = await _client.get<BodyBytes>(
        url,
        decoder: (data) {
          if (data is BodyBytes) {
            return data;
          } else if (data is String) {
            // Defensive fallback: The server might incorrectly return an image 
            // payload as a Base64 string or raw string stream instead of binary bytes.
            return data.codeUnits;
          }
          throw Exception('Unexpected response type for image data');
        },
      );

      if (response.status == HttpStatus.OK && response.body != null) {
        Uint8List imageData = Uint8List.fromList(response.body!);
        onSuccess.call(imageData);
      } else {
        onError.call('Failed to fetch image data: HTTP ${response.status}');
      }
    } catch (error) {
      if (log) {
        Z.log('ZapUtils: Error fetching image: $error');
      }
      onError.call('Error fetching image: $error');
    }
  }

  /// Downloads raw binary image data from a remote [url] via modern `async/await`.
  ///
  /// **Architectural Use Case:**
  /// The preferred modern alternative to [fetchImageData]. It returns a nullable 
  /// `Uint8List?`, allowing the caller to handle failures cleanly using standard 
  /// control flow (e.g., displaying a local placeholder asset if this returns null).
  ///
  /// - [url]: The absolute URL of the image asset.
  /// - [log]: If `true`, network/decoding exceptions are logged.
  /// 
  /// ### Returns:
  /// The binary image data, or `null` if the request fails or times out.
  Future<Uint8List?> fetchImageDataAsync(String url, [bool log = true]) async {
    try {
      final response = await _client.get<BodyBytes>(
        url,
        decoder: (data) {
          if (data is BodyBytes) {
            return data;
          } else if (data is String) {
            return data.codeUnits;
          }
          throw Exception('Unexpected response type for image data');
        },
      );

      if (response.status == HttpStatus.OK && response.body != null) {
        return Uint8List.fromList(response.body!);
      }
    } catch (e) {
      if (log) {
        Z.log('ZapUtils: Failed to fetch image data - $e');
      }
    }
    return null;
  }

  /// Calculates the routing distance and estimated travel time between two coordinates.
  ///
  /// **External Dependency:** 
  /// Queries the Google Maps Distance Matrix API. This requires a highly privileged, 
  /// billing-enabled [googleMapApiKey].
  /// 
  /// **Note on Units:**
  /// This method is hardcoded to request `'imperial'` units (miles/feet). The 
  /// returned JSON elements will reflect this metric system.
  ///
  /// ### Returns:
  /// A `Future<List<dynamic>>` containing the routing `elements` array from the 
  /// Google Maps response. This typically contains `distance` (text/value) and 
  /// `duration` (text/value) objects.
  ///
  /// ### Throws:
  /// Explicitly throws an [Exception] if the network drops, the API key is invalid 
  /// (`REQUEST_DENIED`), or if no routable path exists between the coordinates.
  Future<List<dynamic>> getTotalDistanceAndTime({
    required double originLatitude,
    required double originLongitude,
    required double destinationLatitude,
    required double destinationLongitude,
    required String googleMapApiKey,
    bool log = true,
  }) async {
    String origin = "$originLatitude,$originLongitude";
    String destinations = "$destinationLatitude,$destinationLongitude";

    final queryParams = {
      'units': 'imperial', // Hardcoded to Imperial (Miles)
      'origins': origin,
      'destinations': destinations,
      'key': googleMapApiKey,
    };

    try {
      final response = await _client.get<Map<String, dynamic>>(
        "https://maps.googleapis.com/maps/api/distancematrix/json",
        query: queryParams,
        decoder: (data) => data as Map<String, dynamic>,
      );

      if (response.status == HttpStatus.OK && response.body != null) {
        final responseData = response.body!;
        
        if (responseData['status'] != 'OK') {
          throw Exception('Google Maps API error: ${responseData['status']}');
        }

        final rows = responseData['rows'] as List<dynamic>;
        if (rows.isNotEmpty) {
          final elements = rows[0]['elements'] as List<dynamic>;
          return elements;
        } else {
          throw Exception('No route data found in response');
        }
      } else {
        throw Exception('HTTP ${response.status}: Failed to fetch distance data');
      }
    } catch (e) {
      if (log) {
        Z.log('ZapUtils: Error calculating distance and time: $e');
      }
      throw Exception('Error calculating distance and time: $e');
    }
  }

  /// Performs a reverse-geocode to convert raw GPS coordinates into a human-readable address.
  ///
  /// **External Dependency:**
  /// Queries the OpenStreetMap (OSM) Nominatim API. 
  /// 
  /// **Compliance Note:**
  /// Nominatim heavily enforces a strict Acceptable Use Policy. This method explicitly 
  /// injects a `User-Agent: ZapUtils/1.0` header to comply with their requirement 
  /// that all requests identify the client application.
  ///
  /// **Defensive Fallback:**
  /// Reverse-geocoding is prone to failure (e.g., device offline, API rate limits hit). 
  /// Instead of throwing an error or returning null, this method intercepts failures 
  /// and returns a fallback `LocationInformation` object constructed solely from the 
  /// provided latitude and longitude. This ensures the UI always has a non-null 
  /// location object to render.
  ///
  /// ### Parameters:
  /// - [latitude]: The mathematical latitude (e.g., `6.1481`).
  /// - [longitude]: The mathematical longitude (e.g., `6.7845`).
  /// - [log]: Flags whether network/parsing failures should be printed to the console.
  Future<LocationInformation> getLocationInformation(double latitude, double longitude, [bool log = true]) async {
    try {
      final queryParams = {
        'lat': latitude.toString(),
        'lon': longitude.toString(),
        'format': 'json',
      };

      // Mandatory compliance header for the Nominatim OSM API
      final headers = {
        'User-Agent': 'ZapUtils/1.0',
      };

      final response = await _client.get<Map<String, dynamic>>(
        "https://nominatim.openstreetmap.org/reverse",
        query: queryParams,
        headers: headers,
        decoder: (data) => data as Map<String, dynamic>,
      );

      if (response.status == HttpStatus.OK && response.body != null) {
        return LocationInformation.fromJson(response.body!);
      } else {
        if (log) {
          Z.log('ZapUtils: Failed to fetch location information - HTTP ${response.status}');
        }
      }
    } catch (e) {
      if (log) {
        Z.log('ZapUtils: Error fetching location information - $e');
      }
    }

    // Graceful degradation: Return an empty but structurally valid location object
    return LocationInformation.fromLatLng(latitude, longitude);
  }

  /// Disposes the underlying Zap HTTP client, severing any open socket connections.
  /// 
  /// **Architectural Note:** 
  /// Because [ZapUtils] is a singleton, calling `dispose()` is rarely required 
  /// during normal app execution. It is primarily useful during complete app 
  /// teardown or within test suites to ensure garbage collection of network ports.
  void dispose() {
    _client.dispose();
  }
}