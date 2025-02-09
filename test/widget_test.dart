import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dungeon_game/main.dart';
import 'package:dungeon_game/screens/game_screen.dart';

void main() {
  testWidgets('Game screen initial render test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));

    // Verify that the game screen renders with basic UI elements
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('Game controls are present', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));

    // Verify joystick controls
    expect(find.byIcon(Icons.arrow_drop_up), findsOneWidget);
    expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    expect(find.byIcon(Icons.arrow_left), findsOneWidget);
    expect(find.byIcon(Icons.arrow_right), findsOneWidget);
  });

  testWidgets('Status bar displays game stats', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));

    // Verify status bar elements
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('HP: '), findsOneWidget);
    expect(find.text('Gold: 0'), findsOneWidget);
    expect(find.text('Armor: 0'), findsOneWidget);
  });

  testWidgets('Achievements dialog shows up', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: GameScreen()));

    // Tap the achievements button
    await tester.tap(find.byIcon(Icons.emoji_events));
    await tester.pumpAndSettle();

    // Verify achievements dialog content
    expect(find.text('Достижения'), findsOneWidget);
    expect(find.text('Уровень подземелья'), findsOneWidget);
    expect(find.text('Собрано золота'), findsOneWidget);
    expect(find.text('Сделано шагов'), findsOneWidget);
    expect(find.text('Рейтинг'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Закрыть'));
    await tester.pumpAndSettle();
    expect(find.text('Достижения'), findsNothing);
  });
}
