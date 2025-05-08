import 'package:ml_algo/ml_algo.dart';
import 'package:ml_dataframe/ml_dataframe.dart';
import '../models/drug_interaction.dart';

class MLPredictionService {
  static final MLPredictionService _instance = MLPredictionService._internal();
  factory MLPredictionService() => _instance;
  MLPredictionService._internal();

  Map<String, List<String>> _drugMechanisms = {};
  Map<String, Set<String>> _drugInteractors = {};
  Map<String, List<String>> _riskPatterns = {};
  List<List<double>> _trainingFeatures = [];
  List<String> _trainingLabels = [];

  void trainModel(List<DrugInteraction> interactions) {
    // Build drug interaction patterns
    for (var interaction in interactions) {
      _updateDrugPatterns(interaction);
    }

    // Prepare training data
    _trainingFeatures = [];
    _trainingLabels = [];

    for (var interaction in interactions) {
      var feature = _extractFeatures(interaction.drug1, interaction.drug2);
      _trainingFeatures.add(feature);
      _trainingLabels.add(interaction.riskRating);
    }

    print('Trained with ${_trainingFeatures.length} interactions');
  }

  void _updateDrugPatterns(DrugInteraction interaction) {
    // Store mechanism patterns
    _drugMechanisms.putIfAbsent(interaction.drug1, () => []).add(interaction.mechanism);
    _drugMechanisms.putIfAbsent(interaction.drug2, () => []).add(interaction.mechanism);

    // Store interaction partners
    _drugInteractors.putIfAbsent(interaction.drug1, () => {}).add(interaction.drug2);
    _drugInteractors.putIfAbsent(interaction.drug2, () => {}).add(interaction.drug1);

    // Store risk patterns
    _riskPatterns.putIfAbsent(interaction.drug1, () => []).add(interaction.riskRating);
    _riskPatterns.putIfAbsent(interaction.drug2, () => []).add(interaction.riskRating);
  }

  List<double> _extractFeatures(String drug1, String drug2) {
    // Feature 1: Number of known interactions for each drug
    double drug1Interactions = (_drugInteractors[drug1]?.length ?? 0).toDouble();
    double drug2Interactions = (_drugInteractors[drug2]?.length ?? 0).toDouble();

    // Feature 2: Risk level distribution for each drug
    var drug1Risks = _riskPatterns[drug1] ?? [];
    var drug2Risks = _riskPatterns[drug2] ?? [];
    
    double drug1HighRisk = drug1Risks.where((r) => r == 'X').length / (drug1Risks.length + 1);
    double drug1ModRisk = drug1Risks.where((r) => r == 'D').length / (drug1Risks.length + 1);
    double drug2HighRisk = drug2Risks.where((r) => r == 'X').length / (drug2Risks.length + 1);
    double drug2ModRisk = drug2Risks.where((r) => r == 'D').length / (drug2Risks.length + 1);

    // Feature 3: Mechanism similarity scores
    double mechanismSimilarity = _calculateMechanismSimilarity(drug1, drug2);

    // Feature 4: Common interaction partners
    double commonInteractors = _calculateCommonInteractors(drug1, drug2);

    return [
      drug1Interactions,
      drug2Interactions,
      drug1HighRisk,
      drug1ModRisk,
      drug2HighRisk,
      drug2ModRisk,
      mechanismSimilarity,
      commonInteractors,
    ];
  }

  double _calculateMechanismSimilarity(String drug1, String drug2) {
    var mechanisms1 = _drugMechanisms[drug1] ?? [];
    var mechanisms2 = _drugMechanisms[drug2] ?? [];
    
    if (mechanisms1.isEmpty || mechanisms2.isEmpty) return 0.0;

    // Calculate mechanism similarity using word overlap
    var words1 = mechanisms1.expand((m) => m.toLowerCase().split(RegExp(r'\W+')));
    var words2 = mechanisms2.expand((m) => m.toLowerCase().split(RegExp(r'\W+')));
    
    var set1 = words1.toSet();
    var set2 = words2.toSet();
    
    var intersection = set1.intersection(set2).length;
    var union = set1.union(set2).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }

  double _calculateCommonInteractors(String drug1, String drug2) {
    var interactors1 = _drugInteractors[drug1] ?? {};
    var interactors2 = _drugInteractors[drug2] ?? {};
    
    if (interactors1.isEmpty || interactors2.isEmpty) return 0.0;
    
    var intersection = interactors1.intersection(interactors2).length;
    var union = interactors1.union(interactors2).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }

