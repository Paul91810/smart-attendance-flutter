import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';

/// Pure domain entity representing an HMAC-SHA256 signed, time-limited dynamic QR session.
class QrSession extends Equatable {
  final String sessionId;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String nonce;
  final String signature;

  const QrSession({
    required this.sessionId,
    required this.issuedAt,
    required this.expiresAt,
    required this.nonce,
    required this.signature,
  });

  /// Check whether this session has passed its expiration window.
  bool isExpiredAt(DateTime now) => now.isAfter(expiresAt);

  bool get isExpired => isExpiredAt(DateTime.now());

  /// Calculates remaining seconds before expiration (non-negative).
  int get secondsRemaining {
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Serializes the QR session into the canonical JSON string placed into the QR visual code.
  String toRawPayload() {
    return jsonEncode({
      'sessionId': sessionId,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'nonce': nonce,
      'signature': signature,
    });
  }

  /// Computes HMAC-SHA256 signature for canonical data tuple:
  /// `"$sessionId:${issuedAt.toIso8601String()}:${expiresAt.toIso8601String()}:$nonce"`
  static String computeHmacSignature({
    required String sessionId,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required String nonce,
    required String secret,
  }) {
    final canonicalString =
        '$sessionId:${issuedAt.toIso8601String()}:${expiresAt.toIso8601String()}:$nonce';
    final keyBytes = utf8.encode(secret);
    final hmac = Hmac(sha256, keyBytes);
    final digest = hmac.convert(utf8.encode(canonicalString));
    return digest.toString();
  }

  @override
  List<Object?> get props => [sessionId, issuedAt, expiresAt, nonce, signature];
}
