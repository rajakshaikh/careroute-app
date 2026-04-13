// lib/screens/patient_list_screen.dart — REPLACE ENTIRE FILE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  Color riskColor(String label) {
    if (label == 'HIGH')   return Colors.red;
    if (label == 'MEDIUM') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Patients'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('chwId', isEqualTo: 'chw_001')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Something went wrong'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No patients found.'));
          }

          // Convert docs → Patient objects
          final patients = snapshot.data!.docs.map((doc) {
            return Patient.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
          }).toList();

          // Sort: highest risk first
          patients.sort((a, b) => b.riskScore.compareTo(a.riskScore));

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final p = patients[index];
              final color = riskColor(p.riskLabel);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PatientDetailScreen(patient: p),
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Text(
                      p.riskLabel[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${p.condition} · ${p.lastVisitDays} days ago',
                  ),
                  trailing: p.visited
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : const Icon(Icons.arrow_forward_ios,
                          size: 16, color: Colors.grey),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
