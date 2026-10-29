
import 'package:flutter_test/flutter_test.dart';
import 'package:proyecmozo/main.dart';

void main() {
  testWidgets('La aplicación inicia correctamente', (WidgetTester tester) async {
    await tester.pumpWidget(const ProyecMozo());
    await tester.pump();

    expect(find.byType(ProyecMozo), findsOneWidget);
  });
}
