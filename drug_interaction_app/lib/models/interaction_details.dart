class InteractionDetails {
  final String drug1;
  final String drug2;
  final String mechanismOfInteraction;
  final String alternatives;
  final String riskRating;
  final String source;

  InteractionDetails({
    required this.drug1,
    required this.drug2,
    required this.mechanismOfInteraction,
    required this.alternatives,
    required this.riskRating,
    required this.source,
  });

  factory InteractionDetails.fromJson(Map<String, dynamic> json) {
    return InteractionDetails(
      drug1: json['DRUG 1'] as String,
      drug2: json['DRUG 2'] as String,
      mechanismOfInteraction: json['MECHANISM OF INTERACTION'] as String,
      alternatives: json['ALTERNATIVES'] as String,
      riskRating: json['RISK RATING'] as String,
      source: json['SOURCE'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'DRUG 1': drug1,
    'DRUG 2': drug2,
    'MECHANISM OF INTERACTION': mechanismOfInteraction,
    'ALTERNATIVES': alternatives,
    'RISK RATING': riskRating,
    'SOURCE': source,
  };
} 