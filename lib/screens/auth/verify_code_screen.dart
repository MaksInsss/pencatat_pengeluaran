import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Layar untuk memasukkan kode 6 digit yang dikirim ke email.
/// Dipakai bersama oleh pendaftaran dan penggantian email.
///
/// - [onVerify] dipanggil dengan kode; hasilnya dikembalikan lewat
///   `Navigator.pop`. Lempar exception untuk menampilkan pesan error.
/// - [onResend] meminta kode baru. Tombol kirim ulang aktif setelah
///   hitung mundur 60 detik (sama dengan masa tunggu di server).
class VerifyCodeScreen<T> extends StatefulWidget {
  final String title;
  final String email;
  final String submitLabel;
  final Future<T> Function(String code) onVerify;
  final Future<void> Function() onResend;

  const VerifyCodeScreen({
    super.key,
    required this.title,
    required this.email,
    required this.onVerify,
    required this.onResend,
    this.submitLabel = 'Verifikasi',
  });

  @override
  State<VerifyCodeScreen<T>> createState() => _VerifyCodeScreenState<T>();
}

class _VerifyCodeScreenState<T> extends State<VerifyCodeScreen<T>> {
  static const int _cooldownSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isVerifying = false;
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

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isVerifying = true;
    });

    try {
      final result = await widget.onVerify(_codeController.text.trim());

      if (!mounted) return;

      Navigator.pop<T>(context, result);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isVerifying = false;
      });

      _showMessage(_clean(error), isError: true);
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
    });

    try {
      await widget.onResend();

      if (!mounted) return;

      setState(() {
        _isResending = false;
        _startCooldown();
      });

      _showMessage('Kode baru telah dikirim.');
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
    final canResend = _secondsLeft <= 0 && !_isResending && !_isVerifying;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
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
                    'Masukkan kode verifikasi',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Kami mengirim kode 6 digit ke\n${widget.email}\n'
                    'Periksa juga folder spam.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _codeController,
                    autofocus: true,
                    enabled: !_isVerifying,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
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
                    onFieldSubmitted: (_) => _verify(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isVerifying ? null : _verify,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : Text(widget.submitLabel),
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
