// lib/screens/map_screen.dart — REPLACE ENTIRE FILE

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Patient> _patients = [];
  Patient? _selectedPatient; // tapped pin

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final snap = await FirebaseFirestore.instance
        .collection('patients')
        .where('chwId', isEqualTo: 'chw_001')
        .get();
    setState(() {
      _patients = snap.docs.map((d) =>
        Patient.fromFirestore(d.id, d.data() as Map<String, dynamic>)
      ).toList();
    });
  }

  Color _pinColor(Patient p) {
    if (p.visited)             return const Color(0xFF1D9E75); // green
    if (p.riskLabel == 'HIGH')   return const Color(0xFFE24B4A); // red
    if (p.riskLabel == 'MEDIUM') return const Color(0xFFEF9F27); // orange
    return const Color(0xFF639922);                               // light green
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Map'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPatients,
            tooltip: 'Refresh pins',
          ),
        ],
      ),
      body: Stack(
        children: [

          // ── THE MAP ──────────────────────────────────
          FlutterMap(
            options: const MapOptions(
              initialCenter: LatLng(20.9042, 75.5621), // Jalgaon
              initialZoom: 14,
            ),
            children: [
              // Free OpenStreetMap tiles — no key needed
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.careroute_app',
              ),

              // Patient pins
              MarkerLayer(
                markers: _patients.map((p) {
                  return Marker(
                    point: LatLng(p.lat, p.lng),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedPatient = p),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _pinColor(p),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          p.visited ? Icons.check : Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // ── POPUP when pin is tapped ─────────────────
          if (_selectedPatient != null)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: _pinColor(_selectedPatient!),
                        child: Text(
                          _selectedPatient!.riskLabel[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedPatient!.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              '${_selectedPatient!.condition} · '
                              '${_selectedPatient!.lastVisitDays} days ago',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            Text(
                              _selectedPatient!.visited
                                  ? '✓ Already visited'
                                  : '${_selectedPatient!.riskLabel} RISK — not yet visited',
                              style: TextStyle(
                                color: _pinColor(_selectedPatient!),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () =>
                            setState(() => _selectedPatient = null),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── LEGEND ───────────────────────────────────
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LegendItem(color: Color(0xFFE24B4A), label: 'High risk'),
                  _LegendItem(color: Color(0xFFEF9F27), label: 'Medium'),
                  _LegendItem(color: Color(0xFF639922), label: 'Low risk'),
                  _LegendItem(color: Color(0xFF1D9E75), label: 'Visited ✓'),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }
}

// Small legend row widget
class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}