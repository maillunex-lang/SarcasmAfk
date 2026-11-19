import 'package:flutter_test/flutter_test.dart';
import 'package:bashlegends_flame/main.dart';

void main() {
  testWidgets('app boots to menu', (tester) async {
    await tester.pumpWidget(const BashLegendsApp());
    expect(find.textContaining('Арена'), findsOneWidget);
    expect(find.text('В бой'), findsOneWidget);
  });
}
