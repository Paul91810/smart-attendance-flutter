import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/qr_session.dart';
import '../../domain/usecases/generate_qr_session_usecase.dart';
import 'qr_session_event.dart';
import 'qr_session_state.dart';

class QrSessionBloc extends Bloc<QrSessionEvent, QrSessionState> {
  final GenerateQrSessionUsecase generateQrSessionUsecase;
  Timer? _tickerTimer;

  QrSessionBloc({
    required this.generateQrSessionUsecase,
  }) : super(const QrSessionInitial()) {
    on<StartQrSession>(_onStartQrSession);
    on<QrTick>(_onQrTick);
    on<RefreshQrSession>(_onRefreshQrSession);
    on<QrSessionExpired>(_onQrSessionExpired);
  }

  Future<void> _onStartQrSession(
    StartQrSession event,
    Emitter<QrSessionState> emit,
  ) async {
    _cancelTimer();
    emit(const QrSessionLoading());

    final result = await generateQrSessionUsecase();
    result.fold(
      (failure) {
        emit(QrSessionError(message: failure.message, code: failure.code));
      },
      (session) {
        emit(QrSessionActive(
          session: session,
          secondsRemaining: session.secondsRemaining,
        ));
        _startTimer(session);
      },
    );
  }

  void _onQrTick(
    QrTick event,
    Emitter<QrSessionState> emit,
  ) {
    if (state is QrSessionActive) {
      final current = state as QrSessionActive;
      emit(current.copyWith(secondsRemaining: event.secondsRemaining));
    }
  }

  void _onQrSessionExpired(
    QrSessionExpired event,
    Emitter<QrSessionState> emit,
  ) {
    if (state is QrSessionActive) {
      final current = state as QrSessionActive;
      emit(current.copyWith(secondsRemaining: 0));
    }
  }

  Future<void> _onRefreshQrSession(
    RefreshQrSession event,
    Emitter<QrSessionState> emit,
  ) async {
    if (state is QrSessionActive) {
      final current = state as QrSessionActive;
      emit(current.copyWith(isRefreshing: true));
    } else {
      emit(const QrSessionLoading());
    }

    final result = await generateQrSessionUsecase();
    result.fold(
      (failure) {
        emit(QrSessionError(message: failure.message, code: failure.code));
      },
      (session) {
        _cancelTimer();
        emit(QrSessionActive(
          session: session,
          secondsRemaining: session.secondsRemaining,
          isRefreshing: false,
        ));
        _startTimer(session);
      },
    );
  }

  void _startTimer(QrSession session) {
    _cancelTimer();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = session.secondsRemaining;
      if (remaining <= 0) {
        add(const QrSessionExpired());
        add(const RefreshQrSession());
      } else {
        add(QrTick(remaining));
      }
    });
  }

  void _cancelTimer() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  @override
  Future<void> close() {
    _cancelTimer();
    return super.close();
  }
}
