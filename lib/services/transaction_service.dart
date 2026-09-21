import '../models/transaction_model.dart';

class TransactionService {
  static final TransactionService _instance =
      TransactionService._internal();

  factory TransactionService() {
    return _instance;
  }

  TransactionService._internal();

  final List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions {
    return List.unmodifiable(_transactions);
  }

  void addTransaction(TransactionModel transaction) {
    _transactions.add(transaction);
  }

  void deleteTransaction(TransactionModel transaction) {
    _transactions.remove(transaction);
  }
}