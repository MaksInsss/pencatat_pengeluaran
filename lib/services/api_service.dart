import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category_model.dart';
import '../models/transaction_model.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api';

  // ==========================================
  // GET CATEGORIES
  // ==========================================

  static Future<List<CategoryModel>>
      getCategories() async {
    final response = await http.get(
      Uri.parse('$baseUrl/categories'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List categories =
          data['data'];

      return categories
          .map(
            (category) =>
                CategoryModel.fromJson(category),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil kategori',
    );
  }

  static Future<Map<String, dynamic>>
    createTransaction({
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) 
  async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),

      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },

      body: jsonEncode({
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'description': description,
        'transaction_date': transactionDate,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Gagal menambahkan transaksi: '
      '${response.body}',
    );
  }

  static Future<List<TransactionModel>>
    getTodayTransactions() async {

    final response = await http.get(
      Uri.parse(
        '$baseUrl/transactions/today',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {

      final data = jsonDecode(
        response.body,
      );

      final List transactions =
          data['data'];

      return transactions
          .map(
            (transaction) =>
                TransactionModel.fromJson(
              transaction,
            ),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil transaksi hari ini',
    );
  }

  static Future<List<TransactionModel>>
    getMonthlyTransactions({
    required int year,
    required int month,
  }) 
  async {

    final response = await http.get(
      Uri.parse(
        '$baseUrl/transactions/monthly'
        '?year=$year'
        '&month=$month',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {

      final data =
          jsonDecode(response.body);

      final List transactions =
          data['data'];

      return transactions
          .map(
            (transaction) =>
                TransactionModel.fromJson(
              transaction,
            ),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil riwayat bulanan',
      );
    }

    static Future<List<TransactionModel>>
      getAllTransactions() async {
    final response = await http.get(
      Uri.parse('$baseUrl/transactions'),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List transactions =
          data['data'];

      return transactions
          .map(
            (transaction) =>
                TransactionModel.fromJson(
              transaction,
            ),
          )
          .toList();
    }

    throw Exception(
      'Gagal mengambil seluruh transaksi',
    );
  }

  static Future<Map<String, dynamic>>
      getTransactionSummary() async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/transactions/summary',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['data'];
    }

    throw Exception(
      'Gagal mengambil ringkasan transaksi',
    );
  }

  static Future<TransactionModel> updateTransaction({
    required int id,
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    final response = await http.put(
      Uri.parse(
        '$baseUrl/transactions/$id',
      ),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'category_id': categoryId,
        'type': type,
        'amount': amount,
        'description': description,
        'transaction_date': transactionDate,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return TransactionModel.fromJson(
        data['data'],
      );
    }

    throw Exception(
      'Gagal memperbarui transaksi: ${response.body}',
    );
  }

  static Future<void> deleteTransaction(
    int id,
  ) async {
    final response = await http.delete(
      Uri.parse(
        '$baseUrl/transactions/$id',
      ),
      headers: {
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghapus transaksi: ${response.body}',
      );
    }
  }
}
