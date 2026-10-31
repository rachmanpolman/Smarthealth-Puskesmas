import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilUserModel {
  final String id; // Berelasi dengan auth.users.id
  final String namaLengkap;
  final String? noTelp;
  final String? alamat;
  final String? fotoProfil;
  final DateTime? createdAt;

  ProfilUserModel({
    required this.id,
    required this.namaLengkap,
    this.noTelp,
    this.alamat,
    this.fotoProfil,
    this.createdAt,
  });

  factory ProfilUserModel.fromJson(Map<String, dynamic> json) {
    String? foto = json['foto_profil'] as String?;
    if (foto != null &&
        foto.isNotEmpty &&
        !foto.startsWith('http://') &&
        !foto.startsWith('https://')) {
      foto = Supabase.instance.client.storage
          .from('foto-profil')
          .getPublicUrl(foto);
    }

    return ProfilUserModel(
      id: json['id'] as String,
      namaLengkap: json['nama_lengkap'] as String,
      noTelp: json['no_telp'] as String?,
      alamat: json['alamat'] as String?,
      fotoProfil: foto,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_lengkap': namaLengkap,
      'no_telp': noTelp,
      'alamat': alamat,
      'foto_profil': fotoProfil,
    };
  }
}
