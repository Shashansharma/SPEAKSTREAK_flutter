import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speak_streak/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  SharedPreferences.setMockInitialValues({});

  testWidgets('SpeakStreak dashboard loads', (tester) async {
    await tester.pumpWidget(const SpeakStreakApp());

    await tester.pumpAndSettle();

    expect(find.text('SpeakStreak'), findsOneWidget);
    expect(find.text('0 Day Streak'), findsOneWidget);
  });
}