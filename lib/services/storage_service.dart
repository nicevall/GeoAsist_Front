// lib/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario_model.dart';
import '../core/app_constants.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveUser(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = json.encode(usuario.toJson());
    await prefs.setString(AppConstants.userDataKey, userJson);
    await prefs.setString(AppConstants.userRoleKey, usuario.rol);
    await prefs.setString(AppConstants.userIdKey, usuario.id);
  }

  Future<Usuario?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(AppConstants.userDataKey);
    if (userJson != null) {
      try {
        final userData = json.decode(userJson);
        return Usuario.fromJson(userData);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userRoleKey);
  }

  Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userDataKey);
    await prefs.remove(AppConstants.userRoleKey);
    await prefs.remove(AppConstants.userIdKey);
  }
}
