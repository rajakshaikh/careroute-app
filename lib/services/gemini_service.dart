import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// DO NOT paste your long key here anymore! 
// This line below tells the app to go look inside the .env file.
final String apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

class GeminiService {
  // ─────────────────────────────
  // 1. CHECKLIST (BEFORE VISIT)
  // ─────────────────────────────
  static Future<List<String>> generateChecklist(
      String condition, int lastVisitDays) async {
    
    final url =
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey";

    final prompt = """
You are a healthcare assistant.
Generate a short checklist (3 to 5 points) for a health worker visiting a patient.
Condition: $condition
Days since last visit: $lastVisitDays
Return ONLY bullet points.
""";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      final data = jsonDecode(response.body);

      if (data['candidates'] == null || data['candidates'].isEmpty) {
        return ["No recommendations available at this time."];
      }

      final String text =
          data['candidates'][0]['content']['parts'][0]['text'] ?? "";

      // FIX: Explicitly type the functions to (String e)
      List<String> lines = text
          .split('\n')
          .map((String e) => e.trim()) // Clean whitespace
          .where((String e) => e.isNotEmpty) // Filter empty lines (This was your error!)
          .map((String e) => e.replaceFirst(RegExp(r'^[*•\-\d\.]+\s*'), '')) // Remove AI bullets
          .toList();

      return lines;
    } catch (e) {
      print("Checklist Error: $e");
      rethrow;
    }
  }

  // ─────────────────────────────
  // 2. MEDICAL REPORT (AFTER VISIT)
  // ─────────────────────────────
  static Future<Map<String, dynamic>> generateMedicalReport(
    String speech,
    String patientName,
    String condition,
  ) async {

    final url =
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$apiKey";

    final prompt = """
You are a medical assistant for ASHA workers.
Convert the visit notes into a structured medical report.
Patient Name: $patientName
Condition: $condition
Notes: $speech

Return ONLY JSON:
{
  "summary": "",
  "symptoms": [],
  "action_taken": "",
  "recommendation": ""
}
""";

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      final data = jsonDecode(response.body);

      final String text =
          data['candidates'][0]['content']['parts'][0]['text'] ?? "";

      // Clean up the JSON if AI wraps it in markdown blocks
      final cleaned = text
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      return jsonDecode(cleaned) as Map<String, dynamic>;
    } catch (e) {
      print("Medical Report Error: $e");
      rethrow;
    }
  }
}