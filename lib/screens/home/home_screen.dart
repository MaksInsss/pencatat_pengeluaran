import 'package:flutter/material.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../history/history_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/edit_transaction_screen.dart';
import 'widgets/balance_card.dart';
import 'widgets/today_summary_card.dart';
import '../../widgets/transaction_list_item.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionController
      transactionController =
      TransactionController();

  List<TransactionModel> transactions = [];

  double balance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final summary =
          await transactionController.getSummary();

      final todayTransactions =
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

        transactions = todayTransactions;

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
            'Gagal mengambil transaksi: $e',
          ),
        ),
      );
    }
  }

  Future<void> deleteTransaction(int id) async {
    final confirmed = await showDialog<bool>(
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
                Navigator.pop(context, false);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await transactionController
          .deleteTransaction(id);

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

  Future<void> openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const HistoryScreen(),
      ),
    );

    await loadTransactions();
  }

  Future<void> openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      await loadTransactions();
    }
  }

  Future<void> openEditTransaction(
    TransactionModel transaction,
  ) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            EditTransactionScreen(
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      await loadTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Keuangan Saya',
        ),
      ),

      body: RefreshIndicator(
        onRefresh: loadTransactions,
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  BalanceCard(
                    balance: balance,
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      TodaySummaryCard(
                        title:
                            'Pemasukan Hari Ini',
                        amount: totalIncome,
                        icon:
                            Icons.arrow_downward,
                      ),

                      TodaySummaryCard(
                        title:
                            'Pengeluaran Hari Ini',
                        amount: totalExpense,
                        icon:
                            Icons.arrow_upward,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

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
                        onPressed: openHistory,
                        child: const Text(
                          'Lihat Riwayat',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

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

                        return TransactionListItem(
                          transaction:
                              transaction,
                          onEdit: () {
                            openEditTransaction(
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

      floatingActionButton:
          FloatingActionButton(
        onPressed: openAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}