import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/api_service.dart';
import '../../widgets/password_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // Sama dengan masa tunggu kirim ulang kode di server.
  static const int _cooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();

  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;
  bool _isResending = false;
  int _secondsLeft = _cooldownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    _secondsLeft = _cooldownSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _secondsLeft--;

        if (_secondsLeft <= 0) {
          timer.cancel();
        }
      });
    });
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.resetPassword(
        email: widget.email,
        code: _codeController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );

      if (!mounted) return;

      _showMessage('Password berhasil diubah. Silakan login.');

      // Semua sesi lama dicabut server. AuthGate tidak menemukan token
      // dan menampilkan layar login.
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      _showMessage(_clean(error), isError: true);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
    });

    try {
      await ApiService.forgotPassword(email: widget.email);

      if (!mounted) return;

      setState(() {
        _isResending = false;
        _startCooldown();
      });

      _showMessage('Jika email terdaftar, kode baru telah dikirim.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isResending = false;
      });

      _showMessage(_clean(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsLeft <= 0 && !_isResending && !_isSaving;

    return Scaffold(
      appBar: AppBar(title: const Text('Password Baru')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.mark_email_read_outlined, size: 64),
                  const SizedBox(height: 24),
                  Text(
                    'Masukkan kode & password baru',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kode 6 digit dikirim ke\n${widget.email}\n'
                    'Periksa juga folder spam. Kode berlaku 15 menit.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    enabled: !_isSaving,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    textInputAction: TextInputAction.next,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      hintText: '------',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().length != 6) {
                        return 'Kode harus 6 digit.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _passwordController,
                    label: 'Password Baru',
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password baru wajib diisi.';
                      }

                      if (value.length < 6) {
                        return 'Password baru minimal 6 karakter.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordField(
                    controller: _confirmController,
                    label: 'Konfirmasi Password Baru',
                    enabled: !_isSaving,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi.';
                      }

                      if (value != _passwordController.text) {
                        return 'Konfirmasi password tidak cocok.';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _submit,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Text('Ubah Password'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: canResend ? _resend : null,
                    child: Text(
                      _secondsLeft > 0
                          ? 'Kirim ulang kode dalam $_secondsLeft detik'
                          : 'Kirim ulang kode',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
