import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category_model.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import 'auth_storage.dart';

/// Error yang pesannya sudah siap ditampilkan ke pengguna.
/// toString() mengembalikan pesan apa adanya (tanpa prefix "Exception: "),
/// jadi kode UI lama yang memakai `e.toString()` tetap bekerja.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  // Ganti saat build/run, contoh Android emulator:
  // flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _uploadTimeout = Duration(seconds: 60);

  /// Dipanggil sekali saat server membalas 401 (token dicabut/tidak valid).
  /// Token lokal sudah dihapus sebelum callback ini dipanggil.
  /// Pasang di main.dart untuk mengarahkan pengguna ke layar login.
  static void Function()? onUnauthorized;

  // Beberapa request bisa gagal 401 bersamaan (mis. Home memuat profil,
  // ringkasan, dan transaksi sekaligus). Callback cukup terpanggil sekali;
  // flag di-reset saat login/registrasi berhasil.
  static bool _sessionExpiredHandled = false;

  static const Map<String, String> _jsonHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // ==========================================
  // HELPER
  // ==========================================

  static Map<String, dynamic> _decode(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Body bukan JSON (misalnya halaman error HTML dari server).
    }
    return <String, dynamic>{};
  }

  /// Mengambil pesan paling berguna dari respons error Laravel:
  /// error validasi 422 pertama, lalu `message`, lalu [fallback].
  static String _errorMessage(http.Response response, String fallback) {
    final data = _decode(response);

    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final first = errors.values.first;
      if (first is List && first.isNotEmpty) {
        return first.first.toString();
      }
    }

    final message = data['message'];
    if (message is String && message.isNotEmpty) {
      return message;
    }

    return fallback;
  }

  static ApiException _failure(http.Response response, String fallback) {
    // Dibatasi middleware throttle di server.
    if (response.statusCode == 429) {
      return const ApiException(
        'Terlalu banyak percobaan. Coba lagi sebentar lagi.',
        statusCode: 429,
      );
    }

    return ApiException(
      _errorMessage(response, fallback),
      statusCode: response.statusCode,
    );
  }

  static double _toDouble(dynamic value) {
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  /// Menjalankan request dengan timeout dan pesan error jaringan yang ramah.
  /// Aman untuk Flutter web (tidak memakai dart:io).
  static Future<http.Response> _send(
    Future<http.Response> Function() request, {
    Duration timeout = _timeout,
  }) async {
    try {
      return await request().timeout(timeout);
    } on TimeoutException {
      throw const ApiException('Server tidak merespons. Coba lagi.');
    } on http.ClientException {
      throw const ApiException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  static Future<void> _checkUnauthorized(http.Response response) async {
    if (response.statusCode != 401) return;

    await AuthStorage.deleteToken();

    if (!_sessionExpiredHandled) {
      _sessionExpiredHandled = true;
      onUnauthorized?.call();
    }

    throw const ApiException(
      'Sesi Anda telah berakhir. Silakan login kembali.',
      statusCode: 401,
    );
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  static Future<Map<String, dynamic>> _authenticate({
    required String endpoint,
    required Map<String, String> payload,
    required int successStatus,
    required String fallback,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _jsonHeaders,
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode == successStatus) {
      final data = _decode(response);
      await AuthStorage.saveToken(data['data']['token'] as String);
      _sessionExpiredHandled = false;
      return data;
    }

    throw _failure(response, fallback);
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) {
    return _authenticate(
      endpoint: '/login',
      payload: {'email': email, 'password': password},
      successStatus: 200,
      fallback: 'Login gagal.',
    );
  }

  /// Langkah 1 pendaftaran: server mengirim kode ke email. Akun belum dibuat
  /// dan belum ada token. Memanggilnya lagi = minta kode baru (server
  /// menolak jika belum lewat 60 detik).
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/register'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
        }),
      ),
    );

    if (response.statusCode == 200) {
      return _decode(response);
    }

    throw _failure(response, 'Registrasi gagal.');
  }

  /// Langkah 2 pendaftaran: kode benar -> akun dibuat, token disimpan.
  static Future<Map<String, dynamic>> verifyRegistration({
    required String email,
    required String code,
  }) {
    return _authenticate(
      endpoint: '/register/verify',
      payload: {'email': email, 'code': code},
      successStatus: 201,
      fallback: 'Verifikasi gagal.',
    );
  }

  /// Lupa password langkah 1: server mengirim kode 6 digit ke email.
  /// Server selalu membalas sukses, terdaftar atau tidak.
  static Future<void> forgotPassword({required String email}) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: _jsonHeaders,
        body: jsonEncode({'email': email}),
      ),
    );

    if (response.statusCode != 200) {
      throw _failure(response, 'Gagal mengirim kode reset password.');
    }
  }

  /// Lupa password langkah 2: kode benar -> password diganti.
  /// Semua sesi lama dicabut, jadi pengguna harus login ulang.
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
    required String passwordConfirmation,
  }) async {
    final response = await _send(
      () => http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'email': email,
          'code': code,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw _failure(response, 'Gagal mengubah password.');
    }

    // Server mencabut semua token saat reset. Hapus juga token lokal
    // (jika reset dimulai dari layar Ganti Password saat masih login),
    // supaya pengguna langsung diarahkan ke layar login.
    await AuthStorage.deleteToken();
  }

  static Future<void> logout() async {
    try {
      await authenticatedRequest(
        method: 'POST',
        endpoint: '/logout',
        handleUnauthorized: false,
      );
    } on ApiException {
      // Tetap logout secara lokal walau server tidak terjangkau
      // atau token sudah tidak valid.
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
    bool handleUnauthorized = true,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('User belum login.', statusCode: 401);
    }

    final requestHeaders = {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token',
      ...?headers,
    };

    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await _send(() {
      switch (method) {
        case 'GET':
          return http.get(uri, headers: requestHeaders);
        case 'POST':
          return http.post(uri, headers: requestHeaders, body: body);
        case 'PUT':
          return http.put(uri, headers: requestHeaders, body: body);
        case 'DELETE':
          return http.delete(uri, headers: requestHeaders, body: body);
        default:
          throw ArgumentError('HTTP method tidak didukung: $method');
      }
    });

    if (handleUnauthorized) {
      await _checkUnauthorized(response);
    }

    return response;
  }

  // ==========================================
  // PROFILE
  // ==========================================

  static UserModel _parseUser(http.Response response, String fallback) {
    if (response.statusCode == 200) {
      return UserModel.fromJson(
        Map<String, dynamic>.from(_decode(response)['data']),
      );
    }

    throw _failure(response, fallback);
  }

  static Future<UserModel> getCurrentUser() async {
    final response = await authenticatedRequest(
      method: 'GET',
      endpoint: '/me',
    );

    return _parseUser(response, 'Gagal mengambil data profil.');
  }

  static Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    final response = await authenticatedRequest(
      method: 'PUT',
      endpoint: '/profile',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email}),
    );

    return _parseUser(response, 'Gagal memperbarui profil.');
  }

  /// Ganti password langkah 1: periksa password saat ini. Gagal (422) jika salah.
  static Future<void> verifyCurrentPassword({
    required String currentPassword,
  }) async {
    final response = await authenticatedRequest(
      method: 'POST',
      endpoint: '/profile/password/verify',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'current_password': currentPassword}),
    );

    if (response.statusCode != 200) {
      throw _failure(response, 'Gagal memeriksa password.');
    }
  }

  /// Ganti password langkah 2: simpan password baru. Token di perangkat lain dicabut server,
  /// token perangkat ini tetap berlaku.
  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    final response = await authenticatedRequest(
      method: 'PUT',
      endpoint: '/profile/password',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'current_password': currentPassword,
        'password': newPassword,
        'password_confirmation': newPasswordConfirmation,
      }),
    );

    if (response.statusCode != 200) {
      throw _failure(response, 'Gagal mengubah password.');
    }
  }

  /// Ganti email langkah 1: kirim kode ke email BARU. Butuh password saat ini.
  /// Email lama belum berubah sampai [confirmEmailChange] berhasil.
  static Future<void> requestEmailChange({
    required String email,
    required String currentPassword,
  }) async {
    final response = await authenticatedRequest(
      method: 'POST',
      endpoint: '/profile/email/request',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'current_password': currentPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw _failure(response, 'Gagal mengirim kode verifikasi.');
    }
  }

  /// Ganti email langkah 2: kode benar -> email diganti, user terbaru dikembalikan.
  static Future<UserModel> confirmEmailChange({
    required String code,
  }) async {
    final response = await authenticatedRequest(
      method: 'POST',
      endpoint: '/profile/email/verify',
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'code': code}),
    );

    return _parseUser(response, 'Verifikasi email gagal.');
  }

  static Future<UserModel> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    final token = await AuthStorage.getToken();

    if (token == null || token.isEmpty) {
      throw const ApiException('Sesi login tidak ditemukan.', statusCode: 401);
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/profile/photo'),
    )
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(
        http.MultipartFile.fromBytes('photo', bytes, filename: filename),
      );

    final response = await _send(
      () async => http.Response.fromStream(await request.send()),
      timeout: _uploadTimeout,
    );

    await _checkUnauthorized(response);

    return _parseUser(response, 'Gagal mengunggah foto profil.');
  }

  static Future<UserModel> deleteProfilePhoto() async {
    final response = await authenticatedRequest(
      method: 'DELETE',
      endpoint: '/profile/photo',
    );

    return _parseUser(response, 'Gagal menghapus foto profil.');
  }

  // ==========================================
  // CATEGORIES
  // ==========================================

  static Future<List<CategoryModel>> getCategories() async {
    final response = await _send(
      () => http.get(
        Uri.parse('$baseUrl/categories'),
        headers: const {'Accept': 'application/json'},
      ),
    );

    if (response.statusCode == 200) {
      final List items = _decode(response)['data'];

      return items
          .map((item) => CategoryModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    }

    throw _failure(response, 'Gagal mengambil kategori.');
  }

  // ==========================================
  // TRANSACTIONS
  // ==========================================

  static Future<List<TransactionModel>> _fetchTransactions(
    String endpoint,
    String fallback,
  ) async {
    final response = await authenticatedRequest(
      method: 'GET',
      endpoint: endpoint,
    );

    if (response.statusCode == 200) {
      final List items = _decode(response)['data'];

      return items
          .map(
            (item) => TransactionModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();
    }

    throw _failure(response, fallback);
  }

  static Future<List<TransactionModel>> getTodayTransactions() {
    return _fetchTransactions(
      '/transactions/today',
      'Gagal mengambil transaksi hari ini.',
    );
  }

  static Future<List<TransactionModel>> getMonthlyTransactions({
    required int year,
    required int month,
  }) {
    return _fetchTransactions(
      '/transactions/monthly?year=$year&month=$month',
      'Gagal mengambil riwayat bulanan.',
    );
  }

  static Future<List<TransactionModel>> getAllTransactions() {
    return _fetchTransactions(
      '/transactions',
      'Gagal mengambil seluruh transaksi.',
    );
  }

  /// Nilai `balance`, `today_income`, `today_expense` selalu dikembalikan
  /// sebagai double. Laravel `sum()` pada kolom decimal bisa mengirim string
  /// (mis. "50000.00") tergantung driver database, jadi dinormalkan di sini.
  static Future<Map<String, dynamic>> getTransactionSummary() async {
    final response = await authenticatedRequest(
      method: 'GET',
      endpoint: '/transactions/summary',
    );

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(_decode(response)['data']);

      return {
        'balance': _toDouble(data['balance']),
        'today_income': _toDouble(data['today_income']),
        'today_expense': _toDouble(data['today_expense']),
      };
    }

    throw _failure(response, 'Gagal mengambil ringkasan transaksi.');
  }

  static String _transactionBody({
    required int categoryId,
    required String type,
    required double amount,
    required String? description,
    required String transactionDate,
  }) {
    return jsonEncode({
      'category_id': categoryId,
      'type': type,
      'amount': amount,
      'description': description,
      'transaction_date': transactionDate,
    });
  }

  static Future<Map<String, dynamic>> createTransaction({
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    final response = await authenticatedRequest(
      method: 'POST',
      endpoint: '/transactions',
      headers: {'Content-Type': 'application/json'},
      body: _transactionBody(
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        transactionDate: transactionDate,
      ),
    );

    if (response.statusCode == 201) {
      return _decode(response);
    }

    throw _failure(response, 'Gagal menambahkan transaksi.');
  }

  static Future<TransactionModel> updateTransaction({
    required int id,
    required int categoryId,
    required String type,
    required double amount,
    String? description,
    required String transactionDate,
  }) async {
    final response = await authenticatedRequest(
      method: 'PUT',
      endpoint: '/transactions/$id',
      headers: {'Content-Type': 'application/json'},
      body: _transactionBody(
        categoryId: categoryId,
        type: type,
        amount: amount,
        description: description,
        transactionDate: transactionDate,
      ),
    );

    if (response.statusCode == 200) {
      return TransactionModel.fromJson(
        Map<String, dynamic>.from(_decode(response)['data']),
      );
    }

    throw _failure(response, 'Gagal memperbarui transaksi.');
  }

  static Future<void> deleteTransaction(int id) async {
    final response = await authenticatedRequest(
      method: 'DELETE',
      endpoint: '/transactions/$id',
    );

    if (response.statusCode != 200) {
      throw _failure(response, 'Gagal menghapus transaksi.');
    }
  }
}