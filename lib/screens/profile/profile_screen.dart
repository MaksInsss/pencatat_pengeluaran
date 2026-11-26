
// import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/profile_controller.dart';
import '../../models/user_model.dart';
import '../../services/api_service.dart';
import '../auth/verify_code_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileController _controller = ProfileController();
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  UserModel? _user;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPhotoLoading = false;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _controller.getCurrentUser();

      if (!mounted) return;

      setState(() {
        _user = user;
        _nameController.text = user.name;
        _emailController.text = user.email;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _user!;
    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    final nameChanged = newName != user.name;
    final emailChanged = newEmail.toLowerCase() != user.email.toLowerCase();

    if (!nameChanged && !emailChanged) {
      setState(() {
        _isEditing = false;
      });
      return;
    }

    // Nama disimpan langsung. Email yang dikirim = email saat ini, karena
    // server menolak perubahan email lewat endpoint ini.
    if (nameChanged) {
      setState(() {
        _isSaving = true;
      });

      try {
        final updatedUser = await _controller.updateProfile(
          name: newName,
          email: user.email,
        );

        if (!mounted) return;

        setState(() {
          _user = updatedUser;
          _isSaving = false;
        });
      } catch (error) {
        if (!mounted) return;

        setState(() {
          _isSaving = false;
        });

        _showMessage(
          error.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
        return;
      }
    }

    // Email baru harus diverifikasi dengan kode.
    if (emailChanged) {
      await _startEmailChange(newEmail);
      return;
    }

    setState(() {
      _isEditing = false;
    });

    _showMessage('Profil berhasil diperbarui.');
  }

  Future<String?> _askPassword() {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (dialogContext) {
        bool obscure = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Konfirmasi password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Masukkan password Anda untuk mengganti email.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    obscureText: obscure,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscure = !obscure;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                FilledButton(
                  onPressed: () =>
                      Navigator.pop(dialogContext, controller.text),
                  child: const Text('Lanjut'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _startEmailChange(String newEmail) async {
    final password = await _askPassword();

    if (!mounted) return;

    if (password == null || password.isEmpty) {
      // Dibatalkan: kembalikan isian email ke email saat ini.
      setState(() {
        _emailController.text = _user!.email;
      });
      return;
    }

    try {
      await ApiService.requestEmailChange(
        email: newEmail,
        currentPassword: password,
      );
    } catch (error) {
      if (!mounted) return;

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
      return;
    }

    if (!mounted) return;

    final updatedUser = await Navigator.push<UserModel>(
      context,
      MaterialPageRoute(
        builder: (_) => VerifyCodeScreen<UserModel>(
          title: 'Verifikasi Email Baru',
          email: newEmail,
          onVerify: (code) => ApiService.confirmEmailChange(code: code),
          onResend: () => ApiService.requestEmailChange(
            email: newEmail,
            currentPassword: password,
          ),
        ),
      ),
    );

    if (!mounted) return;

    if (updatedUser == null) {
      // Pengguna keluar tanpa memasukkan kode: email tidak berubah.
      setState(() {
        _emailController.text = _user!.email;
      });

      _showMessage('Email belum diganti.');
      return;
    }

    setState(() {
      _user = updatedUser;
      _nameController.text = updatedUser.name;
      _emailController.text = updatedUser.email;
      _isEditing = false;
    });

    _showMessage('Email berhasil diganti.');
  }

  
  Future<void> _pickPhoto() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
      );

      if (pickedFile == null || !mounted) return;

      final filename = pickedFile.name;
      final extension = filename.split('.').last.toLowerCase();

      if (!['jpg', 'jpeg', 'png', 'webp'].contains(extension)) {
        _showMessage(
          'Pilih foto berformat JPG, JPEG, PNG, atau WEBP.',
          isError: true,
        );
        return;
      }

      setState(() {
        _isPhotoLoading = true;
      });

      final Uint8List bytes = await pickedFile.readAsBytes();

      final updatedUser = await _controller.uploadProfilePhoto(
        bytes: bytes,
        filename: filename,
      );

      if (!mounted) return;

      setState(() {
        _user = updatedUser;
        _isPhotoLoading = false;
      });

      _showMessage('Foto profil berhasil diperbarui.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPhotoLoading = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }


  Future<void> _deletePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus foto profil?'),
          content: const Text(
            'Foto profil akan dihapus secara permanen.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isPhotoLoading = true;
    });

    try {
      final updatedUser =
          await _controller.deleteProfilePhoto();

      if (!mounted) return;

      setState(() {
        _user = updatedUser;
        _isPhotoLoading = false;
      });

      _showMessage('Foto profil berhasil dihapus.');
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isPhotoLoading = false;
      });

      _showMessage(
        error.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Keluar dari akun?'),
          content: const Text('Anda perlu login lagi untuk melanjutkan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Keluar'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    // Tidak melempar error: token lokal selalu dihapus walau server
    // tidak terjangkau.
    await ApiService.logout();

    if (!mounted) return;

    // AuthGate memeriksa token lagi dan menampilkan layar login.
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  
  // ImageProvider? _profileImage() {
  //   final photoUrl = _user?.profilePhotoUrl;

  //   if (photoUrl == null || photoUrl.isEmpty) {
  //     return null;
  //   }

  //   return NetworkImage(
  //     photoUrl,
  //     webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
  //   );
  // }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _user == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Gagal memuat profil.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _loadProfile,
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final user = _user!;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 12),

        Center(
          child: Column(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [                 
                  CircleAvatar(
                    radius: 58,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: ClipOval(
                      child: SizedBox(
                        width: 116,
                        height: 116,
                        child: user.profilePhotoUrl != null &&
                                user.profilePhotoUrl!.isNotEmpty
                            ? Image.network(
                                user.profilePhotoUrl!,
                                fit: BoxFit.cover,
                                width: 116,
                                height: 116,
                                webHtmlElementStrategy:
                                    WebHtmlElementStrategy.prefer,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Icon(Icons.person, size: 58),
                                  );
                                },
                              )
                            : const Center(
                                child: Icon(Icons.person, size: 58),
                              ),
                      ),
                    ),
                  ),
                  if (_isPhotoLoading)
                    const Positioned.fill(
                      child: CircleAvatar(
                        backgroundColor: Colors.black38,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                user.name,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                user.email,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isPhotoLoading
                        ? null
                        : _pickPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Ganti Foto'),
                  ),
                  if (user.profilePhotoUrl != null &&
                      user.profilePhotoUrl!.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: _isPhotoLoading
                          ? null
                          : _deletePhoto,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus Foto'),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        Row(
          children: [
            Expanded(
              child: Text(
                'Informasi Profil',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            TextButton.icon(
              onPressed: _isSaving
                  ? null
                  : () {
                      setState(() {
                        if (_isEditing) {
                          _nameController.text = user.name;
                          _emailController.text = user.email;
                        }

                        _isEditing = !_isEditing;
                      });
                    },
              icon: Icon(
                _isEditing ? Icons.close : Icons.edit_outlined,
              ),
              label: Text(_isEditing ? 'Batal' : 'Edit'),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                enabled: _isEditing && !_isSaving,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama wajib diisi.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                enabled: _isEditing && !_isSaving,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email wajib diisi.';
                  }

                  final emailPattern =
                      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

                  if (!emailPattern.hasMatch(value.trim())) {
                    return 'Format email tidak valid.';
                  }

                  return null;
                },
              ),
              if (_isEditing) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _saveProfile,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Simpan Perubahan'),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/change-password');
          },
          icon: const Icon(Icons.lock_reset),
          label: const Text('Ganti Password'),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: _logout,
          icon: const Icon(Icons.logout),
          label: const Text('Keluar'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }

}
