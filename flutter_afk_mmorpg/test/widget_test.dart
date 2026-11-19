import 'package:afk_mmorpg/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('menu boots', (tester) async {
    await tester.pumpWidget(const AfkApp());
    expect(find.textContaining('AFK'), findsWidgets);
    expect(find.text('В бой'), findsOneWidget);
  });
}
