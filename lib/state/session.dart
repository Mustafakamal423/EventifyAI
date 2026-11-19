import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/models.dart';

/// Who is logged in (UC01/UC02). The whole app listens to this object: when
/// [user] changes, main.dart swaps between the login screens, the attendee app
/// and the organizer's door tools.
class Session extends ChangeNotifier {
  User? user;
  bool ready = false; // false while we check the saved token at startup

  /// Set right after an attendee signs up, so the app opens profile setup first
  /// (the AI matching needs skills/interests/goals to work, FR-10).
  bool needsOnboarding = false;

  Session() {
    // If any request comes back 401 (token expired after 24h/12h, BR-14, or
    // revoked by logout), drop the session so the user lands on the login screen.
    api.onUnauthorized = () {
      if (user != null) _clear();
    };
  }

  bool get loggedIn => user != null;

  /// On app start: if a token was saved, ask the server who it belongs to.
  Future<void> restore() async {
    try {
      if (await api.loadToken() != null) {
        final res = await api.get('/auth/me');
        user = User.fromJson(res['user']);
      }
    } catch (_) {
      // Expired or invalid token, or offline: start logged out.
      await api.saveToken(null);
      user = null;
    }
    ready = true;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final res = await api.post('/auth/login', {'email': email.trim(), 'password': password});
    await _accept(res);
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    required String role,
  }) async {
    final res = await api.post('/auth/register', {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'phone_number': phone.trim(),
      'password': password,
      'role': role,
    });
    needsOnboarding = role == 'attendee';
    await _accept(res);
  }

  /// Logout revokes the token on the server (its jti goes on the blacklist),
  /// then forgets it on the phone.
  Future<void> logout() async {
    try {
      await api.post('/auth/logout');
    } catch (_) {
      // Logging out offline still clears the phone.
    }
    await _clear();
  }

  /// Re-reads the account (e.g. after confirming the email address).
  Future<void> refresh() async {
    final res = await api.get('/auth/me');
    user = User.fromJson(res['user']);
    notifyListeners();
  }

  Future<void> _accept(dynamic res) async {
    await api.saveToken(res['token']);
    user = User.fromJson(res['user']);
    notifyListeners();
  }

  Future<void> _clear() async {
    await api.saveToken(null);
    user = null;
    notifyListeners();
  }
}
