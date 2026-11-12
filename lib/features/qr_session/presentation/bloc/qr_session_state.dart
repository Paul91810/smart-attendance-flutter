import 'package:equatable/equatable.dart';
import '../../domain/entities/qr_session.dart';

abstract class QrSessionState extends Equatable {
  const QrSessionState();

  @override
  List<Object?> get props => [];
}

class QrSessionInitial extends QrSessionState {
  const QrSessionInitial();
}

class QrSessionLoading extends QrSessionState {
  const QrSessionLoading();
}

class QrSessionActive extends QrSessionState {
  final QrSession session;
  final int secondsRemaining;
  final bool isRefreshing;

  const QrSessionActive({
    required this.session,
    required this.secondsRemaining,
    this.isRefreshing = false,
  });

  QrSessionActive copyWith({
    QrSession? session,
    int? secondsRemaining,
    bool? isRefreshing,
  }) {
    return QrSessionActive(
      session: session ?? this.session,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [session, secondsRemaining, isRefreshing];
}

class QrSessionError extends QrSessionState {
  final String message;
  final String? code;

  const QrSessionError({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

