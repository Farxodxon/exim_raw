import 'package:flutter/material.dart';

class LinkedProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final double width;

  const LinkedProductCard({
    super.key,
    required this.product,
    this.width = 260,
  });

  @override
  Widget build(BuildContext context) {
    final active = product['is_active'] == true;
    final rawActiveFrom = product['active_from']?.toString() ?? '';
    final activeFrom = rawActiveFrom.length >= 10
        ? rawActiveFrom.substring(0, 10)
        : rawActiveFrom;
    final barcode = product['product_barcode']?.toString() ?? '';
    final name = product['product_name']?.toString() ?? "Noma'lum";
    final grams = product['grams_per_unit']?.toString() ?? '-';

    return Container(
      width: width,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                active ? Icons.check_circle : Icons.pause_circle,
                size: 14,
                color: active ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  barcode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$grams g/dona',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1565C0),
            ),
          ),
          if (activeFrom.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              '$activeFrom dan',
              style: const TextStyle(fontSize: 9, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }
}
