import 'package:supabase_flutter/supabase_flutter.dart';

class DokterModel {
  final String id;
  final String? puskesmasId;
  final String namaDokter;
  final String spesialisasi;
  final String? deskripsi;
  final String? fotoDokter;
  final DateTime? createdAt;

  DokterModel({
    required this.id,
    this.puskesmasId,
    required this.namaDokter,
    required this.spesialisasi,
    this.deskripsi,
    this.fotoDokter,
    this.createdAt,
  });

  factory DokterModel.fromJson(Map<String, dynamic> json) {
    String? foto = json['foto_dokter'] as String?;
    if (foto != null &&
        foto.isNotEmpty &&
        !foto.startsWith('http://') &&
        !foto.startsWith('https://')) {
      foto = Supabase.instance.client.storage
          .from('foto-dokter')
          .getPublicUrl(foto);
    }

    return DokterModel(
      id: json['id'] as String,
      puskesmasId: json['puskesmas_id'] as String?,
      namaDokter: json['nama_dokter'] as String,
      spesialisasi: json['spesialisasi'] as String,
      deskripsi: json['deskripsi'] as String?,
      fotoDokter: foto,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puskesmas_id': puskesmasId,
      'nama_dokter': namaDokter,
      'spesialisasi': spesialisasi,
      'deskripsi': deskripsi,
      'foto_dokter': fotoDokter,
    };
  }
}
