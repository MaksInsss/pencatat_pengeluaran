import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';

class CategorySummaryCard
    extends StatelessWidget {
  final String title;
  final Map<String, double> summary;

  const CategorySummaryCard({
    super.key,
    required this.title,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            if (summary.isEmpty)
              const Text(
                'Belum ada transaksi.',
              ),

            ...summary.entries.map(
              (entry) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                        ),
                      ),
                      Text(
                        formatRupiah(
                          entry.value,
                        ),
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}