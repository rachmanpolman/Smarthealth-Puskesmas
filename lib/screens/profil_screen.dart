import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/profil_service.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final ProfilService _profilService = ProfilService();
  final ImagePicker _picker = ImagePicker();

  final _namaController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _alamatController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploadingFoto = false;
  String _email = '';
  String? _fotoProfilUrl;

  @override
  void initState() {
    super.initState();
    _loadProfil();
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

  Future<void> _loadProfil() async {
    try {
      _email = Supabase.instance.client.auth.currentUser?.email ?? '';
      final profil = await _profilService.getProfil();

      if (mounted) {
        setState(() {
          _namaController.text = profil.namaLengkap;
          _noTelpController.text = profil.noTelp ?? '';
          _alamatController.text = profil.alamat ?? '';
          _fotoProfilUrl = profil.fotoProfil;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _tampilkanPesanError('Gagal memuat data profil: $e');
      }
    }
  }

  Future<void> _pilihDanUploadFoto(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingFoto = true);

      final newUrl = await _profilService.uploadFotoProfil(pickedFile);

      if (mounted) {
        setState(() {
          _fotoProfilUrl = newUrl;
          _isUploadingFoto = false;
        });
        _tampilkanPesanSukses('Foto profil berhasil diperbarui!');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingFoto = false);
        _tampilkanPesanError('Gagal mengunggah foto profil. Silakan coba lagi.');
      }
    }
  }

  void _tampilkanModalOpsiFoto() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ganti Foto Profil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const ContainerIcon(icon: Icons.photo_library, color: Colors.teal),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pilihDanUploadFoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const ContainerIcon(icon: Icons.camera_alt, color: Colors.blue),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(context);
                  _pilihDanUploadFoto(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _simpanProfil() async {
    setState(() => _isSaving = true);
    try {
      await _profilService.updateProfil(
        nama: _namaController.text.trim(),
        noTelp: _noTelpController.text.trim(),
        alamat: _alamatController.text.trim(),
        fotoProfil: _fotoProfilUrl,
      );
      if (mounted) {
        _tampilkanPesanSukses('Profil berhasil disimpan!');
      }
    } catch (e) {
      if (mounted) {
        _tampilkanPesanError('Gagal menyimpan profil: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        backgroundColor: primaryTeal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  // Profile Photo Avatar with Edit Badge
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 108,
                          height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: primaryTeal, width: 3),
                            color: Colors.teal.shade50,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(54),
                            child: _isUploadingFoto
                                ? const Center(child: CircularProgressIndicator(color: primaryTeal))
                                : (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty
                                    ? Image.network(
                                        _fotoProfilUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return const Icon(Icons.person, size: 55, color: primaryTeal);
                                        },
                                      )
                                    : const Icon(Icons.person, size: 55, color: primaryTeal)),
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: _isUploadingFoto ? null : _tampilkanModalOpsiFoto,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: primaryTeal,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Email Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryTeal.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined, size: 16, color: primaryTeal),
                        const SizedBox(width: 6),
                        Text(
                          _email,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: primaryTeal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Form Container Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informasi Pribadi',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 18),

                        TextField(
                          controller: _namaController,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline, color: primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _noTelpController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Nomor Telepon / WhatsApp',
                            prefixIcon: Icon(Icons.phone_outlined, color: primaryTeal),
                          ),
                        ),
                        const SizedBox(height: 16),

                        TextField(
                          controller: _alamatController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Alamat Lengkap',
                            alignLabelWithHint: true,
                            prefixIcon: Padding(
                              padding: EdgeInsets.only(bottom: 40),
                              child: Icon(Icons.location_on_outlined, color: primaryTeal),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isSaving ? null : _simpanProfil,
                            icon: _isSaving
                                ? const SizedBox.shrink()
                                : const Icon(Icons.save_rounded, color: Colors.white),
                            label: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    'SIMPAN PERUBAHAN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryTeal,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color),
    );
  }
}
