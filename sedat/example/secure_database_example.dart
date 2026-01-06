import 'package:sedat/sedat.dart';

// 1. Define your data model
class User {
  final String name;
  final int age;

  User({required this.name, required this.age});

  Map<String, dynamic> toJson() => {'name': name, 'age': age};
  factory User.fromJson(Map<String, dynamic> json) => User(name: json['name'], age: json['age']);
}

// 2. Implement a repository
class UserRepository extends JsonRepository<User> {
  UserRepository() : super('users') {
    registerDecoder(User.fromJson);
    registerDefault(User(name: 'Unknown', age: 0));
    registerEncoder((user) => user.toJson());
  }
}

// 3. Create a configurer
class MyAppDatabaseConfigurer extends AbstractSecureDatabaseConfigurer {
  @override
  String get prefix => 'myApp'; // Your app's prefix

  @override
  List<BaseRepository> repositories() => [UserRepository()]; // List your repositories

  @override
  Future<void> setup() async {
    // Any additional setup after repositories are opened (e.g., migrations)
    print("Database setup complete.");
  }
}

void main() async {
  // 4. Initialize the database
  final configurer = MyAppDatabaseConfigurer();
  await configurer.initialize();

  // 5. Use the repository
  final userRepository = UserRepository();

  // Save a user
  final newUser = User(name: 'Alice', age: 30);
  await userRepository.save(newUser);
  print('User saved: ${newUser.name}');


  // Get a user
  final retrievedUser = userRepository.get();
  print('Retrieved user: ${retrievedUser.name}, ${retrievedUser.age}');

  // Save another user
  final anotherUser = User(name: 'Bob', age: 25);
  await userRepository.save(anotherUser);
  print('User saved: ${anotherUser.name}');


  // Get all users (example if you implement fetchAll)
  // final allUsers = await userRepository.fetchAll();
  // print('All users: $allUsers');

  // Delete a user (example if you implement delete)
  // await userRepository.delete();
  // print('User deleted');

  // Clear the database
  // await configurer.clear();

}