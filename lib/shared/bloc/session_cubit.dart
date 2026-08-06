import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sakinah/configurations/app_persistence_data_keys.dart';
import 'package:sakinah/configurations/app_states.dart';
import 'package:sakinah/handlers/security/AESEncryptor.dart';
import 'package:sakinah/handlers/security/encrypted_value.dart';
import 'package:sakinah/handlers/shared_handler.dart';
import 'package:sakinah/shared/models/user.dart';

/// # SessionCubit
/// ## Info
/// App-scoped cubit — the only place that reads/writes session data in
/// [SharedPrefHandler]. Anything in the app that needs to know whether the
/// user is logged in, or who they are, calls this — never
/// [SharedPrefHandler] directly for session keys.
class SessionCubit extends Cubit<AppStates> {
  SessionCubit._internal() : super(InitialState());
  static SessionCubit instance = SessionCubit._internal();
  //========================================
  //======================================== Variables
  //========================================
  User? _currentUser;

  bool get isLoggedIn => _currentUser != null;
  User? get currentUser => _currentUser;
  //========================================
  //======================================== Functions
  //========================================

  /// Reads the cached session from Hive only — never calls Supabase.
  /// Fails safe to an unauthenticated state on any corrupted/foreign data.
  Future<void> restoreSession() async {
    try {
      final prefs = SharedPrefHandler.instance;
      final hasSession = prefs != null &&
          prefs.contains(AppPersistenceDataKeys.isLogin) &&
          prefs.get<bool>(key: AppPersistenceDataKeys.isLogin) &&
          prefs.contains(AppPersistenceDataKeys.accessToken) &&
          prefs.contains(AppPersistenceDataKeys.refreshToken) &&
          prefs.contains(AppPersistenceDataKeys.userData);

      if (!hasSession) {
        _currentUser = null;
        emit(LoadedState(_currentUser));
        return;
      }

      // Tokens are decrypted here only to prove the cached session is
      // intact; SessionCubit does not expose them beyond this cubit today.
      _decryptToken(prefs.get<Map>(key: AppPersistenceDataKeys.accessToken));
      _decryptToken(prefs.get<Map>(key: AppPersistenceDataKeys.refreshToken));
      final userMap = prefs.get<Map>(key: AppPersistenceDataKeys.userData);
      _currentUser = User.fromJson(Map<String, dynamic>.from(userMap));

      emit(LoadedState(_currentUser));
    } catch (e) {
      log('SessionCubit.restoreSession failed, falling back to signed-out: $e');
      _currentUser = null;
      emit(LoadedState(_currentUser));
    }
  }

  /// Called once, by LoginBloc, right after a successful login + profile
  /// fetch. Encrypts both tokens independently (each gets its own IV) and
  /// writes all four Hive keys.
  Future<void> persistSession({
    required String accessToken,
    required String refreshToken,
    required User user,
  }) async {
    final prefs = SharedPrefHandler.instance!;
    await prefs.save(AppPersistenceDataKeys.isLogin, value: true);
    await prefs.save(AppPersistenceDataKeys.accessToken,
        value: _encryptToken(accessToken));
    await prefs.save(AppPersistenceDataKeys.refreshToken,
        value: _encryptToken(refreshToken));
    await prefs.save(AppPersistenceDataKeys.userData, value: user.toJson());

    _currentUser = user;
    emit(LoadedState(_currentUser));
  }

  Map<String, String> _encryptToken(String plainToken) {
    final encrypted = AESEncryptor.instance.encrypt(plainToken);
    return {
      'value': encrypted.encryptedValue,
      'iv': encrypted.ivKey,
    };
  }

  String _decryptToken(Map tokenMap) {
    final encryptedValue = EncryptedValue(
      encryptedValue: tokenMap['value'] as String,
      valueType: String,
      ivKey: tokenMap['iv'] as String?,
    );
    return AESEncryptor.instance.decrypt(encryptedValue) as String;
  }
}
