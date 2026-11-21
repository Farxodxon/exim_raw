String fmtDate(dynamic value) {
  if (value == null) return '';
  if (value is DateTime) {
    return '${value.day.toString().padLeft(2, '0')}.'
        '${value.month.toString().padLeft(2, '0')}.${value.year}';
  }
  final s = value.toString().trim();
  if (s.isEmpty) return '';
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(s);
  if (m == null) return s;
  final year = int.parse(m.group(1)!);
  final month = int.parse(m.group(2)!);
  final day = int.parse(m.group(3)!);
  return '${day.toString().padLeft(2, '0')}.'
      '${month.toString().padLeft(2, '0')}.$year';
}
