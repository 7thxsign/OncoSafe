class DrugInteraction {
  final String drug1;
  final String drug2;
  final String mechanism;
  final String alternatives;
  final String riskRating;

  DrugInteraction({
    required this.drug1,
    required this.drug2,
    required this.mechanism,
    required this.alternatives,
    required this.riskRating,
  });

  factory DrugInteraction.fromCsv(List<String> row) {
    return DrugInteraction(
      drug1: row[0],
      drug2: row[1],
      mechanism: row[2],
      alternatives: row[3],
      riskRating: row[4],
    );
  }

  Map<String, dynamic> toJson() => {
        'drug1': drug1,
        'drug2': drug2,
        'mechanism': mechanism,
        'alternatives': alternatives,
        'riskRating': riskRating,
      };

  static String getRiskDescription(String rating) {
    switch (rating) {
      case 'X':
        return 'High Risk - Avoid Combination';
      case 'D':
        return 'Moderate Risk - Consider Modification';
      case 'C':
        return 'Low Risk - Monitor';
      default:
        return 'Unknown Risk';
    }
  }
} 