import 'package:flutter/material.dart';

import '../../models/category_model.dart';
import '../../services/api_service.dart';
import '../../widgets/transaction_form.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() =>
      _AddTransactionScreenState();
}

class _AddTransactionScreenState
    extends State<AddTransactionScreen> {
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
  // SIMPAN TRANSAKSI
  // ==============================

  Future<void> saveTransaction({
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
      await ApiService.createTransaction(
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
            'Transaksi berhasil disimpan.',
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
            'Gagal menyimpan transaksi: $e',
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Transaksi',
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : TransactionForm(
              categories: categories,
              initialDate: DateTime.now(),
              isSaving: isSaving,
              buttonText: 'Simpan Transaksi',
              onSubmit: saveTransaction,
            ),
    );
  }
}