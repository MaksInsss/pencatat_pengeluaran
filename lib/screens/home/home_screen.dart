import 'package:flutter/material.dart';

import '../../models/transaction_model.dart';
import '../history/history_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/edit_transaction_screen.dart';
import '../../controllers/transaction_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // =========================
  // DATA TRANSAKSI
  // =========================

  List<TransactionModel> transactions = [];

  // =========================
  // DATA RINGKASAN
  // =========================

  final TransactionController
    transactionController =
    TransactionController();

  double balance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

  // =========================
  // INIT
  // =========================

  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

  // =========================
  // LOAD DATA
  // =========================

  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final summary =
          await transactionController.getSummary();

      final todayResult =
          await transactionController
              .getTodayTransactions();

      if (!mounted) return;

      setState(() {
        balance = double.parse(
          summary['balance'].toString(),
        );

        totalIncome = double.parse(
          summary['today_income'].toString(),
        );

        totalExpense = double.parse(
          summary['today_expense'].toString(),
        );

        transactions = todayResult;

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
            'Gagal mengambil transaksi: $e',
          ),
        ),
      );
    }
  }

  // =========================
  // HAPUS TRANSAKSI
  // =========================

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

    // Jika user memilih Batal
    if (confirmed != true) {
      return;
    }

    try {
      // Hapus dari Laravel
      await transactionController.deleteTransaction(id);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil dihapus.',
          ),
        ),
      );

      // Refresh Home
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

  // =========================
  // FORMAT RUPIAH
  // =========================

  String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  // =========================
  // BUILD
  // =========================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // =========================
      // APP BAR
      // =========================

      appBar: AppBar(
        title: const Text(
          'Keuangan Saya',
        ),
      ),

      // =========================
      // BODY
      // =========================

      body: RefreshIndicator(
        onRefresh: loadTransactions,

        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),

                children: [
                  // =========================
                  // SALDO
                  // =========================

                  Card(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(20),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Saldo Saat Ini',

                            style: TextStyle(
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),

                          const SizedBox(
                            height: 8,
                          ),

                          Text(
                            formatRupiah(balance),

                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  // =========================
                  // PEMASUKAN & PENGELUARAN
                  // =========================

                  Row(
                    children: [
                      // PEMASUKAN
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                const Text(
                                  'Pemasukan Hari Ini',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  formatRupiah(
                                    totalIncome,
                                  ),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // PENGELUARAN
                      Expanded(
                        child: Card(
                          child: Padding(
                            padding:
                                const EdgeInsets.all(
                              16,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,

                              children: [
                                const Icon(
                                  Icons.arrow_upward,
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                const Text(
                                  'Pengeluaran Hari Ini',
                                ),

                                const SizedBox(
                                  height: 4,
                                ),

                                Text(
                                  formatRupiah(
                                    totalExpense,
                                  ),

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 24,
                  ),

                  // =========================
                  // JUDUL TRANSAKSI
                  // =========================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,

                    children: [
                      const Text(
                        'Transaksi Hari Ini',

                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const HistoryScreen(),
                            ),
                          );

                          await loadTransactions();
                        },

                        child: const Text(
                          'Lihat Riwayat',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  // =========================
                  // TRANSAKSI
                  // =========================

                  if (transactions.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 40,
                      ),

                      child: Center(
                        child: Text(
                          'Belum ada transaksi hari ini',
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
                            // =========================
                            // ICON
                            // =========================

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

                            // =========================
                            // KATEGORI
                            // =========================

                            title: Text(
                              transaction.category?.name ??
                                  'Tanpa Kategori',

                              style: const TextStyle(
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),

                            // =========================
                            // KETERANGAN
                            // =========================

                            subtitle: Text(
                              transaction
                                          .description
                                          ?.isNotEmpty ==
                                      true
                                  ? transaction
                                      .description!
                                  : 'Tidak ada keterangan',
                            ),

                            // =========================
                            // NOMINAL + MENU
                            // =========================

                            trailing: Row(
                              mainAxisSize:
                                  MainAxisSize.min,

                              children: [
                                Text(
                                  '${isIncome ? '+' : '-'} '
                                  '${formatRupiah(
                                    transaction.amount,
                                  )}',

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                PopupMenuButton<String>(
                                  onSelected:
                                      (value) async {
                                    // =========================
                                    // EDIT
                                    // =========================

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

                                    // =========================
                                    // HAPUS
                                    // =========================

                                    if (value ==
                                        'delete') {
                                      await deleteTransaction(
                                        transaction.id,
                                      );
                                    }
                                  },

                                  itemBuilder:
                                      (context) => [
                                    const PopupMenuItem(
                                      value: 'edit',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.edit,
                                          ),

                                          SizedBox(
                                            width: 8,
                                          ),

                                          Text(
                                            'Edit',
                                          ),
                                        ],
                                      ),
                                    ),

                                    const PopupMenuItem(
                                      value: 'delete',

                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete,
                                          ),

                                          SizedBox(
                                            width: 8,
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

      // =========================
      // TOMBOL TAMBAH
      // =========================

      floatingActionButton:
          FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  const AddTransactionScreen(),
            ),
          );

          if (result == true) {
            await loadTransactions();
          }
        },

        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}