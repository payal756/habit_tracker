import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mahadev/domain/repositories/auth_repository_interface.dart';
import 'package:mahadev/data/models/user_model.dart';
import 'package:mahadev/core/services/api_service.dart';
import 'package:mahadev/core/services/hive_service.dart';
import 'package:mahadev/core/constants/app_constants.dart';

class AuthRepository implements IAuthRepository {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<UserModel> login(String email, String password) async {
    final response = await _apiService.post('/auth/login', {
      'email': email,
      'password': password,
    });

    final token = response['token'];
    final user = UserModel.fromJson(response['user']);

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await HiveService.saveUser(user);

    return user;
  }

  @override
  Future<UserModel> register(Map<String, dynamic> data) async {
    final response = await _apiService.post('/auth/register', data);

    final token = response['token'];
    final user = UserModel.fromJson(response['user']);

    await _storage.write(key: AppConstants.tokenKey, value: token);
    await HiveService.saveUser(user);

    return user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return await HiveService.getUser();
  }

  @override
  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: AppConstants.tokenKey);
    return token != null && token.isNotEmpty;
  }

  @override
  Future<void> logout() async {
    await _storage.delete(key: AppConstants.tokenKey);
    await HiveService.clearAll();
  }

  @override
  Future<bool> validateToken() async {
    try {
      await _apiService.get('/auth/me');
      return true;
    } catch (e) {
      return false;
    }
  }
}
