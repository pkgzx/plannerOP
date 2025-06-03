import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plannerop/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Add Worker Flow', () {
    testWidgets('if dni exist dont add worker', (
      tester,
    ) async {
      await app.main();

      await tester.pumpAndSettle();
    });
  });
}
