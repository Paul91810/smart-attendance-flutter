import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/core/responsive/responsive_breakpoints.dart';
import 'package:smart_attendance/core/responsive/responsive_layout.dart';

void main() {
  group('ResponsiveLayout', () {
    testWidgets('renders compact builder when width < 600', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              compact: (context, constraints) => const Text('Compact Layout'),
              expanded: (context, constraints) => const Text('Expanded Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Compact Layout'), findsOneWidget);
      expect(find.text('Expanded Layout'), findsNothing);
    });

    testWidgets('renders expanded builder when width > 900', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              compact: (context, constraints) => const Text('Compact Layout'),
              expanded: (context, constraints) => const Text('Expanded Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Expanded Layout'), findsOneWidget);
      expect(find.text('Compact Layout'), findsNothing);
    });

    testWidgets('renders medium builder when 600 <= width <= 900', (tester) async {
      tester.view.physicalSize = const Size(750, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ResponsiveLayout(
              compact: (context, constraints) => const Text('Compact Layout'),
              medium: (context, constraints) => const Text('Medium Layout'),
              expanded: (context, constraints) => const Text('Expanded Layout'),
            ),
          ),
        ),
      );

      expect(find.text('Medium Layout'), findsOneWidget);
      expect(find.text('Compact Layout'), findsNothing);
      expect(find.text('Expanded Layout'), findsNothing);
    });
  });

  group('ResponsiveBreakpoints', () {
    test('constants match Material 3 specifications', () {
      expect(ResponsiveBreakpoints.compactMax, 600.0);
      expect(ResponsiveBreakpoints.mediumMax, 900.0);
      expect(ResponsiveBreakpoints.maxFormWidth, 420.0);
      expect(ResponsiveBreakpoints.maxContentWidth, 720.0);
      expect(ResponsiveBreakpoints.maxExpandedContentWidth, 1100.0);
    });
  });
}

