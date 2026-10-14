import 'package:flutter/material.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_list_item.dart';
import '../transaction/edit_transaction_screen.dart';
import 'widgets/category_summary_card.dart';
import 'widgets/month_selector.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
  });

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TransactionController controller =
      TransactionController();

  // =========================================================
  // DATA
  // =========================================================

  List<TransactionModel> transactions = [];

  DateTime selectedMonth = DateTime.now();

  bool isLoading = true;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

  // =========================================================
  // LOAD TRANSACTIONS
  // =========================================================

  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data =
          await controller.getMonthlyTransactions(
        year: selectedMonth.year,
        month: selectedMonth.month,
      );

      // Urutkan transaksi berdasarkan nominal
      // dari terbesar ke terkecil.
      data.sort(
        (a, b) =>
            b.amount.compareTo(a.amount),
      );

      setState(() {
        transactions = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil riwayat: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // DELETE TRANSACTION
  // =========================================================

  Future<void> deleteTransaction(
    int id,
  ) async {
    final confirm =
        await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Transaksi',
          ),
          content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  false,
                );
              },
              child: const Text(
                'Batal',
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  true,
                );
              },
              child: const Text(
                'Hapus',
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    try {
      await controller.deleteTransaction(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil dihapus.',
          ),
        ),
      );

      await loadTransactions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus transaksi: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // TOTAL PEMASUKAN
  // =========================================================

  double get totalIncome {
    return transactions
        .where(
          (transaction) =>
              transaction.type == 'income',
        )
        .fold(
          0,
          (sum, transaction) =>
              sum + transaction.amount,
        );
  }

  // =========================================================
  // TOTAL PENGELUARAN
  // =========================================================

  double get totalExpense {
    return transactions
        .where(
          (transaction) =>
              transaction.type == 'expense',
        )
        .fold(
          0,
          (sum, transaction) =>
              sum + transaction.amount,
        );
  }

  // =========================================================
  // NAMA BULAN
  // =========================================================

  String monthName(int month) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return months[month - 1];
  }

  // =========================================================
  // BULAN SEBELUMNYA
  // =========================================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });

    loadTransactions();
  }

  // =========================================================
  // BULAN BERIKUTNYA
  // =========================================================

  void nextMonth() {
    final now = DateTime.now();

    final nextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
    );

    // Mencegah pengguna memilih
    // bulan yang belum terjadi.
    if (nextMonth.year > now.year ||
        (nextMonth.year == now.year &&
            nextMonth.month > now.month)) {
      return;
    }

    setState(() {
      selectedMonth = nextMonth;
    });

    loadTransactions();
  }

  // =========================================================
  // CATEGORY SUMMARY
  // =========================================================

  Map<String, double> getCategorySummary(
    String type,
  ) {
    final Map<String, double> summary = {};

    for (final transaction in transactions) {
      if (transaction.type != type) {
        continue;
      }

      final categoryName =
          transaction.category?.name ??
              'Tanpa Kategori';

      summary[categoryName] =
          (summary[categoryName] ?? 0) +
              transaction.amount;
    }

    // Urutkan kategori berdasarkan
    // nominal terbesar ke terkecil.
    final sortedEntries =
        summary.entries.toList()
          ..sort(
            (a, b) =>
                b.value.compareTo(a.value),
          );

    return Map.fromEntries(
      sortedEntries,
    );
  }

  // =========================================================
  // EDIT TRANSACTION
  // =========================================================

  Future<void> editTransaction(
    TransactionModel transaction,
  ) async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTransactionScreen(
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      loadTransactions();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Riwayat Bulanan',
        ),
      ),

      body: isLoading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: loadTransactions,
              child: ListView(
                padding:
                    const EdgeInsets.all(16),
                children: [
                  // =================================================
                  // MONTH SELECTOR
                  // =================================================

                  MonthSelector(
                    monthText:
                        '${monthName(selectedMonth.month)} '
                        '${selectedMonth.year}',
                    onPrevious:
                        previousMonth,
                    onNext: nextMonth,
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // TOTAL PEMASUKAN & PENGELUARAN
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title:
                              'Total Pemasukan',
                          amount:
                              totalIncome,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: SummaryCard(
                          title:
                              'Total Pengeluaran',
                          amount:
                              totalExpense,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // =================================================
                  // RINGKASAN PEMASUKAN
                  // =================================================

                  CategorySummaryCard(
                    title:
                        'Ringkasan Pemasukan Berdasarkan Kategori',
                    summary:
                        getCategorySummary(
                      'income',
                    ),
                  ),

                  // =================================================
                  // RINGKASAN PENGELUARAN
                  // =================================================

                  CategorySummaryCard(
                    title:
                        'Ringkasan Pengeluaran Berdasarkan Kategori',
                    summary:
                        getCategorySummary(
                      'expense',
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // JUDUL TRANSAKSI
                  // =================================================

                  const Text(
                    'Transaksi Bulan Ini',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // =================================================
                  // JIKA BELUM ADA TRANSAKSI
                  // =================================================

                  if (transactions.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi pada bulan ini.',
                        ),
                      ),
                    ),

                  // =================================================
                  // LIST TRANSAKSI
                  // =================================================

                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
                    itemCount:
                        transactions.length,
                    itemBuilder:
                        (context, index) {
                      final transaction =
                          transactions[index];

                      return TransactionListItem(
                        transaction:
                            transaction,

                        onEdit: () {
                          editTransaction(
                            transaction,
                          );
                        },

                        onDelete: () {
                          deleteTransaction(
                            transaction.id,
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}