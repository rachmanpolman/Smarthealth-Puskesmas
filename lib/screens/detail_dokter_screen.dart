import 'package:flutter/material.dart';
import '../models/dokter_model.dart';
import '../models/jadwal_praktik_model.dart';
import '../services/dokter_service.dart';
import '../services/reservasi_service.dart';

class DetailDokterScreen extends StatefulWidget {
  final DokterModel dokter;

  const DetailDokterScreen({super.key, required this.dokter});

  @override
  State<DetailDokterScreen> createState() => _DetailDokterScreenState();
}

class _DetailDokterScreenState extends State<DetailDokterScreen> {
  final DokterService _dokterService = DokterService();
  final ReservasiService _reservasiService = ReservasiService();

  List<JadwalPraktikModel> _jadwal = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  String? _selectedJadwalId;
  DateTime? _selectedTanggalKunjungan;
  final _keluhanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadJadwal();
  }

  void _tampilkanPesanError(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pesan.replaceAll('Exception: ', ''),
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _tampilkanPesanSukses(String pesan) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                pesan,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0D9488),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _loadJadwal() async {
    try {
      final data = await _dokterService.getJadwalDokter(widget.dokter.id);
      if (mounted) {
        setState(() {
          _jadwal = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _tampilkanPesanError('Gagal memuat jadwal dokter: $e');
      }
    }
  }

  // Menghitung tanggal terdekat yang sesuai dengan hari praktik dokter
  DateTime _hitungTanggalTerdekat(String hariIndo) {
    final Map<String, int> mapHari = {
      'senin': DateTime.monday,
      'selasa': DateTime.tuesday,
      'rabu': DateTime.wednesday,
      'kamis': DateTime.thursday,
      'jumat': DateTime.friday,
      'sabtu': DateTime.saturday,
      'minggu': DateTime.sunday,
    };

    final targetWeekday = mapHari[hariIndo.toLowerCase().trim()];
    DateTime now = DateTime.now();

    if (targetWeekday == null) {
      return now;
    }

    int daysToAdd = targetWeekday - now.weekday;
    if (daysToAdd < 0) {
      daysToAdd += 7; // Hari praktik minggu ini sudah lewat, pilih minggu depan
    }

    return DateTime(now.year, now.month, now.day).add(Duration(days: daysToAdd));
  }

  String _formatTanggal(DateTime dt) {
    final List<String> namaHari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final List<String> namaBulan = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
    ];

    final hariStr = namaHari[dt.weekday - 1];
    final bulanStr = namaBulan[dt.month - 1];

    return '$hariStr, ${dt.day} $bulanStr ${dt.year}';
  }

  Future<void> _buatReservasi() async {
    if (_selectedJadwalId == null || _selectedTanggalKunjungan == null) {
      _tampilkanPesanError('Silakan pilih jadwal praktik terlebih dahulu!');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await _reservasiService.buatReservasi(
        jadwalId: _selectedJadwalId!,
        tanggalKunjungan: _selectedTanggalKunjungan!,
        keluhan: _keluhanController.text.trim(),
      );

      if (mounted) {
        _tampilkanPesanSukses('Reservasi Berhasil! Silakan cek menu Reservasi Saya.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _tampilkanPesanError('Gagal membuat reservasi: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);
    final hasPhoto = widget.dokter.fotoDokter != null && widget.dokter.fotoDokter!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Dokter'),
        backgroundColor: primaryTeal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dokter Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryTeal.withValues(alpha: 0.1),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: hasPhoto
                                ? Image.network(
                                    widget.dokter.fotoDokter!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.person_rounded, size: 45, color: primaryTeal);
                                    },
                                  )
                                : const Icon(Icons.person_rounded, size: 45, color: primaryTeal),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.dokter.namaDokter,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: primaryTeal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.dokter.spesialisasi,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Deskripsi
                  if (widget.dokter.deskripsi != null && widget.dokter.deskripsi!.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Dokter',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.dokter.deskripsi!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Pilih Jadwal Praktik
                  const Text(
                    'Pilih Jadwal Praktik',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_jadwal.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Belum ada jadwal praktik tersedia untuk dokter ini.',
                              style: TextStyle(color: Colors.orange),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: _jadwal.map((j) {
                        final isSelected = _selectedJadwalId == j.id;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryTeal.withValues(alpha: 0.08) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? primaryTeal : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(14),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  _selectedJadwalId = j.id;
                                  _selectedTanggalKunjungan = _hitungTanggalTerdekat(j.hari);
                                });
                              },
                              leading: Icon(
                                isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
                                color: isSelected ? primaryTeal : Colors.grey,
                              ),
                              title: Text(
                                '${j.hari} (${j.jamMulai} - ${j.jamSelesai})',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? primaryTeal : const Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: Text('Sisa Kuota: ${j.kuota} pasien'),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                  // Tanggal Kunjungan Otomatis & Pemilih Tanggal (DatePicker)
                  if (_selectedTanggalKunjungan != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryTeal.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: primaryTeal,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal Kunjungan Otomatis',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: primaryTeal,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatTanggal(_selectedTanggalKunjungan!),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedTanggalKunjungan!,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 90)),
                              );
                              if (picked != null) {
                                setState(() => _selectedTanggalKunjungan = picked);
                              }
                            },
                            icon: const Icon(Icons.edit_calendar_rounded, size: 18, color: primaryTeal),
                            label: const Text('Ubah', style: TextStyle(color: primaryTeal, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Form Keluhan
                  const Text(
                    'Keluhan Penyakit',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),

                  TextField(
                    controller: _keluhanController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Tuliskan keluhan atau gejala yang Anda rasakan...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _jadwal.isEmpty ? null : _buatReservasi,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryTeal,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'BUAT RESERVASI SEKARANG',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
