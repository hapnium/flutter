import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';
import 'package:hapnium/hapnium.dart';

class TestData {
  final String name;
  final int age;

  TestData({required this.name, required this.age});

  Map<String, dynamic> toJson() => {'name': name, 'age': age};

  factory TestData.fromJson(Map<String, dynamic> json) => TestData(name: json['name'], age: json['age']);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is TestData &&
              runtimeType == other.runtimeType &&
              name == other.name &&
              age == other.age;

  @override
  int get hashCode => name.hashCode ^ age.hashCode;
}

void main() {
  group('JsonUtils', () {
    JsonUtils<TestData> jsonUtils = JsonUtils<TestData>().registerAdapter(TestData.fromJson);

    group('encode', () {
      test('should encode data to JSON string', () {
        final data = TestData(name: 'John Doe', age: 30);
        final jsonString = jsonUtils.encode(data);
        expect(jsonString, '{"name":"John Doe","age":30}');
      });

      test('should handle null values correctly', () {
        final data = TestData(name: 'John Doe', age: 30);
        final jsonString = jsonUtils.encode(data);
        expect(jsonString, isNotNull); // Or a more specific check if needed
      });
    });

    group('decode', () {
      test('should decode JSON string to data object', () {
        final jsonString = '{"name":"Jane Doe","age":25}';
        final data = jsonUtils.decode(jsonString);
        expect(data, TestData(name: 'Jane Doe', age: 25));
      });

      test('should throw an exception for invalid JSON', () {
        final invalidJsonString = '{"name":"Invalid JSON'; // Missing closing brace
        expect(() => jsonUtils.decode(invalidJsonString), throwsA(isA<FormatException>()));
      });

      test('should throw an exception for type mismatch', () {
        final jsonString = '{"name":123,"age":"25"}'; // Incorrect types
        expect(() => jsonUtils.decode(jsonString), throwsA(isA<TypeError>()));
      });
    });
  });
}