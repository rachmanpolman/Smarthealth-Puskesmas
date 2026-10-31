import 'jadwal_praktik_model.dart';
import 'profil_user_model.dart';

class ReservasiModel {
  final String id; // UUID unik ini yang dijadikan QR Code!
  final String penggunaId;
  final String jadwalId;
  final DateTime tanggalKunjungan;
  final String? keluhan;
  final String status;
  final DateTime? createdAt;
  final JadwalPraktikModel? jadwal; // Untuk data relasi JOIN
  final ProfilUserModel? pengguna; // Untuk data relasi JOIN

  ReservasiModel({
    required this.id,
    required this.penggunaId,
    required this.jadwalId,
    required this.tanggalKunjungan,
    this.keluhan,
    required this.status,
    this.createdAt,
    this.jadwal,
    this.pengguna,
  });

  factory ReservasiModel.fromJson(Map<String, dynamic> json) {
    return ReservasiModel(
      id: json['id'] as String,
      penggunaId: json['pengguna_id'] as String,
      jadwalId: json['jadwal_id'] as String,
      tanggalKunjungan: DateTime.parse(json['tanggal_kunjungan'] as String),
      keluhan: json['keluhan'] as String?,
      status: json['status'] as String? ?? 'Menunggu',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      jadwal: json['jadwal_praktik'] != null
          ? JadwalPraktikModel.fromJson(
              json['jadwal_praktik'] as Map<String, dynamic>,
            )
          : null,
      pengguna: json['profil_pengguna'] != null
          ? ProfilUserModel.fromJson(
              json['profil_pengguna'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'pengguna_id': penggunaId,
      'jadwal_id': jadwalId,
      'tanggal_kunjungan': tanggalKunjungan.toIso8601String().split('T')[0],
      'keluhan': keluhan,
      'status': status,
    };
  }
}
