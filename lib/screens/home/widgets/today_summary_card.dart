import 'package:flutter/material.dart';

import '../../../utils/currency_formatter.dart';

class TodaySummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;

  const TodaySummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Icon(icon),

              const SizedBox(height: 8),

              Text(title),

              const SizedBox(height: 4),

              Text(
                formatRupiah(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}