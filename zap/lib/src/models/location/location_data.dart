/// {@template location_data}
/// A highly structured Data Transfer Object (DTO) representing detailed 
/// reverse-geocoded address data.
///
/// **Architectural Context:**
/// This class is explicitly designed to handle payload structures typical of 
/// OpenStreetMap (OSM) or Nominatim geocoding services. Because geospatial APIs 
/// are notoriously inconsistent (e.g., an address might have a `city` but no 
/// `borough`, or a `road` but no `house_number`), this model is built with a 
/// **defensive null-object pattern**. It guarantees that all fields are non-null 
/// strings, preventing `NoSuchMethodError` crashes in the UI layer when formatting 
/// partial addresses.
///
/// **Example Usage:**
/// ```dart
/// // Safely parsing a potentially incomplete API response
/// final location = LocationData.fromJson(apiResponse['address']);
/// 
/// // Safely formats to ", California, US" if city is missing, without crashing.
/// final displayAddress = '${location.city}, ${location.state},${location.countryCode.toUpperCase()}';
/// ```
/// {@endtemplate}
class LocationData {
  /// The primary street, avenue, or road name.
  /// 
  /// In rural or developing areas, this may represent an unnamed route or highway 
  /// designation instead of a traditional street name.
  final String road;

  /// A specific Point of Interest (POI) or landmark at this location.
  /// 
  /// Examples include "Starbucks", "General Hospital", or "Central Park". 
  /// This field is often heavily populated in dense urban areas but entirely 
  /// absent in residential zones.
  final String amenity;

  /// The secondary administrative boundary, typically sitting between a city and a state.
  /// 
  /// Examples: "Los Angeles County" (US), "Oxfordshire" (UK).
  final String county;

  /// The primary administrative region or province.
  /// 
  /// Examples: "California" (US), "Bavaria" (Germany), "Anambra" (Nigeria).
  final String state;

  /// A developer-friendly alias for the ISO 3166-2 subdivision code.
  /// 
  /// This field is populated simultaneously with [iso31662Lvl4] during JSON parsing. 
  /// It provides a cleaner, camel-cased variable name for frontend usage (e.g., `US-CA`), 
  /// preventing developers from having to type `iso31662Lvl4` in their UI widgets.
  final String isoCode;

  /// The postal code, ZIP code, or sorting code for the area.
  /// 
  /// Note: Not all countries utilize postal codes. This will fall back to an 
  /// empty string in regions where postal routing does not apply.
  final String postcode;

  /// The full, localized display name of the country.
  /// 
  /// Example: "United States" or "Federal Republic of Nigeria".
  final String country;

  /// The two-letter ISO 3166-1 alpha-2 country code.
  /// 
  /// Example: `"us"`, `"ng"`, `"gb"`. Useful for fetching localized flag icons, 
  /// determining currency, or routing to country-specific backend endpoints.
  final String countryCode;

  /// The specific plot or building identifier on the [road].
  /// 
  /// Example: "123B" or "45". Stored as a string because house numbers often 
  /// contain letters or hyphens.
  final String houseNumber;

  /// A sub-division of a city, often representing a distinct neighborhood, 
  /// district, or metropolitan borough.
  /// 
  /// Examples: "Brooklyn" (New York), "Shibuya" (Tokyo).
  final String borough;

  /// The primary municipality, town, or city name.
  /// 
  /// For exact geopolitical mapping, note that some APIs use `town` or `village` 
  /// instead of `city`, though a robust backend will normalize those into this field.
  final String city;

  /// The strict schema-matching field for the ISO 3166-2 level 4 boundary code.
  /// 
  /// This field directly mirrors the raw `ISO3166-2-lvl4` JSON key required by 
  /// Nominatim/OSM APIs. While [isoCode] is provided for UI convenience, this 
  /// field exists to guarantee 1:1 schema serialization.
  final String iso31662Lvl4;

  /// {@macro location_data}
  ///
  /// Instantiates a fully-populated [LocationData] object. All parameters are 
  /// strictly required to enforce the defensive design pattern (no nulls).
  LocationData({
    required this.road,
    required this.amenity,
    required this.county,
    required this.state,
    required this.isoCode,
    required this.postcode,
    required this.country,
    required this.countryCode,
    required this.houseNumber,
    required this.borough,
    required this.city,
    required this.iso31662Lvl4,
  });

  /// Deserializes a raw JSON map into a strictly typed [LocationData] object.
  ///
  /// **Defensive Parsing:**
  /// This factory heavily utilizes the null-coalescing operator (`?? ''`). 
  /// Geocoding APIs frequently omit keys for data that doesn't exist (e.g., 
  /// returning no `house_number` for a park). By coalescing to empty strings, 
  /// this method guarantees UI safety and eliminates the need for cascading 
  /// null-checks in the presentation layer.
  ///
  /// **Aliasing Note:**
  /// The `ISO3166-2-lvl4` JSON key is injected into both [isoCode] (for frontend 
  /// convenience) and [iso31662Lvl4] (for strict schema adherence).
  /// 
  /// {@macro location_data}
  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      road: json['road'] ?? '',
      amenity: json['amenity'] ?? '',
      county: json['county'] ?? '',
      state: json['state'] ?? '',
      isoCode: json['ISO3166-2-lvl4'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      countryCode: json['country_code'] ?? '',
      houseNumber: json['house_number'] ?? '',
      borough: json['borough'] ?? '',
      city: json['city'] ?? '',
      iso31662Lvl4: json['ISO3166-2-lvl4'] ?? '',
    );
  }

  /// Serializes the object back into an OSM-compatible JSON map.
  ///
  /// **Serialization Asymmetry:**
  /// Note that [isoCode] is intentionally dropped during serialization. Because 
  /// it is simply an alias, exporting it would pollute the JSON payload. Only 
  /// the strict `ISO3166-2-lvl4` key is written, ensuring the resulting map is 
  /// perfectly valid for external API submission or local database caching.
  /// 
  /// {@macro location_data}
  Map<String, dynamic> toJson() {
    return {
      'road': road,
      'amenity': amenity,
      'county': county,
      'state': state,
      'postcode': postcode,
      'country': country,
      'country_code': countryCode,
      'house_number': houseNumber,
      'borough': borough,
      'city': city,
      'ISO3166-2-lvl4': iso31662Lvl4,
    };
  }

  /// Constructs a safe, blank fallback state for location data.
  ///
  /// **Use Case:**
  /// Utilize this factory to generate an initial state for your UI *before* 
  /// GPS coordinates are acquired or a reverse-geocoding request completes.
  /// 
  /// **Note on `country`:**
  /// The [country] field intentionally defaults to `"Regional locale"` rather 
  /// than an empty string. This provides a sensible fallback string for UI 
  /// elements (like a location header) when the device's actual location is 
  /// disabled or still resolving.
  /// 
  /// {@macro location_data}
  factory LocationData.empty() {
    return LocationData(
      road: '',
      amenity: '',
      county: '',
      state: '',
      isoCode: '',
      postcode: '',
      country: "Regional locale", // Explicit fallback state
      countryCode: '',
      houseNumber: '',
      borough: '',
      city: '',
      iso31662Lvl4: '',
    );
  }
}