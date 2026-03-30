import 'package:mahadev/data/models/user_model.dart';

abstract class IAuthRepository {
  Future<UserModel> login(String email, String password);
  Future<UserModel> register(Map<String, dynamic> data);
  Future<UserModel?> getCurrentUser();
  Future<bool> isLoggedIn();
  Future<void> logout();
  Future<bool> validateToken();
}
