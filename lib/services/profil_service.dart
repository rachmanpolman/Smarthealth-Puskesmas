import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profil_user_model.dart';

class ProfilService {
  final _supabase = Supabase.instance.client;

  // Mengambil data profil user saat ini
  Future<ProfilUserModel> getProfil() async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final response = await _supabase
          .from('profil_pengguna')
          .select()
          .eq('id', userId)
          .single();

      return ProfilUserModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat profil: $e');
    }
  }

  // Memperbarui data profil
  Future<void> updateProfil({
    required String nama,
    String? noTelp,
    String? alamat,
    String? fotoProfil,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final updateData = <String, dynamic>{
        'nama_lengkap': nama,
        'no_telp': noTelp,
        'alamat': alamat,
      };
      if (fotoProfil != null) {
        updateData['foto_profil'] = fotoProfil;
      }

      await _supabase
          .from('profil_pengguna')
          .update(updateData)
          .eq('id', userId);
    } catch (e) {
      throw Exception('Gagal memperbarui profil: $e');
    }
  }

  // Unggah foto profil ke Supabase Storage Bucket 'foto-profil'
  Future<String> uploadFotoProfil(XFile imageFile) async {
    try {
      final userId = _supabase.auth.currentUser!.id;
      final bytes = await imageFile.readAsBytes();
      final fileExt = imageFile.name.split('.').last;
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.$fileExt';

      // Upload file ke bucket 'foto-profil'
      await _supabase.storage.from('foto-profil').uploadBinary(
        fileName,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Ambil Public URL foto yang di-upload
      final publicUrl = _supabase.storage
          .from('foto-profil')
          .getPublicUrl(fileName);

      // Simpan URL ke tabel profil_pengguna
      await _supabase
          .from('profil_pengguna')
          .update({'foto_profil': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      throw Exception('Gagal mengunggah foto profil: $e');
    }
  }
}
