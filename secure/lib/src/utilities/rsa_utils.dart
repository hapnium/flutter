import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

import '../enums/pem_mode.dart';
import 'pem.dart';

/// {@template rsa_utils}
/// A utility class for encoding and decoding RSA public and private keys
/// to and from PEM (Privacy Enhanced Mail) format using ASN.1 structure.
///
/// This class simplifies the transformation of `RSAPublicKey` and
/// `RSAPrivateKey` objects into PEM-encoded strings for secure storage
/// and transmission, and vice versa.
///
/// Example usage:
/// ```dart
/// // Encode public key to PEM
/// RSAPublicKey pubKey = RSAPublicKey(BigInt.parse('1234567'), BigInt.parse('65537'));
/// String pemPub = RSAUtils.encodePublicKey(pubKey);
///
/// // Decode public key from PEM
/// RSAPublicKey decodedPub = RSAUtils.decodePublicKey(pemPub);
///
/// // Encode private key to PEM
/// RSAPrivateKey privKey = RSAPrivateKey(
///   BigInt.parse('1234567'),
///   BigInt.parse('1234567'),
///   BigInt.parse('123'),
///   BigInt.parse('456'),
/// );
/// String pemPriv = RSAUtils.encodePrivateKey(privKey);
///
/// // Decode private key from PEM
/// RSAPrivateKey decodedPriv = RSAUtils.decodePrivateKey(pemPriv);
/// ```
/// {@endtemplate}
class RSAUtils {
  /// {@macro rsa_utils}
  RSAUtils._();
  
  /// Encodes an [RSAPublicKey] to PEM format.
  ///
  /// The [publicKey] parameter is the RSA public key to encode.
  ///
  /// Returns the PEM-formatted public key as a `String`.
  ///
  /// Example:
  /// ```dart
  /// RSAPublicKey publicKey = RSAPublicKey(BigInt.parse('modulus'), BigInt.parse('exponent'));
  /// String pem = RSAUtils.encodePublicKey(publicKey);
  /// print(pem);
  /// ```
  static String encodePublicKey(RSAPublicKey publicKey) {
    ASN1Sequence sequence = ASN1Sequence()
      ..add(ASN1IA5String(stringValue: "${publicKey.modulus!}"))
      ..add(ASN1IA5String(stringValue: "${publicKey.exponent!}"));

    return Pem.encode(sequence.encode(), PemMode.PUBLIC_RSA);
  }

  /// Decodes a PEM-formatted public key into an [RSAPublicKey].
  ///
  /// The [pem] parameter is the PEM-formatted public key as a `String`.
  ///
  /// Returns an `RSAPublicKey` object.
  ///
  /// Example:
  /// ```dart
  /// String pem = '-----BEGIN RSA PUBLIC KEY-----...';
  /// RSAPublicKey publicKey = RSAUtils.decodePublicKey(pem);
  /// print(publicKey.modulus);
  /// ```
  static RSAPublicKey decodePublicKey(String pem) {
    ASN1Parser asn1Parser = ASN1Parser(Pem.decode(pem, PemMode.PUBLIC_RSA));
    ASN1Sequence sequence = asn1Parser.nextObject() as ASN1Sequence;

    BigInt modulus = BigInt.parse((sequence.elements![0] as ASN1IA5String).stringValue!);
    BigInt exponent = BigInt.parse((sequence.elements![1] as ASN1IA5String).stringValue!);

    return RSAPublicKey(modulus, exponent);
  }

  /// Encodes an [RSAPrivateKey] to PEM format.
  ///
  /// The [privateKey] parameter is the RSA private key to encode.
  ///
  /// Returns the PEM-formatted private key as a `String`.
  ///
  /// Example:
  /// ```dart
  /// RSAPrivateKey privateKey = RSAPrivateKey(
  ///   BigInt.parse('modulus'),
  ///   BigInt.parse('privateExponent'),
  ///   BigInt.parse('p'),
  ///   BigInt.parse('q')
  /// );
  /// String pem = RSAUtils.encodePrivateKey(privateKey);
  /// print(pem);
  /// ```
  static String encodePrivateKey(RSAPrivateKey privateKey) {
    final sequence = ASN1Sequence()
      ..add(ASN1IA5String(stringValue: "${privateKey.modulus!}"))
      ..add(ASN1IA5String(stringValue: "${privateKey.privateExponent!}"))
      ..add(ASN1IA5String(stringValue: "${privateKey.p}"))
      ..add(ASN1IA5String(stringValue: "${privateKey.q}"));

    return Pem.encode(sequence.encode(), PemMode.PRIVATE_RSA);
  }

  /// Decodes a PEM-formatted private key into an [RSAPrivateKey].
  ///
  /// The [pem] parameter is the PEM-formatted private key as a `String`.
  ///
  /// Returns an `RSAPrivateKey` object.
  ///
  /// Example:
  /// ```dart
  /// String pem = '-----BEGIN RSA PRIVATE KEY-----...';
  /// RSAPrivateKey privateKey = RSAUtils.decodePrivateKey(pem);
  /// print(privateKey.modulus);
  /// ```
  static RSAPrivateKey decodePrivateKey(String pem) {
    ASN1Parser asn1Parser = ASN1Parser(Pem.decode(pem, PemMode.PRIVATE_RSA));
    ASN1Sequence sequence = asn1Parser.nextObject() as ASN1Sequence;

    BigInt modulus = BigInt.parse((sequence.elements![0] as ASN1IA5String).stringValue!);
    BigInt privateExponent =  BigInt.parse((sequence.elements![1] as ASN1IA5String).stringValue!);
    BigInt p =  BigInt.parse((sequence.elements![2] as ASN1IA5String).stringValue!);
    BigInt q =  BigInt.parse((sequence.elements![3] as ASN1IA5String).stringValue!);

    return RSAPrivateKey(modulus, privateExponent, p, q);
  }
}