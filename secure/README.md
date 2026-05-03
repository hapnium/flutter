# secure

**Cryptography and secure messaging** for Dart: **RSA** and **elliptic-curve (EC)** key pairs, **PEM** encoding/decoding, encrypt/decrypt flows, built on **PointyCastle**.

**Import:** `package:secure/secure.dart`  
**SDK:** Dart `^3.0.0` (no Flutter SDK in `pubspec`).

**Runtime dependency:** `tracing` — implementations can log via the shared tracing package.

---

## Public surface (from `secure.dart`)

- **`SecureMessaging`** — facade with factories **`SecureMessaging.rsa()`** and **`SecureMessaging.ec()`** (the old `resolve(PemStyle)` factory is deprecated). Implements **`SecureMessagingService`**: **`generate()`**, **`encrypt({message, publicKey})`**, **`decrypt({message, privateKey})`** → **`MessagingResponse`**.
- **`SecureKey`** — implements **`SecureKeyService`**. Use **`SecureKey.factory()`** for the default implementation. Methods:
  - **`generate(String identifier)`** → **`SecureKeyResponse`** (PEM / key material for that id).
  - **`encrypt({required message, required publicKey})`** → ciphertext string.
  - **`decrypt({required message, required privateKey})`** → plaintext string.
- Models: **`SecureKeyResponse`**, **`MessagingMetadata`**, **`MessagingResponse`**.
- **`SecureException`** — domain errors.
- **`PemStyle`** enum — **RSA** vs **EC** PEM handling.

Utilities (not all re-exported from `secure.dart`): **`Pem`**, RSA/EC helpers under `src/utilities/`. Open **`secure.dart`** for the exact export list.

---

## Typical flow

1. Create messaging: `final messaging = SecureMessaging.rsa();` or `.ec()`.
2. Generate a key pair for each party: `final keys = messaging.generate();` → **`SecureKeyResponse`** (public/private PEM strings).
3. Encrypt for recipient’s public key: `messaging.encrypt(message: '...', publicKey: recipientPublicPem)`.
4. Decrypt with private key: `messaging.decrypt(message: cipherText, privateKey: privatePem)` → **`MessagingResponse`**.

Exact method names match **`SecureMessagingService`** in `src/core/messaging/secure_messaging_service.dart`.

---

## Example

```dart
import 'package:secure/secure.dart';

void rsaRoundTrip() {
  final messaging = SecureMessaging.rsa();
  final alice = messaging.generate();
  final bob = messaging.generate();

  final cipher = messaging.encrypt(
    message: 'Hello',
    publicKey: bob.publicKey,
  );
  final plain = messaging.decrypt(
    message: cipher,
    privateKey: bob.privateKey,
  );
  // use plain (MessagingResponse)
}
```

---

## Installation (private monorepo)

```yaml
dependencies:
  secure:
    git:
      url: https://github.com/Hapnium/flutter.git
      ref: main
      path: secure
```

---

## Security notes

- Use this as a **building block**; wire keys, storage, and protocol choices to your threat model.
- Prefer platform secure storage for private keys in real apps (this package focuses on crypto primitives and messaging).

---

## License

See [LICENSE](LICENSE) in this package directory.
