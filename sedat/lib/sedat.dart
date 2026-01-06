/// Sedat: A secured database for Hapnium platforms.
///
/// Support for secure local database operations using Hive.
///
/// This library provides abstractions and utilities for interacting with a secure
/// local database, including defining repositories, handling exceptions, and
/// configuring the database.
///
/// **Key Features:**
///
/// * **Repository Pattern:** Provides abstract classes and implementations
///   for defining and using repositories for data access.  Supports various
///   data storage formats (e.g., `Map<String, dynamic>`, `List<Map<String, dynamic>>`).
/// * **Secure Storage:**  Uses Hive for local storage, allowing for encryption
///   and other security measures.
/// * **Configuration:**  Provides a mechanism for configuring the database,
///   including opening boxes and setting up repositories.
/// * **Exception Handling:** Defines a custom exception type for database errors.
///
/// **Usage:**
///
/// 1. **Define your data models:** Create Dart classes that represent the data
///    you want to store in the database.
/// 2. **Implement a repository:** Extend the `Repository` class to create a
///    repository for your data type.  You'll need to implement the `toStore`
///    and `fromStore` methods to convert between your data model and the
///    storage format.
/// 3. **Create a configurer:** Extend the `AbstractSecureDatabaseConfigurer`
///    class to configure your database, including opening the necessary boxes
///    and setting up your repositories.
/// 4. **Initialize the database:** Call the `initialize` method of your
///    configurer to open the database and set up your repositories.
/// 5. **Use your repositories:** Access your data through the repository
///    methods (e.g., `save`, `get`, `fetchAll`, `delete`).
///
/// **Example:**
///
/// ```dart
/// // Define a data model
/// class Address {
///   String street;
///   String city;
///
///   Address({required this.street, required this.city});
///
///   Map<String, dynamic> toJson() => {'street': street, 'city': city};
///   factory Address.fromJson(Map<String, dynamic> json) => Address(street: json['street'], city: json['city']);
/// }
///
/// // Implement a repository
/// class AddressRepository extends Repository<Address, Map<String, dynamic>> {
///   AddressRepository() : super('addresses');
///
///   @override
///   Map<String, dynamic> toStore(Address item) => item.toJson();
///
///   @override
///   Address fromStore(Map<String, dynamic>? data) => data != null ? Address.fromJson(data) : Address(street: "", city: "");
/// }
///
/// // Create a configurer
/// class MyDatabaseConfigurer extends AbstractSecureDatabaseConfigurer {
///   @override
///   String get prefix => 'myApp';
///
///   @override
///   List<Repository> repositories() => [AddressRepository()];
///
///   @override
///   Future<void> setup() async {
///     // Any additional setup logic
///   }
///
///   @override
///   Future<void> clear() async {
///     // Logic to clear the database
///   }
/// }
///
/// // Initialize the database
/// final configurer = MyDatabaseConfigurer();
/// await configurer.initialize();
///
/// // Use the repository
/// final addressRepository = AddressRepository();
/// final address = await addressRepository.save(Address(street: '123 Main St', city: 'Anytown'));
/// ```
library;

/// CORE
export 'src/core/abstract_secure_database_configurer.dart';

/// EXCEPTIONS
export 'src/exceptions/secure_database_exception.dart';

/// REPOSITORY
export 'src/repository/base_repository.dart';
export 'src/repository/repository.dart';
export 'src/repository/types.dart';
export 'src/repository/repository_service.dart';

/// TYPEDEFS
export 'src/typedefs.dart';