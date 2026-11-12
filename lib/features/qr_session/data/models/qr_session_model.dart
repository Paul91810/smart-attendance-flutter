import 'dart:convert';
import '../../domain/entities/qr_session.dart';

/// Data model representing a QR session with JSON serialization and deserialization.
class QrSessionModel extends QrSession {
  const QrSessionModel({
    required super.sessionId,
    required super.issuedAt,
    required super.expiresAt,
    required super.nonce,
    required super.signature,
  });

  factory QrSessionModel.fromJson(Map<String, dynamic> json) {
    return QrSessionModel(
      sessionId: json['sessionId'] as String? ?? '',
      issuedAt: DateTime.parse(json['issuedAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      nonce: json['nonce'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
    );
  }

  factory QrSessionModel.fromRawPayload(String rawJson) {
    final map = jsonDecode(rawJson) as Map<String, dynamic>;
    return QrSessionModel.fromJson(map);
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'issuedAt': issuedAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'nonce': nonce,
      'signature': signature,
    };
  }

  factory QrSessionModel.fromEntity(QrSession entity) {
    return QrSessionModel(
      sessionId: entity.sessionId,
      issuedAt: entity.issuedAt,
      expiresAt: entity.expiresAt,
      nonce: entity.nonce,
      signature: entity.signature,
    );
  }

  QrSession toEntity() {
    return QrSession(
      sessionId: sessionId,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      nonce: nonce,
      signature: signature,
    );
  }
}

