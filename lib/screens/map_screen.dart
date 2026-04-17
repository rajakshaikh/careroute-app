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
  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final snap = await FirebaseFirestore.instance.collection('patients').get();

    final tempMarkers = <Marker>[];

    for (final doc in snap.docs) {
      final p = Patient.fromFirestore(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );

      if (p.lat == null || p.lng == null) continue;

      Color color;

      if (p.visited) {
        color = Colors.green;
      } else if (p.riskLabel == 'HIGH') {
        color = Colors.red;
      } else if (p.riskLabel == 'MEDIUM') {
        color = Colors.orange;
      } else {
        color = Colors.lightGreen;
      }

      tempMarkers.add(
        Marker(
          point: LatLng(p.lat, p.lng),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text(p.name),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            p.riskLabel,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(p.condition),
                      const SizedBox(height: 4),
                      Text('${p.lastVisitDays} days ago'),
                      const SizedBox(height: 4),
                      Text(
                        p.visited ? '✓ Visited' : 'Pending',
                        style: TextStyle(
                          color: p.visited ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Icon(Icons.location_on, color: color, size: 30),
          ),
        ),
      );
    }

    setState(() => markers = tempMarkers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Map'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: LatLng(20.9042, 75.5621),
          initialZoom: 13,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          ),
          MarkerLayer(markers: markers),
        ],
      ),
    );
  }
}
