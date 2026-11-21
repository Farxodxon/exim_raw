import 'package:flutter_test/flutter_test.dart';
import 'package:exim_raw/utils/date_format.dart';

void main() {
  group('fmtDate', () {
    test('ISO Z matnni dd.MM.yyyy ga aylantiradi', () {
      expect(fmtDate('2021-12-03T00:00:00.000Z'), '03.12.2021');
      expect(fmtDate('2021-12-03 00:00:00.000Z'), '03.12.2021');
      expect(fmtDate('2021-12-03'), '03.12.2021');
    });

    test("bo'sh va null uchun bo'sh matn qaytaradi", () {
      expect(fmtDate(''), '');
      expect(fmtDate(null), '');
      expect(fmtDate('   '), '');
    });

    test("qo'lda kiritilgan sanani o'zgartirmaydi", () {
      expect(fmtDate('30.07.2026'), '30.07.2026');
    });

    test('DateTime ni dd.MM.yyyy ga aylantiradi', () {
      expect(fmtDate(DateTime(2026, 6, 8)), '08.06.2026');
      expect(fmtDate(DateTime(2021, 12, 3, 23, 59)), '03.12.2021');
    });
  });
}
