import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/reservasi_model.dart';

class ReservasiService {
  final _supabase = Supabase.instance.client;

  // Membuat reservasi baru (Hasil id-nya akan jadi QR Code)
  Future<ReservasiModel> buatReservasi({
    required String jadwalId,
    required DateTime tanggalKunjungan,
    String? keluhan,
  }) async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final response = await _supabase
          .from('reservasi')
          .insert({
            'pengguna_id': userId,
            'jadwal_id': jadwalId,
            'tanggal_kunjungan': tanggalKunjungan.toIso8601String().split(
              'T',
            )[0],
            'keluhan': keluhan,
            'status': 'Menunggu',
          })
          .select()
          .single();

      return ReservasiModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Gagal membuat reservasi: ${e.message}');
      }
      throw Exception('Gagal membuat reservasi: $e');
    }
  }

  // Mengambil riwayat reservasi pengguna yang sedang login
  // Lengkap dengan data join tabel jadwal dan dokter
  Future<List<ReservasiModel>> getRiwayatReservasi() async {
    try {
      final userId = _supabase.auth.currentUser!.id;

      final List<dynamic> response = await _supabase
          .from('reservasi')
          .select('''
            *,
            jadwal_praktik (*, dokter (*))
          ''')
          .eq('pengguna_id', userId)
          .order('created_at', ascending: false);

      return response.map((data) => ReservasiModel.fromJson(data)).toList();
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Gagal memuat riwayat reservasi: ${e.message}');
      }
      throw Exception('Gagal memuat riwayat reservasi: $e');
    }
  }

  // Mengupdate data reservasi (tanggal kunjungan, keluhan, status)
  Future<ReservasiModel> updateReservasi({
    required String id,
    DateTime? tanggalKunjungan,
    String? keluhan,
    String? status,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      if (tanggalKunjungan != null) {
        updateData['tanggal_kunjungan'] =
            tanggalKunjungan.toIso8601String().split('T')[0];
      }
      if (keluhan != null) {
        updateData['keluhan'] = keluhan;
      }
      if (status != null) {
        updateData['status'] = status;
      }

      final response = await _supabase
          .from('reservasi')
          .update(updateData)
          .eq('id', id)
          .select('''
            *,
            jadwal_praktik (*, dokter (*))
          ''')
          .single();

      return ReservasiModel.fromJson(response);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Gagal mengupdate reservasi: ${e.message}');
      }
      throw Exception('Gagal mengupdate reservasi: $e');
    }
  }

  // Menghapus reservasi berdasarkan ID
  Future<void> deleteReservasi(String id) async {
    try {
      await _supabase.from('reservasi').delete().eq('id', id);
    } catch (e) {
      if (e is PostgrestException) {
        throw Exception('Gagal menghapus reservasi: ${e.message}');
      }
      throw Exception('Gagal menghapus reservasi: $e');
    }
  }
}
