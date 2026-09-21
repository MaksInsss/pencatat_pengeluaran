import '../models/transaction_model.dart';
import '../services/api_service.dart';

class TransactionController {
  // ==========================================
  // AMBIL TRANSAKSI HARI INI
  // ==========================================

  Future<List<TransactionModel>>
      getTodayTransactions() async {
    return await ApiService
        .getTodayTransactions();
  }

  // ==========================================
  // AMBIL TRANSAKSI BULANAN
  // ==========================================

  Future<List<TransactionModel>>
      getMonthlyTransactions({
    required int year,
    required int month,
  }) async {
    return await ApiService
        .getMonthlyTransactions(
      year: year,
      month: month,
    );
  }

  // ==========================================
  // AMBIL SEMUA TRANSAKSI
  // ==========================================

  Future<List<TransactionModel>>
      getAllTransactions() async {
    return await ApiService
        .getAllTransactions();
  }

  // ==========================================
  // TAMBAH TRANSAKSI
  // ==========================================

  Future<TransactionModel>
      createTransaction({
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    final result =
        await ApiService.createTransaction(
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      transactionDate: transactionDate,
    );

    return TransactionModel.fromJson(
      result['data'],
    );
  }

  // ==========================================
  // EDIT TRANSAKSI
  // ==========================================

  Future<TransactionModel>
      updateTransaction({
    required int id,
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    return await ApiService.updateTransaction(
      id: id,
      categoryId: categoryId,
      type: type,
      amount: amount,
      description: description,
      transactionDate: transactionDate,
    );
  }

  // ==========================================
  // HAPUS TRANSAKSI
  // ==========================================

  Future<void> deleteTransaction(
    int id,
  ) async {
    await ApiService.deleteTransaction(id);
  }

  // ==========================================
  // AMBIL RINGKASAN
  // ==========================================

  Future<Map<String, dynamic>>
      getSummary() async {
    return await ApiService
        .getTransactionSummary();
  }
}