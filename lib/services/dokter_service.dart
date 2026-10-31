import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/dokter_model.dart';
import '../models/jadwal_praktik_model.dart';

class DokterService {
  final _supabase = Supabase.instance.client;

  // Mengambil semua daftar dokter
  Future<List<DokterModel>> getDaftarDokter() async {
    try {
      final List<dynamic> response = await _supabase.from('dokter').select();
      return response.map((data) => DokterModel.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Gagal memuat daftar dokter: $e');
    }
  }

  // Mengambil jadwal praktik berdasarkan ID Dokter
  Future<List<JadwalPraktikModel>> getJadwalDokter(String dokterId) async {
    try {
      final List<dynamic> response = await _supabase
          .from('jadwal_praktik')
          .select()
          .eq('dokter_id', dokterId);

      return response.map((data) => JadwalPraktikModel.fromJson(data)).toList();
    } catch (e) {
      throw Exception('Gagal memuat jadwal praktik: $e');
    }
  }
}
