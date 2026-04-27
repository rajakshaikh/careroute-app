import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatelessWidget {
  final String regionId;

  const PatientListScreen({super.key, required this.regionId});

  Color riskColor(String label) {
    if (label == 'HIGH') return Colors.red;
    if (label == 'MEDIUM') return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Assigned Patients",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color.fromARGB(255, 106, 219, 208),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .where('regionId', isEqualTo: regionId)
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

          final patients = snapshot.data!.docs
              .map(
                (doc) => Patient.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .where((p) => p.regionId == regionId)
              .toList();

          patients.sort((a, b) => b.riskScore.compareTo(a.riskScore));

          final total = patients.length;
          final visited = patients.where((p) => p.visited).length;
          final highPending = patients
              .where((p) => p.riskLabel == 'HIGH' && !p.visited)
              .length;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Field Progress',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$visited / $total Visits',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Chip(
                            backgroundColor: highPending > 0
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            label: Text(
                              '$highPending High risk',
                              style: TextStyle(
                                color: highPending > 0
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: LinearProgressIndicator(
                          value: total > 0 ? visited / total : 0,
                          backgroundColor: Colors.teal.withOpacity(0.15),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.teal,
                          ),
                          minHeight: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: patients.length,
                  itemBuilder: (context, index) {
                    final p = patients[index];
                    final color = riskColor(p.riskLabel);
                    return Opacity(
                      opacity: p.visited ? 0.65 : 1.0,
                      child: Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PatientDetailScreen(patient: p),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: color.withOpacity(0.2),
                                  child: Text(
                                    p.riskLabel[0],
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          Chip(
                                            label: Text(p.condition),
                                            visualDensity:
                                                VisualDensity.compact,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                          ),
                                          Chip(
                                            label: Text(
                                              '${p.lastVisitDays} days ago',
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            backgroundColor:
                                                Colors.grey.shade100,
                                          ),
                                          Chip(
                                            label: Text(
                                              p.visited ? 'Visited' : 'Pending',
                                            ),
                                            visualDensity:
                                                VisualDensity.compact,
                                            backgroundColor: p.visited
                                                ? Colors.green.shade50
                                                : Colors.orange.shade50,
                                            labelStyle: TextStyle(
                                              color: p.visited
                                                  ? Colors.green.shade700
                                                  : Colors.orange.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        p.riskLabel,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
