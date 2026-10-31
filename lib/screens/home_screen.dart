import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/profil_service.dart';
import 'login_screen.dart';
import 'map_screen.dart';
import 'daftar_dokter_screen.dart';
import 'qr_reservasi_screen.dart';
import 'profil_screen.dart';
import 'scan_qr_screen.dart';
import 'pengaturan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final ProfilService _profilService = ProfilService();

  String _namaUser = 'Pasien';
  String? _fotoProfil;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final profil = await _profilService.getProfil();
      if (mounted) {
        setState(() {
          _namaUser = profil.namaLengkap;
          _fotoProfil = profil.fotoProfil;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Puskesmas Peduli'),
        backgroundColor: primaryTeal,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Banner Profile Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: primaryTeal,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ProfilScreen()),
                      ).then((_) => _loadUserInfo());
                    },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(28),
                          child: _fotoProfil != null && _fotoProfil!.isNotEmpty
                              ? Image.network(
                                  _fotoProfil!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.person, size: 30, color: primaryTeal);
                                  },
                                )
                              : const Icon(Icons.person, size: 30, color: primaryTeal),
                        ),
                      ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selamat Datang,',
                          style: TextStyle(
                            color: Colors.teal.shade100,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _namaUser,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Puskesmas Pariwisata Sungailiat',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Emergency Banner Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade500],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryTeal.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    ContainerIcon(icon: Icons.support_agent_rounded, color: Colors.white),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Layanan Informasi & Darurat',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Telp: (0717) 94443 • Buka Setiap Hari',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Menu Dashboard Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Menu Utama',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 14),

                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.1,
                    children: [
                      // Menu 1: Peta Lokasi
                      _buildMenuCard(
                        context,
                        title: 'Lokasi & Navigasi',
                        subtitle: 'Peta Puskesmas GPS',
                        icon: Icons.map_rounded,
                        color: const Color(0xFF0284C7),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MapScreen()),
                        ),
                      ),

                      // Menu 2: Daftar Dokter
                      _buildMenuCard(
                        context,
                        title: 'Daftar Dokter',
                        subtitle: 'Jadwal & Spesialis',
                        icon: Icons.medical_services_rounded,
                        color: const Color(0xFF0D9488),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DaftarDokterScreen(),
                          ),
                        ),
                      ),

                      // Menu 3: Reservasi Saya
                      _buildMenuCard(
                        context,
                        title: 'Reservasi Saya',
                        subtitle: 'Kode Antrean QR',
                        icon: Icons.qr_code_rounded,
                        color: const Color(0xFFEA580C),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const QrReservasiScreen(),
                          ),
                        ),
                      ),

                      // Menu 4: Scan QR Reservasi
                      _buildMenuCard(
                        context,
                        title: 'Scan QR Antrean',
                        subtitle: 'Kamera Scanner',
                        icon: Icons.qr_code_scanner_rounded,
                        color: const Color(0xFF059669),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ScanQrScreen()),
                        ),
                      ),

                      // Menu 5: Profil Saya
                      _buildMenuCard(
                        context,
                        title: 'Profil Pengguna',
                        subtitle: 'Ubah Data & Foto',
                        icon: Icons.person_rounded,
                        color: const Color(0xFF7C3AED),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilScreen()),
                        ).then((_) => _loadUserInfo()),
                      ),

                      // Menu 6: Pengaturan
                      _buildMenuCard(
                        context,
                        title: 'Pengaturan',
                        subtitle: 'Info Aplikasi & Dev',
                        icon: Icons.settings_rounded,
                        color: const Color(0xFF475569),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const PengaturanScreen(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 30, color: color),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContainerIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  const ContainerIcon({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
