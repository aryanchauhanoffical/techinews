import '../models/user.dart';

enum AuthProvider { google, apple, github, email }

abstract class AuthRepository {
  Future<AppUser?> currentUser();
  Future<AppUser> signIn(AuthProvider provider, {String? email});
  Future<void> signOut();
  Future<AppUser> updateProfile({
    List<String>? interests,
    NotificationMode? notificationMode,
  });
}

class MockAuthRepository implements AuthRepository {
  AppUser? _user;

  @override
  Future<AppUser?> currentUser() async => _user;

  @override
  Future<AppUser> signIn(AuthProvider provider, {String? email}) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    _user = AppUser(
      id: 'mock_user_1',
      email: email ?? 'demo@techinews.app',
      displayName: 'Demo User',
      createdAt: DateTime.now(),
    );
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
  }

  @override
  Future<AppUser> updateProfile({
    List<String>? interests,
    NotificationMode? notificationMode,
  }) async {
    _user = _user!.copyWith(
      interests: interests,
      notificationMode: notificationMode,
    );
    return _user!;
  }
}
