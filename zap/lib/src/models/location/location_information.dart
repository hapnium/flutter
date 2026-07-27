import 'location_data.dart';

/// {@template location_information}
/// A comprehensive Data Transfer Object (DTO) representing a resolved geographic 
/// location from a geocoding or reverse-geocoding service (e.g., OpenStreetMap / Nominatim).
///
/// **Architectural Context:**
/// While [LocationData] handles the microscopic details of a localized street address, 
/// [LocationInformation] represents the macroscopic geographic feature as a whole. 
/// It binds exact mathematical geography (coordinates and bounding boxes) together 
/// with search relevance metrics (importance, rank) and human-readable typography 
/// (names and formatted addresses).
///
/// This class is strictly designed to consume Nominatim/OSM payloads, featuring 
/// robust fallback parsing to handle the notorious inconsistencies of geospatial APIs.
///
/// ---
///
/// ### 🔍 Fields Overview:
/// | Field          | Description                                                   |
/// |----------------|---------------------------------------------------------------|
/// | [placeId]      | Internal geocoder ID (volatile).                              |
/// | [osmId]        | Global OpenStreetMap ID (stable).                             |
/// | [lat], [lon]   | Exact mathematical coordinates (kept as Strings for precision)|
/// | [highwayClass] | Primary geographic categorization.                            |
/// | [placeRank]    | Relevancy score for search ranking.                           |
/// | [address]      | The strictly typed, defensive [LocationData] object.          |
///
/// {@endtemplate}
class LocationInformation {
  /// The internal, unique identifier used by the specific geocoding server instance.
  /// 
  /// **Warning:** Unlike [osmId], this ID is volatile. If the Nominatim server 
  /// rebuilds its database, this ID will change. Do not use this as a long-term 
  /// primary key in your own database.
  final int placeId;

  /// The copyright or attribution string mandated by the data provider.
  /// 
  /// Example: `"Data © OpenStreetMap contributors, ODbL 1.0"`. It is often legally 
  /// required to display this in your UI if you are using open-source mapping data.
  final String licence;

  /// The architectural type of the OpenStreetMap object.
  /// 
  /// Will almost always be one of:
  /// - `"node"` (a single point, like a POI or specific address)
  /// - `"way"` (a line or polygon, like a street or a building perimeter)
  /// - `"relation"` (a collection of ways/nodes, like a multi-polygon city boundary)
  final String osmType;

  /// The global, stable OpenStreetMap identifier for this exact geographic feature.
  /// 
  /// Unlike [placeId], this ID is stable across the global OSM ecosystem. Combined 
  /// with [osmType], this creates a globally unique composite key for the location.
  final int osmId;

  /// The mathematical latitude of the location's exact center point.
  /// 
  /// **Why a String?** Geocoding APIs often return coordinates as strings to 
  /// preserve floating-point precision. Parsing these to `double` prematurely 
  /// can result in microscopic coordinate drift due to binary translation errors.
  final String lat;

  /// The mathematical longitude of the location's exact center point.
  /// 
  /// Preserved as a String to prevent floating-point precision loss.
  final String lon;

  /// The primary category of this geographic feature.
  /// 
  /// **Naming Convention:** This field maps to the JSON key `"class"`. Because 
  /// `class` is a reserved keyword in Dart, it is aliased as `highwayClass`. 
  /// Examples include `"highway"`, `"amenity"`, `"boundary"`, or `"place"`.
  final String highwayClass;

  /// The specific sub-category of the feature, contextualized by [highwayClass].
  /// 
  /// If `highwayClass` is `"place"`, this might be `"city"`. 
  /// If `highwayClass` is `"amenity"`, this might be `"hospital"`.
  final String type;

  /// An integer indicating the search significance of the location.
  /// 
  /// Lower numbers represent larger/more important areas (e.g., a continent is `1`, 
  /// a specific house is `30`). Useful for sorting autocomplete search results.
  final int placeRank;

  /// A floating-point metric (typically `0.0` to `1.0`) determining algorithmic relevance.
  /// 
  /// When a user searches for "Springfield", the geocoder returns dozens of results. 
  /// The result with the highest [importance] is mathematically deemed the most 
  /// likely intended target.
  final double importance;

  /// A human-readable categorization of the address format.
  /// 
  /// Examples: `"city"`, `"town"`, `"village"`, `"residential"`.
  final String addressType;

  /// The specific, colloquial name of the feature, if one exists.
  /// 
  /// Examples: `"Golden Gate Bridge"`, `"Eiffel Tower"`. This is nullable because 
  /// ordinary street addresses (e.g., "123 Main St") do not have a distinct [name].
  final String? name;

  /// A pre-formatted, highly readable string representation of the full address.
  /// 
  /// Generated by the geocoding server. Excellent for populating a primary UI text 
  /// element without needing to manually concatenate fields from [LocationData].
  final String displayName;

  /// The deeply parsed, strictly typed address components.
  /// 
  /// See [LocationData] for how this nested object defensively prevents null-errors 
  /// when dealing with missing address components.
  final LocationData address;

  /// An array of four coordinate strings defining the rectangular boundary of the feature.
  /// 
  /// Format: `[South Latitude, North Latitude, West Longitude, East Longitude]`.
  /// This is incredibly useful for instructing a Map UI to "zoom to fit" the entire 
  /// city or building, rather than just centering on the [lat]/[lon] point.
  final List<String> boundingBox;

  /// {@macro location_information}
  /// 
  /// Instantiates a fully-populated [LocationInformation] object. All parameters 
  /// are strictly required except [name], enforcing a defensive design pattern.
  LocationInformation({
    required this.placeId,
    required this.licence,
    required this.osmType,
    required this.osmId,
    required this.lat,
    required this.lon,
    required this.highwayClass,
    required this.type,
    required this.placeRank,
    required this.importance,
    required this.addressType,
    this.name,
    required this.displayName,
    required this.address,
    required this.boundingBox,
  });

