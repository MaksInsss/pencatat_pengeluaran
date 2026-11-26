import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../widgets/password_field.dart';

/// Ganti password, langkah 2 dari 2: password baru dan konfirmasinya.
/// [currentPassword] sudah diperiksa di langkah 1 dan dikirim lagi ke server
/// bersama password baru (server memeriksanya sekali lagi).
///
/// Mengembalikan `true` lewat Navigator.pop jika password berhasil diganti.
class NewPasswordScreen extends StatefulWidget {
  final String currentPassword;

  const NewPasswordScreen({
    super.key,
    required this.currentPassword,
  });

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ApiService.changePassword(
        currentPassword: widget.currentPassword,
        newPassword: _newController.text,
        newPasswordConfirmation: _confirmController.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password berhasil diubah.')),
      );

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Password Baru')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Langkah 2 dari 2',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Buat password baru. Setelah disimpan, perangkat lain '
                  'yang sedang login akan otomatis keluar.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                PasswordField(
                  controller: _newController,
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

                    if (value == widget.currentPassword) {
                      return 'Password baru harus berbeda dari yang lama.';
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

                    if (value != _newController.text) {
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Simpan Password Baru'),
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
