import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:stridelog/models/user.dart';
import 'package:stridelog/services/database_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<bool> register(String name, String email, String password) async {
    _setLoading(true);
    try {
      final existingUser = await DatabaseService.getUserByEmail(email);
      if (existingUser != null) {
        _setLoading(false);
        return false;
      }

      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        email: email,
        hashedPassword: _hashPassword(password),
        createdAt: DateTime.now(),
      );

      await DatabaseService.insertUser(user);
      _currentUser = user;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserId', user.id);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.register failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _setLoading(true);
    try {
      final user = await DatabaseService.getUserByEmail(email);
      if (user == null) {
        _setLoading(false);
        return false;
      }

      final hashedPassword = _hashPassword(password);
      if (user.hashedPassword != hashedPassword) {
        _setLoading(false);
        return false;
      }

      _currentUser = user;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUserId', user.id);

      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('AuthProvider.login failed: $e');
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('currentUserId');
    notifyListeners();
  }

  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('currentUserId');
    if (id == null) return false;

    final user = await DatabaseService.getUserById(id);
    _currentUser = user;
    if (user != null) {
      notifyListeners();
      return true;
    }
    return false;
  }
}