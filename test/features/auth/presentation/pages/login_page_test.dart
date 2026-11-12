import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/theme/theme_cubit.dart';
import 'package:smart_attendance/core/theme/theme_state.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_attendance/features/auth/presentation/pages/login_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;

  setUpAll(() {
    registerFallbackValue(const LoginSubmitted(
      identifier: 'test@example.com',
      password: 'password123',
    ));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();

    when(() => mockAuthBloc.state).thenReturn(const Unauthenticated());
    when(() => mockThemeCubit.state).thenReturn(const ThemeState(themeMode: ThemeMode.light));
  });

  Widget buildTestableWidget(Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: mockAuthBloc),
        BlocProvider<ThemeCubit>.value(value: mockThemeCubit),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('renders login form elements and demo credentials', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const LoginPage()));

    expect(find.text('Smart Attendance'), findsWidgets);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.text('Email or Employee ID'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Demo Credentials (Tap to Auto-fill)'), findsOneWidget);
  });

  testWidgets('tapping Admin demo credential auto-fills email and password', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const LoginPage()));

    final adminButton = find.text('Admin (EMP000)');
    expect(adminButton, findsOneWidget);
    await tester.tap(adminButton);
    await tester.pumpAndSettle();

    expect(find.text('admin@smartattendance.com'), findsOneWidget);
    expect(find.text('admin123'), findsOneWidget);
  });

  testWidgets('shows validation errors when submitting empty form', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const LoginPage()));

    final signInButton = find.widgetWithText(FilledButton, 'Sign In');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your email or employee ID'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);
    verifyNever(() => mockAuthBloc.add(any()));
  });

  testWidgets('dispatches LoginSubmitted when valid credentials are submitted', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const LoginPage()));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email or Employee ID'),
      'EMP001',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'password123',
    );

    final signInButton = find.widgetWithText(FilledButton, 'Sign In');
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    verify(() => mockAuthBloc.add(const LoginSubmitted(
          identifier: 'EMP001',
          password: 'password123',
        ))).called(1);
  });

  testWidgets('displays CircularProgressIndicator when AuthLoading state is emitted', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    when(() => mockAuthBloc.state).thenReturn(const AuthLoading());

    await tester.pumpWidget(buildTestableWidget(const LoginPage()));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders split screen branding panel on tablet landscape (>900dp)', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(const LoginPage()));

    expect(find.text('HMAC-SHA256 Verified'), findsOneWidget);
    expect(find.text('Offline Resilient'), findsOneWidget);
    expect(find.text('Sign in to manage and mark attendance'), findsOneWidget);
  });
}
