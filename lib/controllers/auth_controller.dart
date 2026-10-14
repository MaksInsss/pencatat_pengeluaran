import '../services/api_service.dart';
import '../services/auth_storage.dart';

class AuthController {
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await ApiService.login(
      email: email,
      password: password,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    await ApiService.register(
      name: name,
      email: email,
      password: password,
    );
  }

  Future<void> logout() async {
    await ApiService.logout();
  }

  Future<bool> isLoggedIn() async {
    return await AuthStorage.hasToken();
  }
}
