import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient.dart';
import '../services/gemini_service.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PatientDetailScreen extends StatefulWidget {
  final Patient patient;
  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<String> checklist = [];
  bool isLoading = false;
  stt.SpeechToText speech = stt.SpeechToText();
  bool isListening = false;
  String spokenText = "";
  bool isGeneratingReport = false;
  Map<String, dynamic>? aiReport;

  Color riskColor(String label) {
    if (label == 'HIGH') return Colors.red;
    if (label == 'MEDIUM') return Colors.orange;
    return const Color.fromARGB(255, 76, 175, 120);
  }

  Widget _buildRiskBanner() {
    final color = riskColor(widget.patient.riskLabel);
    final reasons = widget.patient.riskReasons;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.45), width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_rounded, color: color),
              const SizedBox(width: 10),
              Text(
                '${widget.patient.riskLabel} RISK',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Why this risk level',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (reasons.isEmpty)
            Text(
              'No specific risk reasons available.',
              style: TextStyle(color: color),
            )
          else
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 8, color: color),
                    const SizedBox(width: 10),
                    Expanded(child: Text(reason)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override//line 99 this is what u gotta change
  void initState() {
    super.initState();
    loadPatientAIData();
  }

 Future<void> loadPatientAIData() async {
    final docRef = FirebaseFirestore.instance
        .collection('patients')
        .doc(widget.patient.id);

    final doc = await docRef.get();
    if (!doc.exists) return;

    final data = doc.data();
    if (data == null) return;

    // ✅ FIX 1: Look for 'aiChecklist' (This matches your save logic)
    final List<String>? savedChecklist = data['aiChecklist'] != null
        ? List<String>.from(data['aiChecklist'] as List<dynamic>)
        : null;

    Map<String, dynamic>? savedReport;
    if (data['aiReport'] != null) {
      final dynamic reportValue = data['aiReport'];
      if (reportValue is Map<String, dynamic>) {
        savedReport = reportValue;
      } else if (reportValue is Map) {
        savedReport = Map<String, dynamic>.from(reportValue);
      }
    }

    if (mounted) {
      setState(() {
        // ✅ FIX 2: Ensure the variable names match your State
        if (savedChecklist != null) checklist = savedChecklist;
        if (savedReport != null) aiReport = savedReport;
      });
    }
  }

  Future<void> loadChecklist() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      // Don't clear it immediately if you want to keep showing the old one while loading
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id);

      // ✅ 1. CALL GEMINI (Always get fresh data if they click the button)
      final result = await GeminiService.generateChecklist(
        widget.patient.condition,
        widget.patient.lastVisitDays,
      );

      // result is a List<String> coming from your service
      if (mounted) {
        setState(() {
          checklist = result;
        });
      }

      // ✅ 2. SAVE TO FIRESTORE using the SAME KEY as loadPatientAIData
      await docRef.update({'aiChecklist': result});

      debugPrint("Saved to Firestore ✅");
    } catch (e) {
      debugPrint("Checklist Error: $e");
      if (mounted) {
        setState(() {
          checklist = ["Error: Could not generate checklist. Try again."];
        });
      }
    }

    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> startListening() async {
    bool available = await speech.initialize();

    if (available) {
      setState(() => isListening = true);

      speech.listen(
        onResult: (result) {
          setState(() {
            spokenText = result.recognizedWords;
          });
        },
      );
    }
  }

  // 👉 ALSO add this right below it
  void stopListening() {
    speech.stop();
    setState(() => isListening = false);
  }

  Future<void> generateReport() async {
    setState(() { isGeneratingReport = true; });

    try {
      final report = await GeminiService.generateMedicalReport(
        spokenText,
        widget.patient.name,
        widget.patient.condition,
      );

      setState(() { aiReport = report; });

      // CREATE THE BATCH
      WriteBatch batch = FirebaseFirestore.instance.batch();
      DocumentReference patientRef = FirebaseFirestore.instance
          .collection('patients')
          .doc(widget.patient.id);
      DocumentReference reportHistoryRef = patientRef.collection('reports').doc();

      // ✅ STEP 1: Update Main Doc (FOR THE DASHBOARD)
      // We name the key 'aiReport' to match your React code exactly
      batch.update(patientRef, {
        'aiReport': report,
        'voiceNote': spokenText,
        'visited': true,
        'lastVisitDays': 0,
      });

      // ✅ STEP 2: Save to History (FOR ARCHIVE)
      batch.set(reportHistoryRef, {
        ...report,
        'time': DateTime.now().toIso8601String(),
      });

      await batch.commit();

      debugPrint("✅ Report Synced to Cloud & Dashboard!");
    } catch (e) {
      debugPrint("Report Error: $e");
    }

    setState(() { isGeneratingReport = false; });
  }

  @override
  Widget build(BuildContext context) {
    final color = riskColor(widget.patient.riskLabel);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.patient.name),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── RISK BANNER ──────────────────────────────
            _buildRiskBanner(),

            const SizedBox(height: 20),

            _sectionHeader('Patient Details'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoRow('Name', widget.patient.name),
                  const Divider(height: 24),
                  _infoRow('Age', '${widget.patient.age} months'),
                  const Divider(height: 24),
                  _infoRow('Condition', widget.patient.condition),
                  const Divider(height: 24),
                  _infoRow('Address', widget.patient.address),
                  const Divider(height: 24),
                  _infoRow(
                    'Last visited',
                    '${widget.patient.lastVisitDays} days ago',
                  ),
                  const Divider(height: 24),
                  _infoRow(
                    'Status',
                    widget.patient.visited
                        ? '✓ Visited today'
                        : 'Not yet visited',
                  ),
                ],
              ),
            ),

            _sectionHeader('AI Checklist'),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : loadChecklist,
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.psychology),
                label: Text(
                  isLoading ? 'Generating...' : 'Generate AI Checklist',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
            if (checklist.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Recommended Checklist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...checklist.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Icon(
                                Icons.check_circle_outline,
                                size: 18,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Text(item)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),
            _sectionHeader('Visit Notes'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: isListening ? stopListening : startListening,
                    icon: Icon(isListening ? Icons.mic_off : Icons.mic),
                    label: Text(
                      isListening ? 'Stop Recording' : 'Start Recording',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isListening
                          ? Colors.orange
                          : Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (spokenText.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        spokenText,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  if (spokenText.isNotEmpty) const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: spokenText.trim().isEmpty
                        ? null
                        : () async {
                            await FirebaseFirestore.instance
                                .collection('patients')
                                .doc(widget.patient.id)
                                .set({
                                  'voiceNote': spokenText,
                                  'voiceNoteTime': DateTime.now()
                                      .toIso8601String(),
                                }, SetOptions(merge: true));

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Saved to patient record'),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade800,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Save Voice Note'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionHeader('Latest AI Report'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    // Safety: Disable button if already generating or if input text is empty
                    onPressed: (isGeneratingReport || spokenText.trim().isEmpty)
                        ? null
                        : generateReport,
                    icon: isGeneratingReport
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.document_scanner),
                    label: Text(
                      isGeneratingReport
                          ? 'Generating Report...'
                          : 'Generate AI Report',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // PROTECTION: Only show the report box if aiReport is NOT null AND we aren't currently generating
                  if (aiReport != null && !isGeneratingReport)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.teal.shade100),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AI Medical Report',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // The '??' is your insurance policy against null fields
                          Text(
                            'Summary: ${aiReport!['summary'] ?? "Processing..."}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Symptoms: ${aiReport!['symptoms'] ?? "No symptoms noted"}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Action: ${aiReport!['action_taken'] ?? "Standard protocol"}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Recommendation: ${aiReport!['recommendation'] ?? "Monitor status"}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else if (isGeneratingReport)
                    // Show a helpful state while the user waits
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          "Gemini is analyzing your notes...",
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    // Initial State
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        'No AI report generated yet. Record notes and tap Generate AI Report.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            _sectionHeader('Saved Reports'),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .doc(widget.patient.id)
                  .collection('reports')
                  .orderBy('time', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No saved reports yet.');
                }

                final docs = snapshot.data!.docs;

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.teal.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Summary: ${data['summary'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Symptoms: ${data['symptoms'] ?? ''}'),
                          const SizedBox(height: 4),
                          Text('Action: ${data['action_taken'] ?? ''}'),
                          const SizedBox(height: 4),
                          Text(
                            'Recommendation: ${data['recommendation'] ?? ''}',
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['time'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 24),
            if (!widget.patient.visited)
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
                        .doc(widget.patient.id)
                        .update({
                          'visited': true,
                          'visitedAt': DateTime.now().toIso8601String(),
                        });

                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text(
                    'Mark Visit Done',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

            if (widget.patient.visited)
              const Center(
                child: Column(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Visit completed',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

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
