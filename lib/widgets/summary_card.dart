import 'package:flutter/material.dart';

class SummaryCard
    extends StatelessWidget {

  final String title;
  final double amount;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            Text(title),

            const SizedBox(height: 8),

            Text(
              'Rp ${amount.toStringAsFixed(0)}',

              style:
                  const TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}