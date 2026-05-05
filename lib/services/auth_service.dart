import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'https://www.googleapis.com/auth/userinfo.profile',
      'https://www.googleapis.com/auth/gmail.readonly',
      'https://www.googleapis.com/auth/gmail.modify',
    ],
  );

  GoogleSignInAccount? _currentUser;

  // =========================
  // LOGIN
  // =========================
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      _currentUser = account;
      return account;
    } catch (e) {
      print("Login error: $e");
      return null;
    }
  }

  // =========================
  // AUTO RESTORE SESSION (QUAN TRỌNG)
  // =========================
  Future<GoogleSignInAccount?> trySilentLogin() async {
    try {
      final account = await _googleSignIn.signInSilently();
      _currentUser = account;
      return account;
    } catch (e) {
      print("Silent login error: $e");
      return null;
    }
  }

  // =========================
  // TOKEN
  // =========================
  Future<String?> getAccessToken() async {
    final user = _currentUser ?? _googleSignIn.currentUser;

    if (user == null) return null;

    final auth = await user.authentication;
    return auth.accessToken;
  }

  // =========================
  // CURRENT USER
  // =========================
  GoogleSignInAccount? get currentUser =>
      _currentUser ?? _googleSignIn.currentUser;

  // =========================
  // LOGOUT
  // =========================
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }
}
