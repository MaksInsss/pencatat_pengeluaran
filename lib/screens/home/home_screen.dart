import 'package:flutter/material.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_list_item.dart';
import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../history/history_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/edit_transaction_screen.dart';
import '../profile/profile_screen.dart';
import 'widgets/balance_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
  });

  @override
  State<HomeScreen> createState() =>
      _HomeScreenState();
}

class _HomeScreenState
    extends State<HomeScreen> {
  // =========================================================
  // CONTROLLER
  // =========================================================

  final TransactionController controller =
      TransactionController();

  // =========================================================
  // DATA
  // =========================================================

  final ProfileController profileController = ProfileController();
  UserModel? currentUser;
  bool isProfileLoading = true; 

  List<TransactionModel> transactions = [];

  double balance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    loadTransactions();
    loadCurrentUser();
  }

  // =========================================================
  // LOAD DATA HOME
  // =========================================================

  Future<void> loadCurrentUser() async {
    try {
      final user = await profileController.getCurrentUser();

      if (!mounted) return;

      setState(() {
        currentUser = user;
        isProfileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProfileLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil profil: $e'),
        ),
      );
    }
  }


  Future<void> loadTransactions() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    try {
      final results = await Future.wait([
        controller.getSummary(),
        controller.getTodayTransactions(),
      ]);

      final summary =
          results[0] as Map<String, dynamic>;

      final todayTransactions =
          results[1] as List<TransactionModel>;

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
            'Gagal mengambil data: $e',
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
  // BUKA HALAMAN RIWAYAT
  // =========================================================

  Future<void> openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const HistoryScreen(),
      ),
    );

    // Refresh Home ketika kembali
    // dari halaman History.
    loadTransactions();
  }

  // =========================================================
  // BUKA HALAMAN TAMBAH TRANSAKSI
  // =========================================================

  Future<void> openAddTransaction() async {
    final result =
        await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddTransactionScreen(),
      ),
    );

    if (result == true) {
      loadTransactions();
    }
  }

  // =========================================================
  // BUKA HALAMAN EDIT TRANSAKSI
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

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProfileScreen(),
      ),
    );

    if (!mounted) return;

    await loadCurrentUser();
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(      
      appBar: AppBar(
        title: Row(
          children: [        
            InkWell(
              onTap: openProfile,
              borderRadius: BorderRadius.circular(24),
              child: CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                child: ClipOval(
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: currentUser?.profilePhotoUrl != null &&
                            currentUser!.profilePhotoUrl!.isNotEmpty
                        ? Image.network(
                            currentUser!.profilePhotoUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            webHtmlElementStrategy:
                                WebHtmlElementStrategy.prefer,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.person, size: 24),
                              );
                            },
                          )
                        : const Center(
                            child: Icon(Icons.person, size: 24),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isProfileLoading
                    ? 'Laporan Keuangan'
                    : 'Laporan Keuangan ${currentUser?.name ?? ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
                  // SALDO
                  // =================================================

                  BalanceCard(
                    balance: balance,
                  ),

                  const SizedBox(height: 12),

                  // =================================================
                  // PEMASUKAN & PENGELUARAN HARI INI
                  // =================================================

                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          title:
                              'Pemasukan Hari Ini',
                          amount:
                              totalIncome,
                          icon:
                              Icons.arrow_downward,
                        ),
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: SummaryCard(
                          title:
                              'Pengeluaran Hari Ini',
                          amount:
                              totalExpense,
                          icon:
                              Icons.arrow_upward,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // =================================================
                  // JUDUL TRANSAKSI + LIHAT RIWAYAT
                  // =================================================

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .spaceBetween,
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
                        onPressed:
                            openHistory,
                        child: const Text(
                          'Lihat Riwayat',
                        ),
                      ),
                    ],
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
                          'Belum ada transaksi hari ini.',
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

      // =========================================================
      // FAB TAMBAH TRANSAKSI
      // =========================================================

      floatingActionButton:
          FloatingActionButton(
        onPressed:
            openAddTransaction,
        child: const Icon(
          Icons.add,
        ),
      ),
    );
  }
}