  String _predictRiskLevel(List<double> features) {
    if (_trainingFeatures.isEmpty) return 'Unknown';

    // Find k nearest neighbors (k=3)
    const k = 3;
    var distances = List<MapEntry<int, double>>.generate(
      _trainingFeatures.length,
      (i) => MapEntry(i, _calculateDistance(_trainingFeatures[i], features))
    );

    // Sort by distance and get top k
    distances.sort((a, b) => a.value.compareTo(b.value));
    var nearestNeighbors = distances.take(k).map((e) => _trainingLabels[e.key]).toList();

    // Count risk levels
    var riskCounts = {
      'X': nearestNeighbors.where((r) => r == 'X').length,
      'D': nearestNeighbors.where((r) => r == 'D').length,
      'C': nearestNeighbors.where((r) => r == 'C').length,
    };

    // Return most common risk level
    return riskCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  double _calculateDistance(List<double> a, List<double> b) {
    if (a.length != b.length) return double.infinity;

    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += (a[i] - b[i]) * (a[i] - b[i]);
    }
    return sum;  // Using squared distance to avoid sqrt calculation
  }

  DrugInteraction predictInteraction(String drug1, String drug2) {
    try {
      var features = _extractFeatures(drug1, drug2);
      var predictedRisk = _predictRiskLevel(features);

      if (predictedRisk == 'Unknown') {
        throw Exception('Insufficient data for prediction');
      }

      // Generate explanation based on features
      String mechanism = _generateMechanismExplanation(drug1, drug2, features);
      String alternatives = _suggestAlternatives(drug1, drug2, predictedRisk);

      return DrugInteraction(
        drug1: drug1,
        drug2: drug2,
        mechanism: mechanism,
        alternatives: alternatives,
        riskRating: predictedRisk,
      );
    } catch (e) {
      print('Prediction error: $e');
      return DrugInteraction(
        drug1: drug1,
        drug2: drug2,
        mechanism: 'Interaction prediction requires more data. Please consult a healthcare professional.',
        alternatives: 'Consult your healthcare provider for verified alternatives.',
        riskRating: 'Unknown'
      );
    }
  }

  String _generateMechanismExplanation(String drug1, String drug2, List<double> features) {
    List<String> explanations = [];

    if (features[2] > 0.5 || features[4] > 0.5) {
      explanations.add('Both drugs have shown high-risk interactions with other medications');
    } else if (features[3] > 0.5 || features[5] > 0.5) {
      explanations.add('Both drugs have shown moderate-risk interactions with other medications');
    }

    if (features[6] > 0.3) {
      explanations.add('Similar interaction mechanisms have been observed with other drug combinations');
    }

    if (features[7] > 0.3) {
      explanations.add('These drugs interact with similar medications');
    }

    if (explanations.isEmpty) {
      return 'Predicted based on available interaction patterns. Verification needed.';
    }

    return explanations.join('. ') + '. Please consult a healthcare professional to verify.';
  }

  String _suggestAlternatives(String drug1, String drug2, String predictedRisk) {
    // Look for drugs that have lower risk interactions
    var alternatives1 = _findSaferAlternatives(drug1);
    var alternatives2 = _findSaferAlternatives(drug2);

    if (alternatives1.isEmpty && alternatives2.isEmpty) {
      return 'Please consult your healthcare provider for verified alternatives.';
    }

    String suggestion = 'Potential alternatives to consider:\n';
    if (alternatives1.isNotEmpty) {
      suggestion += '- Instead of $drug1: ${alternatives1.join(', ')}\n';
    }
    if (alternatives2.isNotEmpty) {
      suggestion += '- Instead of $drug2: ${alternatives2.join(', ')}';
    }

    return suggestion + '\nPlease consult your healthcare provider before making any changes.';
  }

  List<String> _findSaferAlternatives(String drug) {
    var interactors = _drugInteractors[drug] ?? {};
    if (interactors.isEmpty) return [];

    // Find drugs with similar mechanisms but lower risk ratings
    var risks = _riskPatterns[drug] ?? [];
    if (risks.isEmpty) return [];

    var currentRiskLevel = risks.contains('X') ? 3 : (risks.contains('D') ? 2 : 1);
    
    return _drugMechanisms.entries
        .where((entry) => entry.key != drug)
        .where((entry) {
          var entryRisks = _riskPatterns[entry.key] ?? [];
          var entryRiskLevel = entryRisks.contains('X') ? 3 : (entryRisks.contains('D') ? 2 : 1);
          return entryRiskLevel < currentRiskLevel;
        })
        .map((e) => e.key)
        .take(3)
        .toList();
  }
} 