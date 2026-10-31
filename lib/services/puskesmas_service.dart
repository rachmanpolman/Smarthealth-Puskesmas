import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/puskesmas_model.dart';

class PuskesmasService {
  final _supabase = Supabase.instance.client;

  // Mengambil data Puskesmas (Titik Lokasi GPS)
  Future<PuskesmasModel> getLokasiPuskesmas() async {
    try {
      // Karena puskesmas hanya 1, kita ambil single()
      final response = await _supabase
          .from('puskesmas')
          .select()
          .limit(1)
          .single();

      return PuskesmasModel.fromJson(response);
    } catch (e) {
      throw Exception('Gagal memuat data lokasi puskesmas: $e');
    }
  }
}
