import 'package:flutter/material.dart';

<<<<<<< HEAD
import '../../controllers/transaction_controller.dart';
=======
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
import '../../models/transaction_model.dart';
import '../history/history_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/edit_transaction_screen.dart';
<<<<<<< HEAD
import 'widgets/balance_card.dart';
import 'widgets/today_summary_card.dart';
import '../../widgets/transaction_list_item.dart';
=======
import '../../controllers/transaction_controller.dart';
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
<<<<<<< HEAD
  final TransactionController
      transactionController =
      TransactionController();

  List<TransactionModel> transactions = [];

=======
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

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
  double balance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

<<<<<<< HEAD
=======
  // =========================
  // INIT
  // =========================

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

<<<<<<< HEAD
=======
  // =========================
  // LOAD DATA
  // =========================

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
  Future<void> loadTransactions() async {
    setState(() {
      isLoading = true;
    });

    try {
      final summary =
          await transactionController.getSummary();

<<<<<<< HEAD
      final todayTransactions =
=======
      final todayResult =
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
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

<<<<<<< HEAD
        transactions = todayTransactions;
=======
        transactions = todayResult;
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

<<<<<<< HEAD
      ScaffoldMessenger.of(context).showSnackBar(
=======
      ScaffoldMessenger.of(context)
          .showSnackBar(
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
        SnackBar(
          content: Text(
            'Gagal mengambil transaksi: $e',
          ),
        ),
      );
    }
  }

<<<<<<< HEAD
  Future<void> deleteTransaction(int id) async {
    final confirmed = await showDialog<bool>(
=======
  // =========================
  // HAPUS TRANSAKSI
  // =========================

  Future<void> deleteTransaction(int id) async {
    final confirmed =
        await showDialog<bool>(
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Hapus Transaksi',
          ),
<<<<<<< HEAD
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
=======

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
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
            ),
          ],
        );
      },
    );

<<<<<<< HEAD
=======
    // Jika user memilih Batal
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
    if (confirmed != true) {
      return;
    }

    try {
<<<<<<< HEAD
      await transactionController
          .deleteTransaction(id);

=======
      // Hapus dari Laravel
      await transactionController.deleteTransaction(id);
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Transaksi berhasil dihapus.',
          ),
        ),
      );

<<<<<<< HEAD
=======
      // Refresh Home
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
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

<<<<<<< HEAD
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
=======
  // =========================
  // FORMAT RUPIAH
  // =========================

  String formatRupiah(double amount) {
    return 'Rp ${amount.toStringAsFixed(0)}';
  }

  // =========================
  // BUILD
  // =========================
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< HEAD
=======
      // =========================
      // APP BAR
      // =========================

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
      appBar: AppBar(
        title: const Text(
          'Keuangan Saya',
        ),
      ),

<<<<<<< HEAD
      body: RefreshIndicator(
        onRefresh: loadTransactions,
=======
      // =========================
      // BODY
      // =========================

      body: RefreshIndicator(
        onRefresh: loadTransactions,

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
        child: isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
<<<<<<< HEAD
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
=======

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
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
                      ),
                    ],
                  ),

<<<<<<< HEAD
                  const SizedBox(height: 24),
=======
                  const SizedBox(
                    height: 24,
                  ),

                  // =========================
                  // JUDUL TRANSAKSI
                  // =========================
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
<<<<<<< HEAD
                    children: [
                      const Text(
                        'Transaksi Hari Ini',
=======

                    children: [
                      const Text(
                        'Transaksi Hari Ini',

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight:
                              FontWeight.bold,
                        ),
                      ),

                      TextButton(
<<<<<<< HEAD
                        onPressed: openHistory,
=======
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

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
                        child: const Text(
                          'Lihat Riwayat',
                        ),
                      ),
                    ],
                  ),

<<<<<<< HEAD
                  const SizedBox(height: 8),
=======
                  const SizedBox(
                    height: 8,
                  ),

                  // =========================
                  // TRANSAKSI
                  // =========================
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565

                  if (transactions.isEmpty)
                    const Padding(
                      padding:
                          EdgeInsets.symmetric(
                        vertical: 40,
                      ),
<<<<<<< HEAD
=======

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
                      child: Center(
                        child: Text(
                          'Belum ada transaksi hari ini',
                        ),
                      ),
                    )
<<<<<<< HEAD
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(),
                      itemCount:
                          transactions.length,
=======

                  else
                    ListView.builder(
                      shrinkWrap: true,

                      physics:
                          const NeverScrollableScrollPhysics(),

                      itemCount:
                          transactions.length,

>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
                      itemBuilder:
                          (context, index) {
                        final transaction =
                            transactions[index];

<<<<<<< HEAD
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
=======
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
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
                        );
                      },
                    ),
                ],
              ),
      ),

<<<<<<< HEAD
      floatingActionButton:
          FloatingActionButton(
        onPressed: openAddTransaction,
        child: const Icon(Icons.add),
=======
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
>>>>>>> 363012fefb07bd68b280249a7d53f521ee95e565
      ),
    );
  }
}