import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../transaction/edit_transaction_screen.dart';
import '../../controllers/transaction_controller.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() =>
      _HistoryScreenState();
}

class _HistoryScreenState
    extends State<HistoryScreen> {
  List<TransactionModel> transactions = [];

  DateTime selectedMonth = DateTime.now();

  bool isLoading = true;

  final TransactionController
    transactionController =
    TransactionController();

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // ==========================================
  // LOAD TRANSACTIONS
  // ==========================================

  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result =
          await transactionController
              .getMonthlyTransactions(
        year: selectedMonth.year,
        month: selectedMonth.month,
      );

      result.sort(
        (a, b) =>
            b.amount.compareTo(a.amount),
      );

      if (!mounted) return;

      setState(() {
        transactions = result;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengambil riwayat: $e',
          ),
        ),
      );
    }
  }

  // ==========================================
  // HAPUS TRANSAKSI
  // ==========================================

  Future<void> deleteTransaction(int id) async {
    final confirmed =
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
            ElevatedButton(
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

    if (confirmed != true) {
      return;
    }

    try {
      await transactionController.deleteTransaction(id);

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

  // ==========================================
  // TOTAL PEMASUKAN
  // ==========================================

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

  // ==========================================
  // TOTAL PENGELUARAN
  // ==========================================

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

  // ==========================================
  // NAMA BULAN
  // ==========================================

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

  // ==========================================
  // BULAN SEBELUMNYA
  // ==========================================

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month - 1,
      );
    });

    loadTransactions();
  }

  // ==========================================
  // BULAN BERIKUTNYA
  // ==========================================

  void nextMonth() {
    final now = DateTime.now();

    final nextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
    );

    // Jangan bisa melihat bulan masa depan
    if (nextMonth.isAfter(
      DateTime(
        now.year,
        now.month,
      ),
    )) {
      return;
    }

    setState(() {
      selectedMonth = nextMonth;
    });

    loadTransactions();
  }

  // ==========================================
  // FORMAT RUPIAH
  // ==========================================

  String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  // ==========================================
  // RINGKASAN KATEGORI
  // ==========================================

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

    return Map.fromEntries(
      summary.entries.toList()
        ..sort(
          (a, b) =>
              b.value.compareTo(a.value),
        ),
    );
  }

  // ==========================================
  // BUILD CATEGORY SUMMARY
  // ==========================================

  Widget buildCategorySummary(
    String title,
    String type,
  ) {
    final summary =
        getCategorySummary(type);

    if (summary.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
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
                fontWeight:
                    FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            ...summary.entries.map(
              (entry) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 6,
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      Text(
                        entry.key,
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

  // ==========================================
  // BUILD
  // ==========================================

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
                  // ==================================
                  // NAVIGASI BULAN
                  // ==================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
                    children: [
                      IconButton(
                        onPressed:
                            previousMonth,
                        icon: const Icon(
                          Icons.chevron_left,
                        ),
                      ),

                      Text(
                        '${monthName(selectedMonth.month)} '
                        '${selectedMonth.year}',
                        style:
                            const TextStyle(
                          fontSize: 18,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      IconButton(
                        onPressed:
                            nextMonth,
                        icon: const Icon(
                          Icons.chevron_right,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ==================================
                  // TOTAL PEMASUKAN & PENGELUARAN
                  // ==================================

                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Total Pemasukan',
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  formatRupiah(
                                    totalIncome,
                                  ),
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Expanded(
                        child: Card(
                          child: Padding(
                            padding:
                                const EdgeInsets
                                    .all(16),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                const Text(
                                  'Total Pengeluaran',
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                Text(
                                  formatRupiah(
                                    totalExpense,
                                  ),
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ==================================
                  // RINGKASAN PEMASUKAN
                  // ==================================

                  buildCategorySummary(
                    'Ringkasan Pemasukan',
                    'income',
                  ),

                  const SizedBox(height: 12),

                  // ==================================
                  // RINGKASAN PENGELUARAN
                  // ==================================

                  buildCategorySummary(
                    'Ringkasan Pengeluaran',
                    'expense',
                  ),

                  const SizedBox(height: 24),

                  // ==================================
                  // JUDUL TRANSAKSI
                  // ==================================

                  const Text(
                    'Transaksi Bulan Ini',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ==================================
                  // TRANSAKSI
                  // ==================================

                  if (transactions.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 40,
                      ),
                      child: Center(
                        child: Text(
                          'Belum ada transaksi pada bulan ini',
                        ),
                      ),
                    )
                  else
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

                        final isIncome =
                            transaction.type ==
                                'income';

                        return Card(
                          margin:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 5,
                          ),
                          child: ListTile(
                            leading:
                                CircleAvatar(
                              child: Icon(
                                isIncome
                                    ? Icons
                                        .arrow_downward
                                    : Icons
                                        .arrow_upward,
                              ),
                            ),

                            title: Text(
                              transaction
                                      .category
                                      ?.name ??
                                  'Tanpa Kategori',
                              style:
                                  const TextStyle(
                                fontWeight:
                                    FontWeight
                                        .bold,
                              ),
                            ),

                            subtitle: Text(
                              transaction
                                          .description
                                          ?.isNotEmpty ==
                                      true
                                  ? transaction
                                      .description!
                                  : 'Tidak ada keterangan',
                            ),

                            trailing:
                                Row(
                              mainAxisSize:
                                  MainAxisSize
                                      .min,
                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} '
                                  '${formatRupiah(
                                    transaction
                                        .amount,
                                  )}',
                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight
                                            .bold,
                                  ),
                                ),

                                // ==================================
                                // MENU EDIT & HAPUS
                                // ==================================

                                PopupMenuButton<
                                    String>(
                                  onSelected:
                                      (value) async {
                                    // EDIT
                                    if (value ==
                                        'edit') {
                                      final result =
                                          await Navigator
                                              .push(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  EditTransactionScreen(
                                            transaction:
                                                transaction,
                                          ),
                                        ),
                                      );

                                      if (result ==
                                          true) {
                                        await loadTransactions();
                                      }
                                    }

                                    // HAPUS
                                    if (value ==
                                        'delete') {
                                      await deleteTransaction(
                                        transaction
                                            .id,
                                      );
                                    }
                                  },

                                  itemBuilder:
                                      (context) =>
                                          [
                                    const PopupMenuItem(
                                      value:
                                          'edit',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .edit,
                                          ),
                                          SizedBox(
                                            width:
                                                8,
                                          ),
                                          Text(
                                            'Edit',
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuItem(
                                      value:
                                          'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons
                                                .delete,
                                          ),
                                          SizedBox(
                                            width:
                                                8,
                                          ),
                                          Text(
                                            'Hapus',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
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