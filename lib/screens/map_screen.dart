import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/puskesmas_service.dart';
import '../models/puskesmas_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final PuskesmasService _puskesmasService = PuskesmasService();
  final MapController _mapController = MapController();
  
  PuskesmasModel? _puskesmas;
  bool _isLoading = true;
  String _jarakText = "Menghitung jarak...";
  Position? _currentPosition;
  List<LatLng> _routePoints = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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
                pesan.replaceAll('Exception: ', '').replaceAll('Error: ', ''),
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

  Future<void> _loadData() async {
    try {
      final data = await _puskesmasService.getLokasiPuskesmas();
      setState(() => _puskesmas = data);
      await _hitungJarakDanRute();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _tampilkanPesanError('Gagal memuat peta lokasi Puskesmas: $e');
      }
    }
  }

  Future<void> _hitungJarakDanRute() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _jarakText = "Izin lokasi ditolak.");
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _jarakText = "Izin lokasi ditolak permanen.");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      _currentPosition = position;

      double distanceInMeters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        _puskesmas!.latitude,
        _puskesmas!.longitude,
      );

      setState(() {
        _jarakText =
            "Jarak ke Puskesmas: ${(distanceInMeters / 1000).toStringAsFixed(2)} KM";
      });

      // Ambil Rute Pengendara dari OSRM Routing Engine (OpenStreetMap)
      await _fetchRouteGeometry(position);
    } catch (e) {
      setState(() => _jarakText = "Gagal mengambil lokasi.");
    }
  }

  Future<void> _fetchRouteGeometry(Position userPos) async {
    try {
      final puskLat = _puskesmas!.latitude;
      final puskLng = _puskesmas!.longitude;
      final userLat = userPos.latitude;
      final userLng = userPos.longitude;

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/$userLng,$userLat;$puskLng,$puskLat?overview=full&geometries=geojson',
      );

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(url);
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final coords = data['routes'][0]['geometry']['coordinates'] as List;
          final points = coords.map((c) => LatLng(c[1].toDouble(), c[0].toDouble())).toList();

          if (mounted) {
            setState(() {
              _routePoints = points;
            });

            // Sesuaikan kamera agar garis rute dan kedua lokasi terlihat pas di layar
            _fitMapBounds(userLat, userLng, puskLat, puskLng);
          }
          return;
        }
      }
    } catch (_) {}

    // Fallback jika API OSRM tidak merespons: Buat garis lurus antar lokasi
    if (mounted) {
      setState(() {
        _routePoints = [
          LatLng(userPos.latitude, userPos.longitude),
          LatLng(_puskesmas!.latitude, _puskesmas!.longitude),
        ];
      });
      _fitMapBounds(userPos.latitude, userPos.longitude, _puskesmas!.latitude, _puskesmas!.longitude);
    }
  }

  void _fitMapBounds(double lat1, double lng1, double lat2, double lng2) {
    try {
      final bounds = LatLngBounds.fromPoints([
        LatLng(lat1, lng1),
        LatLng(lat2, lng2),
      ]);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(60.0)),
      );
    } catch (_) {}
  }

  Future<void> _bukaNavigasi() async {
    if (_puskesmas == null) return;

    final lat = _puskesmas!.latitude;
    final lng = _puskesmas!.longitude;
    final namaPuskesmas = Uri.encodeComponent(_puskesmas!.nama);

    final googleNavUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final geoUrl = Uri.parse('geo:$lat,$lng?q=$lat,$lng($namaPuskesmas)');
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      if (await canLaunchUrl(googleNavUrl)) {
        await launchUrl(googleNavUrl, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(geoUrl)) {
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      try {
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (mounted) {
          _tampilkanPesanError('Gagal membuka aplikasi peta.');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF0D9488);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi & Navigasi Puskesmas'),
        backgroundColor: primaryTeal,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryTeal))
          : Column(
              children: [
                Expanded(
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(
                        _puskesmas!.latitude,
                        _puskesmas!.longitude,
                      ),
                      initialZoom: 16.0,
                      minZoom: 3.0,
                      maxZoom: 19.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.flutter_application_1',
                        maxZoom: 19,
                        maxNativeZoom: 19,
                      ),

                      // Garis Jalur Navigasi Rute (Polyline)
                      if (_routePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: _routePoints,
                              strokeWidth: 5.0,
                              color: primaryTeal,
                            ),
                          ],
                        ),

                      MarkerLayer(
                        markers: [
                          // Marker Puskesmas
                          Marker(
                            point: LatLng(
                              _puskesmas!.latitude,
                              _puskesmas!.longitude,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.local_hospital_rounded,
                                color: primaryTeal,
                                size: 32,
                              ),
                            ),
                          ),
                          // Marker Lokasi Saya (jika ada)
                          if (_currentPosition != null)
                            Marker(
                              point: LatLng(
                                _currentPosition!.latitude,
                                _currentPosition!.longitude,
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
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
                                  Icons.person_pin_circle_rounded,
                                  color: Colors.blueAccent,
                                  size: 32,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Panel Jarak & Tombol Navigasi
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 15,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryTeal.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.location_on_rounded, color: primaryTeal),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _puskesmas?.nama ?? 'Puskesmas',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _puskesmas?.alamat ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.directions_walk_rounded, color: Colors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _jarakText,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _bukaNavigasi,
                          icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                          label: const Text(
                            'PETUNJUK ARAH GOOGLE MAPS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryTeal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
