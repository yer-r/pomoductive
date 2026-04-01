import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pomoductive/main.dart';

void main() {
  testWidgets('main menu shows loop customization controls', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(
      find.text(
        'Set your focus, break, and loop count before starting a session.',
      ),
      findsOneWidget,
    );
    expect(find.text('Log in'), findsOneWidget);
    expect(find.byTooltip('Statistics'), findsNothing);
    expect(find.text('Number of loops'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(3));
    expect(find.text(defaultLoopCount.toString()), findsOneWidget);
  });

  testWidgets('pomodoro repeats across loops and then resets', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PomodoroPage(
          workDuration: Duration(seconds: 2),
          breakDuration: Duration(seconds: 2),
          loopCount: 2,
        ),
      ),
    );

    expect(find.text('Loop 1 of 2'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Pause timer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(find.text('Break time'), findsOneWidget);
    expect(find.text('Loop 1 of 2'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Loop 2 of 2'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('Break time'), findsOneWidget);
    expect(find.text('Loop 2 of 2'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();

    expect(find.text('All loops complete'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Start again'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Start again'));
    await tester.pump();

    expect(find.text('Loop 1 of 2'), findsOneWidget);
    expect(find.text('Focus time'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('pause button freezes and resumes the countdown', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: PomodoroPage(
          workDuration: Duration(seconds: 5),
          breakDuration: Duration(seconds: 2),
          loopCount: 1,
        ),
      ),
    );

    expect(find.text('00:05'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Pause timer'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Pause timer'));
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, 'Resume timer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.text('00:05'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, 'Resume timer'));
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, 'Pause timer'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.text('00:04'), findsOneWidget);
  });
}
