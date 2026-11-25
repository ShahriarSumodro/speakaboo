/// Authentication and user identity state provider.
library;

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../services/cache_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  UserProfile? _profile;
  String? _userId;
  String? _authToken;
  bool _isLoading = true;
  bool _serverConnected = true;
  String? _errorMessage;
  Timer? _healthTimer;

  AuthProvider({required ApiService api}) : _api = api;

  UserProfile? get profile => _profile;
  String get userId => _userId ?? 'anonymous';
  String? get authToken => _authToken;
  bool get isLoading => _isLoading;
  bool get serverConnected => _serverConnected;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _userId != null && _authToken != null;

  /// Check backend health and update connection state.
  Future<bool> checkHealth() async {
    try {
      final res = await _api.healthCheck();
      final isOk = res['status'] == 'ok' || res['status'] == 'degraded';
      if (isOk) {
        setServerConnected(true);
        if (_profile == null || _userId == null) {
          initialize();
        }
        return true;
      } else {
        setServerConnected(false);
        return false;
      }
    } catch (e) {
      setServerConnected(false);
      return false;
    }
  }

  void setServerConnected(bool connected) {
    if (_serverConnected != connected) {
      _serverConnected = connected;
      notifyListeners();
    }
    if (!connected) {
      _startHealthTimer();
    } else {
      _stopHealthTimer();
    }
  }

  void _startHealthTimer() {
    if (_healthTimer != null && _healthTimer!.isActive) return;
    _healthTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      checkHealth();
    });
  }

  void _stopHealthTimer() {
    _healthTimer?.cancel();
    _healthTimer = null;
  }

  /// Initialize user identity, obtaining or verifying device credentials.
  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _userId = await AuthStorage.getUserId();
      _authToken = await AuthStorage.getAuthToken();

      if (_authToken != null) {
        _api.setAuthToken(_authToken);
      }

      // Check if we need to authenticate device
      if (_userId == null || _authToken == null) {
        final deviceId = await AuthStorage.getDeviceId();
        final authRes = await _api.deviceAuth(deviceId: deviceId);
        _userId = authRes['user_id'] as String;
        _authToken = (authRes['auth_token'] ?? authRes['token']) as String?;
        if (_userId != null && _authToken != null) {
          await AuthStorage.saveAuth(userId: _userId!, authToken: _authToken!);
          _api.setAuthToken(_authToken);
        }
      }

      // Load profile (try cache first for speed, then refresh from network)
      final cached = await CacheService.get('profile_$_userId');
      if (cached != null) {
        try {
          _profile = UserProfile.fromJson(cached);
        } catch (_) {}
      }

      try {
        final remoteProfile = await _api.getProfile();
        _profile = remoteProfile;
        await CacheService.set('profile_$_userId', remoteProfile.toJson());
        setServerConnected(true);
      } catch (e) {
        // If cached profile exists or network call failed, probe health check
        final isHealthy = await checkHealth();
        if (!isHealthy && _profile == null) {
          _errorMessage = 'Could not connect to Speakaboo server';
        }
      }
    } catch (e) {
      setServerConnected(false);
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile.
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final updated = await _api.updateProfile(updates);
      _profile = updated;
      if (_userId != null) {
        await CacheService.set('profile_$_userId', updated.toJson());
      }
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Set 4-digit parent PIN.
  Future<bool> setParentPin(String pin) async {
    try {
      final success = await _api.setParentPin(pin);
      if (success && _profile != null) {
        _profile = _profile!.copyWith(hasParentPin: true);
        notifyListeners();
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Verify 4-digit parent PIN.
  Future<bool> verifyParentPin(String pin) async {
    try {
      return await _api.verifyParentPin(pin);
    } catch (_) {
      return false;
    }
  }

  /// Purge all user data and reset session.
  Future<bool> deleteAccount() async {
    if (_userId == null) return false;
    try {
      final ok = await _api.deleteUserData(_userId!);
      if (ok) {
        await AuthStorage.clear();
        await CacheService.clear();
        _userId = null;
        _authToken = null;
        _profile = null;
        _api.setAuthToken(null);
        notifyListeners();
      }
      return ok;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _stopHealthTimer();
    super.dispose();
  }
}