  /// Deserializes a raw JSON map into a strictly typed [LocationInformation] object.
  ///
  /// **Defensive Parsing Strategy:**
  /// Nominatim and alternative OSM wrappers often change key formatting depending 
  /// on the exact API version (e.g., returning `addresstype` vs `address_type`, or 
  /// `boundingbox` vs `bounding_box`). This factory aggressively checks multiple 
  /// potential keys and falls back to safe zero-values (e.g., `0`, `0.0`, `[]`) 
  /// to ensure the app never crashes on a missing payload key.
  /// 
  /// {@macro location_information}
  factory LocationInformation.fromJson(Map<String, dynamic> json) {
    return LocationInformation(
      placeId: json['place_id'] ?? 0,
      licence: json['licence'] ?? '',
      osmType: json['osm_type'] ?? '',
      osmId: json['osm_id'] ?? 0,
      lat: json['lat'] ?? '',
      lon: json['lon'] ?? '',
      highwayClass: json['class'] ?? '',
      type: json['type'] ?? '',
      placeRank: json['place_rank'] ?? 0,
      importance: json['importance']?.toDouble() ?? 0.0,
      // Handle variable API key formatting for address type
      addressType: json['addresstype'] ?? json['address_type'] ?? '',
      name: json['name'],
      displayName: json['display_name'] ?? '',
      // Safely delegate to the defensive LocationData factory
      address: LocationData.fromJson(json['address'] ?? {}),
      // Handle variable API key formatting for bounding box
      boundingBox: List<String>.from(json['boundingbox'] ?? json['bounding_box'] ?? []),
    );
  }

  /// Serializes the object back into a normalized, OSM-compatible JSON map.
  ///
  /// **Normalization:**
  /// Regardless of how the data was ingested (e.g., `addresstype` vs `address_type`), 
  /// this method normalizes the output to strictly use snake_case keys 
  /// (`address_type`, `bounding_box`). This ensures absolute consistency when 
  /// caching this object locally or transmitting it to your own backend.
  /// 
  /// {@macro location_information}
  Map<String, dynamic> toJson() {
    return {
      'place_id': placeId,
      'licence': licence,
      'osm_type': osmType,
      'osm_id': osmId,
      'lat': lat,
      'lon': lon,
      'class': highwayClass,
      'type': type,
      'place_rank': placeRank,
      'importance': importance,
      'address_type': addressType,
      'name': name,
      'display_name': displayName,
      'address': address.toJson(),
      'bounding_box': boundingBox,
    };
  }

  /// Returns a new instance of [LocationInformation] with selectively updated fields.
  ///
  /// Deeply enforces immutability. Rather than mutating fields on the existing 
  /// object, this creates a brand new instance, inheriting any fields that were 
  /// not explicitly overridden. Highly useful in reactive state management architectures 
  /// (like Bloc or Riverpod).
  /// 
  /// {@macro location_information}
  LocationInformation copyWith({
    int? placeId,
    String? licence,
    String? osmType,
    int? osmId,
    String? lat,
    String? lon,
    String? highwayClass,
    String? type,
    int? placeRank,
    double? importance,
    String? addressType,
    String? name,
    String? displayName,
    LocationData? address,
    List<String>? boundingBox,
  }) {
    return LocationInformation(
      placeId: placeId ?? this.placeId,
      licence: licence ?? this.licence,
      osmType: osmType ?? this.osmType,
      osmId: osmId ?? this.osmId,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      highwayClass: highwayClass ?? this.highwayClass,
      type: type ?? this.type,
      placeRank: placeRank ?? this.placeRank,
      importance: importance ?? this.importance,
      addressType: addressType ?? this.addressType,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      address: address ?? this.address,
      boundingBox: boundingBox ?? this.boundingBox,
    );
  }

  /// Constructs a safe, blank fallback state.
  ///
  /// **Use Case:**
  /// Generates a completely empty, yet non-null, object. Ideal for initializing 
  /// a default UI state before a network request is dispatched, ensuring no 
  /// late-initialization errors or null-pointer exceptions occur in the rendering tree.
  /// 
  /// {@macro location_information}
  factory LocationInformation.empty() {
    return LocationInformation(
      placeId: 0,
      licence: '',
      osmType: '',
      osmId: 0,
      lat: '',
      lon: '',
      highwayClass: '',
      type: '',
      placeRank: 0,
      importance: 0.0,
      addressType: '',
      name: null,
      displayName: '',
      address: LocationData.empty(),
      boundingBox: [],
    );
  }

  /// Bypasses the geocoding network layer by constructing an object directly 
  /// from raw GPS coordinates.
  ///
  /// **Architectural Fallback:**
  /// If the device acquires a GPS lock (producing a latitude/longitude), but the 
  /// reverse-geocoding network request fails (e.g., due to no internet), you can 
  /// use this factory to ensure the app can still proceed.
  /// 
  /// It injects `"Residential Zone"` as the fallback [displayName], guaranteeing 
  /// the UI has something acceptable to show the user in offline scenarios.
  /// 
  /// {@macro location_information}
  factory LocationInformation.fromLatLng(double latitude, double longitude) {
    return LocationInformation(
      placeId: 0,
      licence: '',
      osmType: '',
      osmId: 0,
      lat: '$latitude',
      lon: '$longitude',
      highwayClass: '',
      type: '',
      placeRank: 0,
      importance: 0.0,
      addressType: '',
      name: null,
      displayName: "Residential Zone", // Fallback display for offline mode
      address: LocationData.empty(),
      boundingBox: [],
    );
  }
}