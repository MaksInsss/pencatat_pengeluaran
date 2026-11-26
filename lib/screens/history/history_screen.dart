import 'package:flutter/material.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../widgets/summary_card.dart';
import '../../widgets/transaction_list_item.dart';
import '../transaction/edit_transaction_screen.dart';
import 'widgets/category_summary_card.dart';
import 'widgets/month_selector.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TransactionController controller = TransactionController();

  List<TransactionModel> transactions = [];
  DateTime selectedMonth = DateTime.now();

  bool isLoading = true;
  String? errorMessage;

  // Penanda request terbaru. Jika pengguna berpindah bulan dengan cepat,
  // respons lama yang datang terlambat diabaikan.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  // =========================================================
  // LOAD TRANSACTIONS
  // =========================================================

  /// [showLoader] false dipakai oleh pull-to-refresh, karena
  /// RefreshIndicator sudah menampilkan indikatornya sendiri.
  Future<void> loadTransactions({bool showLoader = true}) async {
    final requestId = ++_requestId;

    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final data = await controller.getMonthlyTransactions(
        year: selectedMonth.year,
        month: selectedMonth.month,
      );

      if (!mounted || requestId != _requestId) return;

      // Urutkan berdasarkan nominal terbesar ke terkecil.
      // Hapus baris ini jika ingin tetap urut tanggal (urutan dari server).
      data.sort((a, b) => b.amount.compareTo(a.amount));

      setState(() {
        transactions = data;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;

      setState(() {
        isLoading = false;
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
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

      await loadTransactions();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal menghapus transaksi: '
            '${e.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    }
  }

  // =========================================================
  // TOTAL
  // =========================================================

  double get totalIncome {
    return transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get totalExpense {
    return transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  // =========================================================
  // BULAN
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

  void previousMonth() {
    setState(() {
      selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    });

    loadTransactions();
  }

  void nextMonth() {
    final now = DateTime.now();

    final next = DateTime(selectedMonth.year, selectedMonth.month + 1);

    // Mencegah pengguna memilih bulan yang belum terjadi.
    if (next.year > now.year ||
        (next.year == now.year && next.month > now.month)) {
      return;
    }

    setState(() {
      selectedMonth = next;
    });

    loadTransactions();
  }

  // =========================================================
  // CATEGORY SUMMARY
  // =========================================================

  Map<String, double> getCategorySummary(String type) {
    final Map<String, double> summary = {};

    for (final transaction in transactions) {
      if (transaction.type != type) continue;

      final categoryName = transaction.category?.name ?? 'Tanpa Kategori';

      summary[categoryName] =
          (summary[categoryName] ?? 0) + transaction.amount;
    }

    final sortedEntries = summary.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  // =========================================================
  // EDIT TRANSACTION
  // =========================================================

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
      loadTransactions();
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

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
      Row(
        children: [
          Expanded(
            child: SummaryCard(
              title: 'Total Pemasukan',
              amount: totalIncome,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SummaryCard(
              title: 'Total Pengeluaran',
              amount: totalExpense,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      CategorySummaryCard(
        title: 'Ringkasan Pemasukan Berdasarkan Kategori',
        summary: getCategorySummary('income'),
      ),
      CategorySummaryCard(
        title: 'Ringkasan Pengeluaran Berdasarkan Kategori',
        summary: getCategorySummary('expense'),
      ),
      const SizedBox(height: 8),
      const Text(
        'Transaksi Bulan Ini',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (transactions.isEmpty)
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
            child: Text('Belum ada transaksi pada bulan ini.'),
          ),
        ),
      ...transactions.map(
        (transaction) => TransactionListItem(
          transaction: transaction,
          showDate: true,
          onEdit: () => editTransaction(transaction),
          onDelete: () => deleteTransaction(transaction.id),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Bulanan')),
      body: RefreshIndicator(
        onRefresh: () => loadTransactions(showLoader: false),
        child: ListView(
          // Agar pull-to-refresh tetap jalan saat isi lebih pendek dari layar.
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // Selector bulan selalu terlihat, termasuk saat loading/error.
            MonthSelector(
              monthText:
                  '${monthName(selectedMonth.month)} ${selectedMonth.year}',
              onPrevious: previousMonth,
              onNext: nextMonth,
            ),
            const SizedBox(height: 12),
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
    );
  }
}