# hapnium

Pure **Dart** foundation library for Hapnium apps and packages. It adds **extensions**, **`Optional<T>`**, JSON/helpers, lightweight **stream/collection utilities**, and **statistics** helpers without pulling in Flutter.

**Import:** `package:hapnium/hapnium.dart`  
**SDK:** see `pubspec.yaml` (currently Dart `^3.7.0`).  
**Dependencies:** `meta` only.

---

## What it provides

### Types and errors

- **`Optional<T>`** — optional value container (present/absent, mapping, `of` / `ofNullable`).
- **`HapniumException`** — shared base exception for library and app errors.

### Extensions (high level)

- **Primitives:** `String`, `bool`, `int`, `double`, `num`, plus **`pageable`** helpers for paged APIs.
- **Collections:** `List`, `Map`, `Iterable`, `Set`.
- **Other:** `DateTime`, `Duration`, `dynamic`, generic **`T`** (`TTypeExtensions`).

Typical uses: string casing and validation, list chunking/sorting, safe map access, iterable helpers, date arithmetic.

### Utilities

- **`JsonUtils`** — decode/encode and safe work with `Map` / dynamic JSON.
- **`InstanceUtils`** — reflection-style helpers for instances and types.
- **`RegexUtils`** — shared patterns and validation.
- **`Typedefs`** — common function type aliases.
- **`helpers/`** — `equalsAndHashCode`, `toString` helpers.

### IO and streams

- **`BaseStream`** and typed variants (**`IntStream`**, **`DoubleStream`**, generic streams) for numeric/stream pipelines.
- **`stream_support`** — supporting types for stream usage.

### Collectors and statistics

- **`Collector`** / **`Collectors`** — aggregate values from iterables (similar in spirit to Java streams).
- **`paging`** — paging-related collector helpers.
- **`IntSummaryStatistics`** / **`DoubleSummaryStatistics`** — min/max/count/sum/average summaries.

---

## `hapnium.dart` export map

Everything below is available from **`import 'package:hapnium/hapnium.dart';`** (see `lib/hapnium.dart` for the authoritative list).

| Group | Exports |
|--------|---------|
| Types | **`Optional`**, **`HapniumException`** |
| Primitive extensions | **`string.dart`**, **`bool.dart`**, **`int.dart`**, **`double.dart`**, **`num.dart`**, **`list.dart`**, **`map.dart`**, **`iterable.dart`**, **`pageable.dart`** |
| Other extensions | **`dynamic.dart`**, **`t.dart`** (generic **`T`** helpers), **`duration.dart`**, **`date_time.dart`** |
| Utils | **`InstanceUtils`** (`instance.dart`), **`JsonUtils`**, **`RegexUtils`**, **`Typedefs`** |
| Helpers | **`equals_and_hash_code.dart`**, **`to_string.dart`** |
| IO streams | **`BaseStream`**, **`IntStream`** / internals, **`DoubleStream`**, **`GenericStream`**, **`stream_support.dart`** |
| Collectors | **`Collector`**, **`Collectors`**, **`paging.dart`** |

Use your IDE “go to definition” on any extension method to see the full method set on each type.

---

## Usage

```dart
import 'package:hapnium/hapnium.dart';

void main() {
  final name = 'hapnium';
  print(name.capitalize());

  final chunks = [1, 2, 3, 4].chunk(2);
  print(chunks);

  final opt = Optional.ofNullable<String>(null);
  print(opt.isPresent); // false
}
```

---

## Relationship to other Hapnium packages

- **`smart`** re-exports this package from `smart.dart` for Flutter apps that want one umbrella import.
- **`device`**, **`sedat`**, and others depend on **`hapnium`** for shared types and extensions.

---

## Testing

Unit tests live under `test/`. Run from this directory:

```bash
dart test
```

---

## License

See [LICENSE](LICENSE) in this package directory.
