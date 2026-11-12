import 'package:equatable/equatable.dart';

abstract class QrSessionEvent extends Equatable {
  const QrSessionEvent();

  @override
  List<Object?> get props => [];
}

class StartQrSession extends QrSessionEvent {
  const StartQrSession();
}

class QrTick extends QrSessionEvent {
  final int secondsRemaining;

  const QrTick(this.secondsRemaining);

  @override
  List<Object?> get props => [secondsRemaining];
}

class RefreshQrSession extends QrSessionEvent {
  const RefreshQrSession();
}

class QrSessionExpired extends QrSessionEvent {
  const QrSessionExpired();
}

