import 'dokter_model.dart';

class JadwalPraktikModel {
  final String id;
  final String dokterId;
  final String hari;
  final String jamMulai;
  final String jamSelesai;
  final int kuota;
  final DokterModel? dokter; // Untuk data join dari tabel dokter

  JadwalPraktikModel({
    required this.id,
    required this.dokterId,
    required this.hari,
    required this.jamMulai,
    required this.jamSelesai,
    required this.kuota,
    this.dokter,
  });

  factory JadwalPraktikModel.fromJson(Map<String, dynamic> json) {
    return JadwalPraktikModel(
      id: json['id'] as String,
      dokterId: json['dokter_id'] as String,
      hari: json['hari'] as String,
      jamMulai: json['jam_mulai'] as String,
      jamSelesai: json['jam_selesai'] as String,
      kuota: json['kuota'] as int? ?? 20,
      dokter: json['dokter'] != null
          ? DokterModel.fromJson(json['dokter'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'dokter_id': dokterId,
      'hari': hari,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
      'kuota': kuota,
    };
  }
}
