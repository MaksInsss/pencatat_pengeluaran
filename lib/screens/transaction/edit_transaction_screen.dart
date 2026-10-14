import 'package:flutter/material.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/category_model.dart';
import '../../models/transaction_model.dart';
import '../../services/api_service.dart';
import '../../widgets/transaction_form.dart';

class EditTransactionScreen extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionScreen({
    super.key,
    required this.transaction,
  });

  @override
  State<EditTransactionScreen> createState() =>
      _EditTransactionScreenState();
}

class _EditTransactionScreenState
    extends State<EditTransactionScreen> {
  final TransactionController
      transactionController =
      TransactionController();

  List<CategoryModel> categories = [];

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();

    loadCategories();
  }

  // ==============================
  // LOAD KATEGORI
  // ==============================

  Future<void> loadCategories() async {
    try {
      final result = await ApiService.getCategories();

      if (!mounted) return;

      setState(() {
        categories = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil kategori: $e',
          ),
        ),
      );
    }
  }

  // ==============================
  // UPDATE TRANSAKSI
  // ==============================

  Future<void> updateTransaction({
    required String type,
    required int categoryId,
    required double amount,
    required String? description,
    required DateTime date,
  }) async {
    setState(() {
      isSaving = true;
    });

    try {
      await transactionController.updateTransaction(
        id: widget.transaction.id,
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        transactionDate: formatApiDate(date),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil diperbarui.',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui transaksi: $e',
          ),
        ),
      );
    }
  }

  // ==============================
  // FORMAT TANGGAL API
  // ==============================

  String formatApiDate(DateTime date) {
    final year = date.year;

    final month =
        date.month.toString().padLeft(2, '0');

    final day =
        date.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    final transaction = widget.transaction;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Transaksi',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TransactionForm(
              categories: categories,

              initialType: transaction.type,

              initialCategoryId:
                  transaction.categoryId,

              initialAmount:
                  transaction.amount,

              initialDescription:
                  transaction.description,

              initialDate:
                  transaction.date,

              isSaving: isSaving,

              buttonText:
                  'Simpan Perubahan',

              onSubmit: updateTransaction,
            ),
    );
  }
}