import 'package:exim_raw/widgets/linked_product_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('40 ta biriktirilgan mahsulot kartochkasi toshib ketmaydi',
      (WidgetTester tester) async {
    final products = List<Map<String, dynamic>>.generate(
      40,
      (i) => {
        'product_barcode': 'BARCODE-${i + 1}',
        'product_name':
            "Juda uzun mahsulot nomi ${i + 1} - qo'shimcha tavsif bilan",
        'grams_per_unit': 2.5,
        'is_active': i.isEven,
        'active_from': '2026-03-01',
      },
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: products
                  .map((product) => LinkedProductCard(product: product))
                  .toList(),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.byType(LinkedProductCard), findsNWidgets(40));

    final nameFinder = find.text(
      "Juda uzun mahsulot nomi 1 - qo'shimcha tavsif bilan",
    );
    expect(nameFinder, findsOneWidget);
    final nameWidget = tester.widget<Text>(nameFinder);
    expect(nameWidget.maxLines, isNull);
    expect(nameWidget.overflow, isNot(TextOverflow.ellipsis));
  });
}
