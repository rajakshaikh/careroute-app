// lib/models/patient.dart

class Patient {
  final String id;
  final String name;
  final int age;
  final String condition;
  final int lastVisitDays;
  final String address;
  //final String chwId;
  final bool visited;
  final double lat;
  final double lng;
  final String notes;
  final bool flaggedByANM;
  final String regionId;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.condition,
    required this.lastVisitDays,
    required this.address,
    //required this.chwId,
    required this.visited,
    required this.lat,
    required this.lng,
    required this.notes,
    required this.flaggedByANM,
    required this.regionId

  });

  // Convert Firestore document → Patient object
  factory Patient.fromFirestore(String id, Map<String, dynamic> data) {
    return Patient(
      id:            id,
      name:          data['name'] ?? '',
      age:           (data['age'] ?? 0).toInt(),
      condition:     data['condition'] ?? '',
      lastVisitDays: (data['lastVisitDays'] ?? 0).toInt(),
      address:       data['address'] ?? '',
      //chwId:         data['chwId'] ?? '',
      visited:       data['visited'] ?? false,
      lat:           (data['lat'] ?? 0.0).toDouble(),
      lng:           (data['lng'] ?? 0.0).toDouble(),
      notes:         data['notes'] ?? '',
      flaggedByANM:  data['flaggedByANM'] ?? false,
      regionId:      data['regionId'] ?? '',
    );
  }

  // Risk score — same logic as before, just moved here
  int get riskScore {
    int score = 0;
    if (lastVisitDays > 14) {
      score += 40;
    } else if (lastVisitDays > 7) {
      score += 20;
    } else {
      score += 5;
    }
    
    if (['malnutrition', 'tb', 'postpartum'].contains(condition.toLowerCase())) {
      score += 50;
    } else {
      score += 10;
    }
    return score;
  }

  String get riskLabel {
    if (riskScore >= 70) return 'HIGH';
    if (riskScore >= 40) return 'MEDIUM';
    return 'LOW';
  }

  // Human-readable reason WHY this patient is high risk
  List<String> get riskReasons {
    List<String> reasons = [];
    if (lastVisitDays > 14) {
      reasons.add('No visit in $lastVisitDays days (very overdue)');
    } else if (lastVisitDays > 7) {
      reasons.add('No visit in $lastVisitDays days (overdue)');
    }
    if (['malnutrition', 'tb', 'postpartum'].contains(condition.toLowerCase())) {
      reasons.add('High-risk condition: $condition');
    }
    if (reasons.isEmpty) reasons.add('Stable — routine check');
    return reasons;
  }
}
