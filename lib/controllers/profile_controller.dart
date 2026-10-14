
// import 'dart:io';

import '../models/user_model.dart';
import '../services/api_service.dart';

class ProfileController {
  Future<UserModel> getCurrentUser() async {
    return await ApiService.getCurrentUser();
  }

  Future<UserModel> updateProfile({
    required String name,
    required String email,
  }) async {
    return await ApiService.updateProfile(
      name: name,
      email: email,
    );
  }

  Future<UserModel> uploadProfilePhoto({
    required List<int> bytes,
    required String filename,
  }) async {
    return await ApiService.uploadProfilePhoto(
      bytes: bytes,
      filename: filename,
    );
  }

  Future<UserModel> deleteProfilePhoto() async {
    return await ApiService.deleteProfilePhoto();
  }
}
