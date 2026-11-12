import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smart_attendance/core/theme/theme_cubit.dart';
import 'package:smart_attendance/core/theme/theme_state.dart';
import 'package:smart_attendance/features/auth/domain/entities/user.dart';
import 'package:smart_attendance/features/auth/domain/entities/user_role.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_attendance/features/auth/presentation/bloc/auth_state.dart';
import 'package:smart_attendance/features/auth/presentation/pages/profile_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockThemeCubit extends MockCubit<ThemeState> implements ThemeCubit {}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockThemeCubit mockThemeCubit;

  final testUser = User(
    id: 'emp_001',
    employeeId: 'EMP001',
    name: 'Alice Johnson',
    email: 'alice@smartattendance.com',
    role: UserRole.employee,
  );

  setUpAll(() {
    registerFallbackValue(const LogoutRequested());
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockThemeCubit = MockThemeCubit();

    when(() => mockAuthBloc.state).thenReturn(Authenticated(testUser));
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

  testWidgets('renders user profile details and log out button', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(ProfilePage(user: testUser)));

    expect(find.text('My Profile'), findsOneWidget);
    expect(find.text('Alice Johnson'), findsOneWidget);
    expect(find.text('alice@smartattendance.com'), findsNWidgets(2)); // Header + detail list
    expect(find.text('EMP001'), findsOneWidget);
    expect(find.text('EMPLOYEE'), findsOneWidget);
    expect(find.text('Log Out'), findsWidgets);
  });

  testWidgets('tapping Log Out button displays confirmation dialog', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(ProfilePage(user: testUser)));

    // Tap Log Out button
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Verify dialog appears with title, prompt, Back, and Log Out buttons
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Do you want to log out?'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Back'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Log Out'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping Back dismisses popup and does NOT logout', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(ProfilePage(user: testUser)));

    // Open popup
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Tap Back
    await tester.tap(find.widgetWithText(TextButton, 'Back'));
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(find.byType(AlertDialog), findsNothing);
    // LogoutRequested should NOT have been dispatched
    verifyNever(() => mockAuthBloc.add(const LogoutRequested()));
  });

  testWidgets('tapping Log Out inside confirmation dialog dispatches LogoutRequested', (tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(buildTestableWidget(ProfilePage(user: testUser)));

    // Open popup
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();

    // Tap the Log Out button inside the dialog
    final dialogLogoutButton = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Log Out'),
    );
    await tester.tap(dialogLogoutButton);
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(find.byType(AlertDialog), findsNothing);
    // LogoutRequested was dispatched
    verify(() => mockAuthBloc.add(const LogoutRequested())).called(1);
  });

  testWidgets('tapping AppBar logout action also displays confirmation popup', (tester) async {
    await tester.pumpWidget(buildTestableWidget(ProfilePage(user: testUser)));

    // Tap AppBar logout icon button
    await tester.tap(find.byTooltip('Log Out'));
    await tester.pumpAndSettle();

    // Verify dialog is shown
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Do you want to log out?'), findsOneWidget);
  });
}
