class PuskesmasModel {
  final String id;
  final String nama;
  final String alamat;
  final double latitude;
  final double longitude;
  final String? noTelp;

  PuskesmasModel({
    required this.id,
    required this.nama,
    required this.alamat,
    required this.latitude,
    required this.longitude,
    this.noTelp,
  });

  // Konversi dari JSON Supabase ke Objek Dart
  factory PuskesmasModel.fromJson(Map<String, dynamic> json) {
    return PuskesmasModel(
      id: json['id'] as String,
      nama: json['nama'] as String,
      alamat: json['alamat'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      noTelp: json['no_telp'] as String?,
    );
  }

  // Konversi dari Objek Dart ke JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama': nama,
      'alamat': alamat,
      'latitude': latitude,
      'longitude': longitude,
      'no_telp': noTelp,
    };
  }
}
