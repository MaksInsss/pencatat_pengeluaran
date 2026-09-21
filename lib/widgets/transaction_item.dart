import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class TransactionItem extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionItem({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome =
        transaction.type == 'income';

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Icon(
            isIncome
                ? Icons.arrow_downward
                : Icons.arrow_upward,
          ),
        ),

        title: Text(
          transaction.category?.name ??
              'Tanpa Kategori',
        ),

        subtitle: Text(
          transaction.description?.isNotEmpty ==
                  true
              ? transaction.description!
              : 'Tidak ada keterangan',
        ),

        trailing: Text(
          '${isIncome ? '+' : '-'} '
          '${formatRupiah(transaction.amount)}',

          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}