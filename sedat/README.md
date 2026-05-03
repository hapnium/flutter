# sedat

**Hive CE**–backed local persistence with a **repository** abstraction, optional **streams**, and a single **database configurer** entry point for Flutter apps.

**Import:** `package:sedat/sedat.dart`  
**SDK:** Dart `^3.0.0`.

**Dependencies:** `hive_ce_flutter`, `meta`, **`hapnium`**, **`tracing`**.

---

## Concepts

### `AbstractSecureDatabaseConfigurer`

Subclass this to define:

- **`prefix`** — storage namespace (e.g. reverse-DNS).
- **`repositories()`** — list of **`BaseRepository`** instances (stable instances, not new objects every call).
- Optional lifecycle: **`setup`**, **`clear`**, **`close`**, plus inherited **`initialize`**, **`clearAll`**, **`closeAll`**.

`initialize()`:

1. Runs **`Hive.initFlutter`** via **`SecureDatabaseConfiguration`** (from **`getConfiguration()`** or passed **`config`**).
2. Opens each repository with prefix/device/platform/logging flags.
3. Registers repositories with **`RepositoryContext.INSTANCE`** (`repository_mixin.dart`).
4. Awaits **`setup()`**.

Call **`await configurer.initialize()`** once before `runApp` (after **`WidgetsFlutterBinding.ensureInitialized()`**).

### `Repository<Entity, Insert>`

Generic repository bridging **domain** type **`Entity`** and **stored** type **`Insert`** (often `Map<String, dynamic>`).

You **must** register before use:

- **`registerDecoder`** / **`registerEncoder`** / **`registerDefault`**, or **`registerAll`** (decoder, encoder, default value).

Otherwise reads/writes throw **`SecureDatabaseException`**.

### Other types

- **`BaseRepository`** — box name and open/close contract.
- **`StreamableRepository`** — reactive variants where applicable.
- **`RepositoryService`**, **`RepositoryConfiguration`**, **`RepositoryContext`** — wiring and shared context.
- **`SecureDatabaseException`** — database-layer errors.

---

## Example (shape only)

```dart
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:flutter/material.dart';
import 'package:sedat/sedat.dart';

class User {
  User({required this.name});
  final String name;
  Map<String, dynamic> toJson() => {'name': name};
  static User fromJson(Map<String, dynamic> j) => User(name: j['name'] as String);
  static User empty() => User(name: '');
}

class UserRepository extends Repository<User, Map<String, dynamic>> {
  UserRepository() : super('users') {
    registerAll(
      decoder: User.fromJson,
      encoder: (u) => u.toJson(),
      defaultValue: User.empty(),
    );
  }
}

class AppDb extends AbstractSecureDatabaseConfigurer {
  @override
  String get prefix => 'com.example.app';

  @override
  List<BaseRepository> repositories() => [UserRepository()];

  @override
  Future<void> setup() async {}
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppDb().initialize();
  runApp(const MyApp());
}
```

### `BaseRepository` / `Repository` — common operations

After **`open(...)`** on the configurer, typical **`Repository<Entity, Insert>`** API includes:

| Method | Purpose |
|--------|---------|
| **`registerDecoder`**, **`registerEncoder`**, **`registerDefault`**, **`registerAll`** | Required adapters; throws **`SecureDatabaseException`** if missing when reading/writing. |
| **`fromStore`**, **`toStore`** | Map storage ↔ domain (override on concrete repo or use adapters). |
| **`get()`** | Synchronous read of current value (single-key box semantics); uses default when empty. |
| **`save(Entity item)`** | `Future<Entity>` — persist and notify listeners. |
| **`fetchAll()`** | `Future<List<Entity>>` — list/collection boxes. |
| **`delete()`** | `Future<Optional<Entity>>` — remove current. |
| **`deleteAll(List<Entity> items)`** | Bulk delete. |
| **`close()`**, **`dispose()`** | Box lifecycle. |
| **`getLength()`**, **`isStoreEmpty`**, **`isNotEmpty`** | Introspection. |
| **`put()`**, **`read()`** | Advanced hooks for custom Hive **`put`** / read paths. |

**`StreamableRepository`** adds reactive streams (see `streamable_repository.dart`). Full behavior depends on box type (single vs collection); read **`base_repository.dart`** for edge cases and lazy/eager **`RepositoryInitializer`**.

---

## Code generation

`hive_ce_generator` is a **dev_dependency** for type adapters where you use generated Hive types.

---

## Installation (private monorepo)

```yaml
dependencies:
  sedat:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: sedat
```

---

## License

See [LICENSE](LICENSE) in this package directory.
