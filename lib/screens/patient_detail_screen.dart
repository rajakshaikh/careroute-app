// lib/screens/patient_detail_screen.dart — CREATE THIS FILE

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';

class PatientDetailScreen extends StatelessWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});

  Color riskColor(String label) {
    if (label == 'HIGH')   return Colors.red;
    if (label == 'MEDIUM') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final color = riskColor(patient.riskLabel);

    return Scaffold(
      appBar: AppBar(
        title: Text(patient.name),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── RISK BANNER ──────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                border: Border.all(color: color, width: 1.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.warning_rounded, color: color),
                    const SizedBox(width: 8),
                    Text(
                      '${patient.riskLabel} RISK',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  // Show WHY this patient is high risk
                  Text(
                    'Why this risk level:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...patient.riskReasons.map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Icon(Icons.circle, size: 8, color: color),
                      const SizedBox(width: 8),
                      Expanded(child: Text(reason)),
                    ]),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── PATIENT DETAILS ───────────────────────────
            const Text(
              'Patient Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _infoRow('Name',        patient.name),
            _infoRow('Age',         '${patient.age} months'),
            _infoRow('Condition',   patient.condition),
            _infoRow('Address',     patient.address),
            _infoRow('Last visited', '${patient.lastVisitDays} days ago'),
            _infoRow('Status',
              patient.visited ? '✓ Visited today' : 'Not yet visited'),

            const SizedBox(height: 32),

            // ── MARK DONE BUTTON ─────────────────────────
            if (!patient.visited)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('patients')
                        .doc(patient.id)
                        .update({
                      'visited':   true,
                      'visitedAt': DateTime.now().toIso8601String(),
                    });
                    // Go back to list after marking done
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Mark Visit Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (patient.visited)
              const Center(
                child: Column(children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 48),
                  SizedBox(height: 8),
                  Text('Visit completed',
                    style: TextStyle(color: Colors.green, fontSize: 16)),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  // Helper widget for info rows
  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
