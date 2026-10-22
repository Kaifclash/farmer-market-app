import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';

class AuthProvider extends ChangeNotifier {
  static const _accountsKey = 'local_auth_accounts';
  static const _currentUserKey = 'local_auth_current_user';
  static const demoAdminEmail = 'admin@farmermarket.local';
  static const demoAdminPassword = 'admin123';
  final Map<String, Map<String, dynamic>> _accounts = {};

  LocalUser? _user;
  UserRole? _role;
  String? _accountStatus;
  String? _sellerStatus;
  Map<String, dynamic>? _profile;
  bool _isLoading = false;

  LocalUser? get user => _user;
  UserRole? get role => _role;
  String? get accountStatus => _accountStatus;
  String? get sellerStatus => _sellerStatus;
  Map<String, dynamic>? get profile => _profile;
  bool get isLoading => _isLoading;
  bool get isConfigured => true;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_accountsKey);
    if (stored != null) {
      try {
        final decoded = jsonDecode(stored);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Expected account records.');
        }
        for (final entry in decoded.entries) {
          if (entry.value is Map<String, dynamic>) {
            _accounts[entry.key] =
                Map<String, dynamic>.from(entry.value as Map<String, dynamic>);
          }
        }
      } on FormatException catch (error) {
        throw AuthOperationException(
          'Saved account data is unreadable. Clear app data and try again. (${error.message})',
        );
      }
    }
    if (!_accounts.values.any((account) => account['role'] == 'admin')) {
      final salt = _newSalt();
      const uid = 'local-demo-admin';
      _accounts[uid] = {
        'uid': uid,
        'name': 'Farmer Market Admin',
        'email': demoAdminEmail,
        'phone': '',
        'role': 'admin',
        'status': 'active',
        'sellerStatus': null,
        'passwordSalt': salt,
        'passwordHash': _passwordHash(salt, demoAdminPassword),
        'createdAt': DateTime.now().toIso8601String(),
      };
      await _saveAccounts();
    }
    final uid = prefs.getString(_currentUserKey);
    final account = uid == null ? null : _accounts[uid];
    if (account != null) {
      _setIdentity(account);
    } else if (uid != null) {
      await prefs.remove(_currentUserKey);
    }
  }

  Future<void> waitUntilReady() async {}

  Future<void> signIn(String email, String password) async {
    _startOperation();
    try {
      final account = _findAccount(email.trim().toLowerCase());
      if (account == null ||
          account['passwordHash'] !=
              _passwordHash(account['passwordSalt'] as String, password)) {
        throw const AuthOperationException(
            'The email or password is incorrect.');
      }
      if (account['status'] != 'active') {
        throw const AuthOperationException(
            'This account is suspended. Contact support.');
      }
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_currentUserKey, account['uid'] as String)) {
        throw const AuthOperationException(
            'Could not save the signed-in account on this device.');
      }
      _setIdentity(account);
    } finally {
      _finishOperation();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required bool asSeller,
    String? shopName,
  }) async {
    _startOperation();
    try {
      if (_findAccount(email.trim().toLowerCase()) != null) {
        throw const AuthOperationException(
            'An account already exists for this email.');
      }
      final salt = _newSalt();
      final uid =
          '${DateTime.now().microsecondsSinceEpoch}-${salt.substring(0, 8)}';
      final account = <String, dynamic>{
        'uid': uid,
        'name': name.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'role': asSeller ? 'seller' : 'customer',
        'status': 'active',
        'sellerStatus': asSeller ? 'pending' : null,
        if (asSeller)
          'shopName': shopName?.trim().isNotEmpty == true
              ? shopName!.trim()
              : name.trim(),
        'passwordSalt': salt,
        'passwordHash': _passwordHash(salt, password),
        'createdAt': DateTime.now().toIso8601String(),
      };
      _accounts[uid] = account;
      try {
        await _saveAccounts();
      } on AuthOperationException {
        _accounts.remove(uid);
        rethrow;
      }
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_currentUserKey, uid)) {
        _accounts.remove(uid);
        await _saveAccounts();
        throw const AuthOperationException(
            'Could not save the new account on this device.');
      }
      _setIdentity(account);
    } finally {
      _finishOperation();
    }
  }

  Future<void> resetPassword(String email, String password) async {
    final account = _findAccount(email.trim().toLowerCase());
    if (account == null) {
      throw const AuthOperationException('No account exists for this email.');
    }
    final oldSalt = account['passwordSalt'];
    final oldHash = account['passwordHash'];
    final salt = _newSalt();
    account['passwordSalt'] = salt;
    account['passwordHash'] = _passwordHash(salt, password);
    try {
      await _saveAccounts();
    } on AuthOperationException {
      account['passwordSalt'] = oldSalt;
      account['passwordHash'] = oldHash;
      rethrow;
    }
  }

  Future<void> signOut() async {
    _startOperation();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      _clearIdentity();
    } finally {
      _finishOperation();
    }
  }

  Future<List<Map<String, dynamic>>> getAccounts() async => _accounts.values
      .map((account) => {
            for (final entry in account.entries)
              if (entry.key != 'passwordHash' && entry.key != 'passwordSalt')
                entry.key: entry.value,
          })
      .toList(growable: false);

  Future<void> updateAccount({
    required String uid,
    String? accountStatus,
    String? sellerStatus,
  }) async {
    if (_role != UserRole.admin || _accountStatus != 'active') {
      throw const AuthOperationException(
          'Only an active admin can manage accounts.');
    }
    final account = _accounts[uid];
    if (account == null) {
      throw const AuthOperationException('Account not found on this device.');
    }
    final oldStatus = account['status'];
    final oldSellerStatus = account['sellerStatus'];
    if (accountStatus != null) account['status'] = accountStatus;
    if (sellerStatus != null) account['sellerStatus'] = sellerStatus;
    try {
      await _saveAccounts();
    } on AuthOperationException {
      account['status'] = oldStatus;
      account['sellerStatus'] = oldSellerStatus;
      rethrow;
    }
    if (_user?.uid == uid) _setIdentity(account);
    notifyListeners();
  }

  Map<String, dynamic>? _findAccount(String email) {
    for (final account in _accounts.values) {
      if ((account['email'] as String).toLowerCase() == email) return account;
    }
    return null;
  }

  Future<void> _saveAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_accountsKey, jsonEncode(_accounts))) {
      throw const AuthOperationException(
          'Could not save account data on this device.');
    }
  }

  void _setIdentity(Map<String, dynamic> account) {
    _user = LocalUser(
      uid: account['uid'] as String,
      email: account['email'] as String,
    );
    _role = switch (account['role']) {
      'customer' => UserRole.customer,
      'seller' => UserRole.seller,
      'admin' => UserRole.admin,
      _ => null,
    };
    _accountStatus = account['status'] as String? ?? 'active';
    _sellerStatus = account['sellerStatus'] as String?;
    _profile = {
      for (final entry in account.entries)
        if (entry.key != 'passwordHash' && entry.key != 'passwordSalt')
          entry.key: entry.value,
    };
  }

  void _clearIdentity() {
    _user = null;
    _role = null;
    _accountStatus = null;
    _sellerStatus = null;
    _profile = null;
  }

  void _startOperation() {
    _isLoading = true;
    notifyListeners();
  }

  void _finishOperation() {
    _isLoading = false;
    notifyListeners();
  }

  String _newSalt() =>
      List<int>.generate(16, (_) => Random.secure().nextInt(256))
          .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
          .join();

  String _passwordHash(String salt, String password) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}

class LocalUser {
  const LocalUser({required this.uid, required this.email});
  final String uid;
  final String email;
}

class AuthOperationException implements Exception {
  const AuthOperationException(this.message);
  final String message;
  @override
  String toString() => message;
}
