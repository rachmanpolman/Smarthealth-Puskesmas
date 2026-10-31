import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ScanQrScreen extends StatefulWidget {
  const ScanQrScreen({super.key});

  @override
  State<ScanQrScreen> createState() => _ScanQrScreenState();
}

class _ScanQrScreenState extends State<ScanQrScreen> {
  final MobileScannerController _scannerController = MobileScannerController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _tampilkanDetailReservasi(BuildContext context, String reservasiId) async {
    if (_isProcessing) return;
    _isProcessing = true;

    // Hentikan sementara scanner kamera agar tidak terjadi trigger berulang/spam
    await _scannerController.stop();

    try {
      final data = await Supabase.instance.client
          .from('reservasi')
          .select(
            '*, jadwal_praktik(hari, jam_mulai, jam_selesai, dokter(nama_dokter, spesialisasi)), profil_pengguna(nama_lengkap, no_telp)',
          )
          .eq('id', reservasiId)
          .single();

      if (!mounted) return;

      final profil = data['profil_pengguna'];
      final jadwal = data['jadwal_praktik'];
      final dokter = jadwal != null ? jadwal['dokter'] : null;

      final namaPasien = profil != null ? profil['nama_lengkap'] ?? 'Pasien' : 'Pasien';
      final namaDokter = dokter != null ? dokter['nama_dokter'] ?? '-' : '-';
      final spesialisasi = dokter != null ? dokter['spesialisasi'] ?? '-' : '-';
      final hariJam = jadwal != null
          ? '${jadwal['hari']} (${jadwal['jam_mulai']} - ${jadwal['jam_selesai']})'
          : '-';
      final keluhan = data['keluhan'] != null && data['keluhan'].toString().isNotEmpty
          ? data['keluhan']
          : 'Tidak ada keluhan';
      final status = data['status'] ?? 'Menunggu';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF0D9488), size: 28),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Verifikasi Reservasi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                _buildDetailRow('Nama Pasien', namaPasien),
                _buildDetailRow('Dokter', namaDokter),
                _buildDetailRow('Spesialisasi', spesialisasi),
                _buildDetailRow('Hari & Jam', hariJam),
                _buildDetailRow('Keluhan', keluhan),
                _buildDetailRow('Status', status),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      // Jalankan kembali scanner kamera setelah dialog ditutup
                      await _scannerController.start();
                      if (mounted) setState(() => _isProcessing = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('SELESAI / SCAN LAGI', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      // Dialog Peringatan Ramah Pengguna jika QR Code tidak ditemukan / sudah dihapus
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: Colors.amber,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tiket Reservasi Tidak Ditemukan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Kode QR ini tidak terdaftar dalam sistem, atau reservasi sudah dibatalkan/dihapus oleh pengguna.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(dialogCtx);
                      await _scannerController.start();
                      if (mounted) setState(() => _isProcessing = false);
                    },
                    icon: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'SCAN LAGI',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Antrean'),
        backgroundColor: primaryTeal,
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty && !_isProcessing) {
                final String? qrData = barcodes.first.rawValue;
                if (qrData != null) {
                  _tampilkanDetailReservasi(context, qrData);
                }
              }
            },
          ),
          // Overlay Target Frame
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: primaryTeal, width: 3),
                borderRadius: BorderRadius.circular(20),
                color: Colors.black.withValues(alpha: 0.05),
              ),
            ),
          ),
          // Top Instruction Badge
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Arahkan kamera ke QR Code tiket reservasi pasien',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
