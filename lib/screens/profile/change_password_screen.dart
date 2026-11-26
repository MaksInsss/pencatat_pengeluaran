import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/password_field.dart';
import '../auth/reset_password_screen.dart';
import 'new_password_screen.dart';

/// Ganti password, langkah 1 dari 2: pengguna memasukkan password saat ini.
/// Jika benar, lanjut ke [NewPasswordScreen]. Ada juga jalan keluar
/// "Lupa password?" lewat kode yang dikirim ke email.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();

  bool _isVerifying = false;
  bool _isSendingCode = false;

  bool get _isBusy => _isVerifying || _isSendingCode;

  @override
  void dispose() {
    _currentController.dispose();
    super.dispose();
  }

  String _clean(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  // ==============================
  // LANJUT KE PASSWORD BARU
  // ==============================

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      await ApiService.verifyCurrentPassword(
        currentPassword: _currentController.text,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showMessage(_clean(error), isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isVerifying = false;
    });

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => NewPasswordScreen(
          currentPassword: _currentController.text,
        ),
      ),
    );

    // Password sudah diganti di layar berikutnya: kembali ke Profil.
    if (changed == true && mounted) {
      Navigator.pop(context);
    }
  }

  // ==============================
  // LUPA PASSWORD SAAT INI
  // ==============================
  //
  // Pengguna sudah login, jadi email diambil dari akunnya sendiri.
  // Kode dikirim ke email itu, lalu alurnya sama dengan Lupa Password
  // di layar login.

  Future<void> _forgotPassword() async {
    setState(() {
      _isSendingCode = true;
    });

    final String email;

    try {
      final user = await ApiService.getCurrentUser();
      email = user.email;
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSendingCode = false;
      });

      _showMessage(_clean(error), isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
    });

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Reset lewat email?'),
          content: Text(
            'Kode 6 digit akan dikirim ke $email.\n\n'
            'Setelah password diganti dengan cara ini, Anda perlu login '
            'kembali di semua perangkat.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Kirim Kode'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    setState(() {
      _isSendingCode = true;
    });

    try {
      await ApiService.forgotPassword(email: email);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSendingCode = false;
      });

      _showMessage(_clean(error), isError: true);
      return;
    }

    if (!mounted) return;

    setState(() {
      _isSendingCode = false;
    });

    _showMessage('Kode reset telah dikirim ke $email.');

    // Setelah berhasil, ResetPasswordScreen mengarahkan ke layar login.
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(email: email),
      ),
    );
  }

  // ==============================
  // BUILD
  // ==============================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Langkah 1 dari 2',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Masukkan password Anda saat ini untuk melanjutkan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _currentController,
                  label: 'Password Saat Ini',
                  enabled: !_isBusy,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _continue(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password saat ini wajib diisi.';
                    }

                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isBusy ? null : _forgotPassword,
                    child: _isSendingCode
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lupa password?'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isBusy ? null : _continue,
                    child: _isVerifying
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lanjut'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}