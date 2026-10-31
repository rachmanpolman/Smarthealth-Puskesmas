import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _supabase = Supabase.instance.client;

  // Mendapatkan data user yang sedang login
  User? get currentUser => _supabase.auth.currentUser;

  // Format pesan error Auth agar ramah pengguna
  String _parseAuthError(dynamic e) {
    if (e is AuthException) {
      final msg = e.message.toLowerCase();
      if (msg.contains('invalid login credentials') || msg.contains('invalid_credentials')) {
        return 'Email atau password yang Anda masukkan salah. Silakan periksa kembali.';
      }
      if (msg.contains('user not found') || msg.contains('user_not_found')) {
        return 'Akun dengan email ini belum terdaftar. Silakan daftar terlebih dahulu.';
      }
      if (msg.contains('email not confirmed')) {
        return 'Email Anda belum dikonfirmasi. Silakan periksa kotak masuk email Anda.';
      }
      if (msg.contains('already registered') || msg.contains('already_exists')) {
        return 'Email ini sudah terdaftar. Silakan login atau gunakan email lain.';
      }
      if (msg.contains('password should be at least')) {
        return 'Password harus minimal 6 karakter.';
      }
      return e.message;
    }
    final str = e.toString();
    if (str.contains('SocketException') || str.contains('Failed host lookup') || str.contains('Network')) {
      return 'Gagal terhubung ke server. Pastikan HP Anda terhubung ke internet.';
    }
    return str.replaceAll('Exception: ', '');
  }

  // Fungsi REGISTER
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String namaLengkap,
  }) async {
    try {
      final AuthResponse response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _supabase.from('profil_pengguna').insert({
          'id': response.user!.id,
          'nama_lengkap': namaLengkap,
        });
      }
      return response;
    } catch (e) {
      throw Exception(_parseAuthError(e));
    }
  }

  // Fungsi LOGIN
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception(_parseAuthError(e));
    }
  }

  // Fungsi LOGOUT
  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  // Kirim Tautan Email Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.flutter://reset-callback',
      );
    } catch (e) {
      throw Exception(_parseAuthError(e));
    }
  }

  // Simpan Password Baru setelah klik tautan email
  Future<void> ubahPasswordBaru(String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception(_parseAuthError(e));
    }
  }
}
