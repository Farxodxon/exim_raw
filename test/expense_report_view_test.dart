import 'package:exim_raw/widgets/expense_report_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sarfi bor siryolar ro\'yxat boshida turadi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ExpenseReportView(
              materials: [
                {
                  'material_name': 'Nol sarf',
                  'material_code': 'Z',
                  'total_kg': 0,
                  'items': const [],
                },
                {
                  'material_name': 'Faol sarf',
                  'material_code': 'A',
                  'total_kg': 1.234,
                  'items': [
                    {
                      'product_name': 'Mahsulot',
                      'product_barcode': 'B1',
                      'product_qty': 10,
                      'quantity_kg': 1.234,
                      'grams_per_unit': 123.4,
                    },
                  ],
                },
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Faol sarf'), findsOneWidget);
    expect(find.text('Nol sarf'), findsOneWidget);
    expect(find.text('1.234 kg'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Faol sarf')).dy,
      lessThan(tester.getTopLeft(find.text('Nol sarf')).dy),
    );
  });

  testWidgets('xom ashyo sarfi bottom sheet ochiladi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showExpenseReportSheet(
                context,
                orderNumber: '42',
                materials: [
                  {
                    'material_name': 'Paxta',
                    'material_code': 'P-1',
                    'total_kg': 2.5,
                    'items': const [],
                  },
                ],
              ),
              child: const Text('Ochish'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Ochish'));
    await tester.pumpAndSettle();

    expect(find.text('Xom ashyo sarfi — Buyurtma 42'), findsOneWidget);
    expect(find.text('Paxta'), findsOneWidget);
    expect(find.text('2.500 kg'), findsOneWidget);
  });

  testWidgets('bo\'sh hisobotda hisoblash tugmasi ko\'rinadi', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ExpenseReportView(
            materials: const [],
            onCalculate: () {},
          ),
        ),
      ),
    );

    expect(find.text('Rasxod hali hisoblanmagan'), findsOneWidget);
    expect(find.text('Hisoblash'), findsOneWidget);
  });
}
