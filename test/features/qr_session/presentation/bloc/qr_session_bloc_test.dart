import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/error/failures.dart';
import 'package:smart_attendance/core/error/result.dart';
import 'package:smart_attendance/features/qr_session/domain/entities/qr_session.dart';
import 'package:smart_attendance/features/qr_session/domain/usecases/generate_qr_session_usecase.dart';
import 'package:smart_attendance/features/qr_session/presentation/bloc/qr_session_bloc.dart';
import 'package:smart_attendance/features/qr_session/presentation/bloc/qr_session_event.dart';
import 'package:smart_attendance/features/qr_session/presentation/bloc/qr_session_state.dart';

class MockGenerateQrSessionUsecase extends Mock
    implements GenerateQrSessionUsecase {}

void main() {
  late MockGenerateQrSessionUsecase mockGenerateQrSessionUsecase;

  setUp(() {
    mockGenerateQrSessionUsecase = MockGenerateQrSessionUsecase();
  });

  final testSession = QrSession(
    sessionId: 'SES-001',
    issuedAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(seconds: 60)),
    nonce: 'nonce-123',
    signature: 'sig-abc',
  );

  test('initial state is QrSessionInitial', () {
    final bloc = QrSessionBloc(
      generateQrSessionUsecase: mockGenerateQrSessionUsecase,
    );
    expect(bloc.state, const QrSessionInitial());
    bloc.close();
  });

  blocTest<QrSessionBloc, QrSessionState>(
    'StartQrSession emits [QrSessionLoading, QrSessionActive] on success',
    build: () {
      when(() => mockGenerateQrSessionUsecase())
          .thenAnswer((_) async => Result.success(testSession));
      return QrSessionBloc(
        generateQrSessionUsecase: mockGenerateQrSessionUsecase,
      );
    },
    act: (bloc) => bloc.add(const StartQrSession()),
    expect: () => [
      const QrSessionLoading(),
      isA<QrSessionActive>().having((s) => s.session, 'session', testSession),
    ],
  );

  blocTest<QrSessionBloc, QrSessionState>(
    'StartQrSession emits [QrSessionLoading, QrSessionError] on failure',
    build: () {
      when(() => mockGenerateQrSessionUsecase()).thenAnswer(
        (_) async => const Result.failure(
          ServerFailure('Failed to generate QR', code: 'SERVER_ERROR'),
        ),
      );
      return QrSessionBloc(
        generateQrSessionUsecase: mockGenerateQrSessionUsecase,
      );
    },
    act: (bloc) => bloc.add(const StartQrSession()),
    expect: () => [
      const QrSessionLoading(),
      const QrSessionError(message: 'Failed to generate QR', code: 'SERVER_ERROR'),
    ],
  );

  blocTest<QrSessionBloc, QrSessionState>(
    'QrTick updates secondsRemaining in QrSessionActive',
    build: () => QrSessionBloc(
      generateQrSessionUsecase: mockGenerateQrSessionUsecase,
    ),
    seed: () => QrSessionActive(session: testSession, secondsRemaining: 60),
    act: (bloc) => bloc.add(const QrTick(45)),
    expect: () => [
      QrSessionActive(session: testSession, secondsRemaining: 45),
    ],
  );

  blocTest<QrSessionBloc, QrSessionState>(
    'RefreshQrSession emits refreshing flag and then fresh QrSessionActive',
    build: () {
      when(() => mockGenerateQrSessionUsecase())
          .thenAnswer((_) async => Result.success(testSession));
      return QrSessionBloc(
        generateQrSessionUsecase: mockGenerateQrSessionUsecase,
      );
    },
    seed: () => QrSessionActive(session: testSession, secondsRemaining: 5),
    act: (bloc) => bloc.add(const RefreshQrSession()),
    expect: () => [
      QrSessionActive(
        session: testSession,
        secondsRemaining: 5,
        isRefreshing: true,
      ),
      isA<QrSessionActive>()
          .having((s) => s.session, 'session', testSession)
          .having((s) => s.isRefreshing, 'isRefreshing', false),
    ],
  );
}

