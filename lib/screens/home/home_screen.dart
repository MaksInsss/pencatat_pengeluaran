import 'package:flutter/material.dart';

import '../../controllers/profile_controller.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../models/user_model.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_list_item.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';
import '../transaction/add_transaction_screen.dart';
import '../transaction/edit_transaction_screen.dart';
import 'widgets/balance_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TransactionController controller = TransactionController();
  final ProfileController profileController = ProfileController();

  UserModel? currentUser;
  bool isProfileLoading = true;

  List<TransactionModel> transactions = [];

  double balance = 0;
  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;
  String? errorMessage;

  // Hanya respons dari request terbaru yang dipakai.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();

    loadTransactions();
    loadCurrentUser();
  }

  String _clean(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // =========================================================
  // LOAD DATA
  // =========================================================

  Future<void> loadCurrentUser() async {
    try {
      final user = await profileController.getCurrentUser();

      if (!mounted) return;

      setState(() {
        currentUser = user;
        isProfileLoading = false;
      });
    } catch (_) {
      // Gagal memuat profil tidak perlu mengganggu layar utama:
      // avatar jatuh ke ikon default. Error nyata (mis. sesi berakhir)
      // sudah ditangani oleh request transaksi di bawah.
      if (!mounted) return;

      setState(() {
        isProfileLoading = false;
      });
    }
  }

  /// [showLoader] false dipakai untuk pull-to-refresh dan refresh setelah
  /// kembali dari layar lain, supaya isi layar tidak diganti spinner.
  Future<void> loadTransactions({bool showLoader = true}) async {
    final requestId = ++_requestId;

    if (showLoader && mounted) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final results = await Future.wait([
        controller.getSummary(),
        controller.getTodayTransactions(),
      ]);

      final summary = results[0] as Map<String, dynamic>;
      final todayTransactions = results[1] as List<TransactionModel>;

      if (!mounted || requestId != _requestId) return;

      setState(() {
        balance = double.tryParse(summary['balance'].toString()) ?? 0;
        totalIncome = double.tryParse(summary['today_income'].toString()) ?? 0;
        totalExpense =
            double.tryParse(summary['today_expense'].toString()) ?? 0;

        transactions = todayTransactions;

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        isLoading = false;
        errorMessage = _clean(e);
      });
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      loadTransactions(showLoader: false),
      loadCurrentUser(),
    ]);
  }

  // =========================================================
  // DELETE TRANSACTION
  // =========================================================

  Future<void> deleteTransaction(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Transaksi'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus transaksi ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await controller.deleteTransaction(id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil dihapus.')),
      );

      await loadTransactions(showLoader: false);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menghapus transaksi: ${_clean(e)}')),
      );
    }
  }

  // =========================================================
  // NAVIGASI
  // =========================================================

  Future<void> openHistory() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HistoryScreen()),
    );

    // Refresh Home ketika kembali dari History.
    loadTransactions(showLoader: false);
  }

  Future<void> openAddTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
    );

    if (result == true) {
      loadTransactions(showLoader: false);
    }
  }

  Future<void> editTransaction(TransactionModel transaction) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionScreen(
          transaction: transaction,
        ),
      ),
    );

    if (result == true) {
      loadTransactions(showLoader: false);
    }
  }

  Future<void> openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );

    if (!mounted) return;

    await loadCurrentUser();
  }

  // =========================================================
  // BUILD
  // =========================================================

  Widget _buildAvatar() {
    final photoUrl = currentUser?.profilePhotoUrl;

    return InkWell(
      onTap: openProfile,
      borderRadius: BorderRadius.circular(24),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: SizedBox(
            width: 40,
            height: 40,
            child: photoUrl != null && photoUrl.isNotEmpty
                ? Image.network(
                    photoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.person, size: 24),
                      );
                    },
                  )
                : const Center(child: Icon(Icons.person, size: 24)),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 48),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'Terjadi kesalahan.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: loadTransactions,
            child: const Text('Coba Lagi'),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent() {
    return [
      BalanceCard(balance: balance),
      const SizedBox(height: 12),
      Row(
        children: [
          Expanded(
            child: SummaryCard(
              title: 'Pemasukan Hari Ini',
              amount: totalIncome,
              icon: Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SummaryCard(
              title: 'Pengeluaran Hari Ini',
              amount: totalExpense,
              icon: Icons.arrow_upward,
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Transaksi Hari Ini',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: openHistory,
            child: const Text('Lihat Riwayat'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      if (transactions.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: Text('Belum ada transaksi hari ini.')),
        ),
      ...transactions.map(
        (transaction) => TransactionListItem(
          transaction: transaction,
          onEdit: () => editTransaction(transaction),
          onDelete: () => deleteTransaction(transaction.id),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            _buildAvatar(),
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
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          // Agar pull-to-refresh tetap jalan saat isi lebih pendek dari layar.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (errorMessage != null)
              _buildError()
            else
              ..._buildContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: openAddTransaction,
        child: const Icon(Icons.add),
      ),
    );
  }
}