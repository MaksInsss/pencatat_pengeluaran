import 'dart:convert';
// import 'dart:io';

import 'package:http/http.dart' as http;
// import 'package:http_parser/http_parser.dart';


import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'auth_storage.dart';

class ApiService {
  static const String baseUrl =
      'http://127.0.0.1:8000/api';

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final token = data['data']['token'];

      await AuthStorage.saveToken(token);

      return data;
    }

    if (response.statusCode == 422) {
      final errors = data['errors'];

      if (errors is Map &&
          errors['email'] is List &&
          errors['email'].isNotEmpty) {
        throw Exception(
          errors['email'][0].toString(),
        );
      }

      throw Exception(
        data['message']?.toString() ??
            'Email atau password salah.',
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Login gagal.',
    );
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      final token = data['data']['token'];

      await AuthStorage.saveToken(token);

      return data;
    }

    throw Exception(
      'Registrasi gagal: ${response.body}',
    );
  }
  
  static Future<UserModel> getCurrentUser() async {
    final response = await authenticatedRequest(
      method: 'GET',
      endpoint: '/me',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Gagal mengambil data profil.',
    );
  }

  static Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await authenticatedRequest(
      method: 'PUT',
      endpoint: '/profile',
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name,
        'email': email,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    }

    if (response.statusCode == 422) {
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;

        if (firstError is List && firstError.isNotEmpty) {
          throw Exception(firstError.first.toString());
        }
      }
    }

    throw Exception(
      data['message']?.toString() ??
          'Gagal memperbarui profil.',
    );
  }

  
  static Future<UserModel> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Sesi login tidak ditemukan.');
    }

    final uri = Uri.parse('$baseUrl/profile/photo');

    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: filename,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    }

    throw Exception(
      data['message']?.toString() ?? 'Gagal mengunggah foto profil.',
    );
  }

  static Future<UserModel> deleteProfilePhoto() async {
    final response = await authenticatedRequest(
      method: 'DELETE',
      endpoint: '/profile/photo',
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(data['data']),
      );
    }

    throw Exception(
      data['message']?.toString() ??
          'Gagal menghapus foto profil.',
    );
  }


  static Future<void> logout() async {
    try {
      final response = await authenticatedRequest(
        method: 'POST',
        endpoint: '/logout',
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Logout gagal: ${response.body}',
        );
      }
    } finally {
      await AuthStorage.deleteToken();
    }
  }

  // ==========================================
  // AUTHENTICATED REQUEST
  // ==========================================

  static Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, String>? headers,
    Object? body,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw Exception(
        'User belum login.',
      );
    }

    final requestHeaders = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    final uri = Uri.parse(
      '$baseUrl$endpoint',
    );

    switch (method) {
      case 'GET':
        return await http.get(
          uri,
          headers: requestHeaders,
        );

      case 'POST':
        return await http.post(
          uri,
          headers: requestHeaders,
          body: body,
        );

      case 'PUT':
        return await http.put(
          uri,
          headers: requestHeaders,
          body: body,
        );

      case 'DELETE':
        return await http.delete(
          uri,
          headers: requestHeaders,
          body: body,
        );

      default:
        throw Exception(
          'HTTP method tidak didukung: $method',
        );
    }
  }

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

  // ==========================================
  // CREATE TRANSACTION
  // ==========================================

  static Future<Map<String, dynamic>>
      createTransaction({
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    final response =
        await authenticatedRequest(
      method: 'POST',
      endpoint: '/transactions',
      headers: {
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

  // ==========================================
  // GET TODAY TRANSACTIONS
  // ==========================================

  static Future<List<TransactionModel>>
      getTodayTransactions() async {
    final response =
        await authenticatedRequest(
      method: 'GET',
      endpoint: '/transactions/today',
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

  // ==========================================
  // GET MONTHLY TRANSACTIONS
  // ==========================================

  static Future<List<TransactionModel>>
      getMonthlyTransactions({
    required int year,
    required int month,
  }) async {
    final response =
        await authenticatedRequest(
      method: 'GET',
      endpoint:
          '/transactions/monthly'
          '?year=$year'
          '&month=$month',
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
      'Gagal mengambil riwayat bulanan',
    );
  }

  // ==========================================
  // GET ALL TRANSACTIONS
  // ==========================================

  static Future<List<TransactionModel>>
      getAllTransactions() async {
    final response =
        await authenticatedRequest(
      method: 'GET',
      endpoint: '/transactions',
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
      'Gagal mengambil seluruh transaksi',
    );
  }

  // ==========================================
  // GET TRANSACTION SUMMARY
  // ==========================================

  static Future<Map<String, dynamic>>
      getTransactionSummary() async {
    final response =
        await authenticatedRequest(
      method: 'GET',
      endpoint: '/transactions/summary',
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(
        response.body,
      );

      return data['data'];
    }

    throw Exception(
      'Gagal mengambil ringkasan transaksi',
    );
  }

  // ==========================================
  // UPDATE TRANSACTION
  // ==========================================

  static Future<TransactionModel>
      updateTransaction({
    required int id,
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    final response =
        await authenticatedRequest(
      method: 'PUT',
      endpoint: '/transactions/$id',
      headers: {
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
      final data = jsonDecode(
        response.body,
      );

      return TransactionModel.fromJson(
        data['data'],
      );
    }

    throw Exception(
      'Gagal memperbarui transaksi: '
      '${response.body}',
    );
  }

  // ==========================================
  // DELETE TRANSACTION
  // ==========================================

  static Future<void> deleteTransaction(
    int id,
  ) async {
    final response =
        await authenticatedRequest(
      method: 'DELETE',
      endpoint: '/transactions/$id',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Gagal menghapus transaksi: '
        '${response.body}',
      );
    }
  }
}