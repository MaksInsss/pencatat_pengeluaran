import 'package:flutter/material.dart';

class BalanceCard
    extends StatelessWidget {

  final double balance;

  const BalanceCard({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      child: Padding(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [

            const Text(
              'Saldo Saat Ini',
              style:
                  TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 8),

            Text(
              'Rp ${balance.toStringAsFixed(0)}',

              style:
                  const TextStyle(
                fontSize: 32,
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