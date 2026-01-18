import 'package:block_blue_light/control_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:block_blue_light/main.dart';

void main() {
  testWidgets('Test main screen UI and toggle switch', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the app bar title is correct.
    expect(find.text('블루 라이트 차단'), findsOneWidget);

    // Verify that there is only one switch initially.
    final switchFinder = find.byType(Switch);
    expect(switchFinder, findsOneWidget);

    // Verify the initial state of the switch.
    Switch switchWidget = tester.widget(switchFinder);
    expect(switchWidget.value, isFalse);

    // Find the power button
    final powerButtonFinder = find.byIcon(Icons.power_settings_new);
    expect(powerButtonFinder, findsOneWidget);

    // Tap the switch to turn it on.
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    // Verify that there are now two switches.
    expect(switchFinder, findsNWidgets(2));

    // Verify the main switch is on.
    switchWidget = tester.widget(switchFinder.first);
    expect(switchWidget.value, isTrue);

    // Verify the power button is gone and the control panel is visible
    expect(powerButtonFinder, findsNothing);
    expect(find.byType(ControlPanel), findsOneWidget);

    // Tap the switch to turn it off.
    await tester.tap(switchFinder.first);
    await tester.pumpAndSettle();

    // Verify that there is only one switch again.
    expect(switchFinder, findsOneWidget);

    // Verify the power button is gone and the control panel is visible
    expect(powerButtonFinder, findsNothing);
    expect(find.byType(ControlPanel), findsOneWidget);
  });
}
