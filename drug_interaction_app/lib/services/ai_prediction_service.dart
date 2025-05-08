import 'dart:math';
import 'package:collection/collection.dart';
import '../models/drug_interaction.dart';

class AIPredictionService {
  static final AIPredictionService _instance = AIPredictionService._internal();
  factory AIPredictionService() => _instance;
  AIPredictionService._internal();

  // Store known interactions for training
  List<DrugInteraction> _knownInteractions = [];

  void trainModel(List<DrugInteraction> interactions) {
    _knownInteractions = interactions;
  }

  double _calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;
    
    // Convert to lowercase and split into words
    final words1 = str1.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
    final words2 = str2.toLowerCase().split(RegExp(r'[^a-z0-9]+'));
    
    // Calculate Jaccard similarity
    final set1 = words1.toSet();
    final set2 = words2.toSet();
    
    final intersection = set1.intersection(set2).length;
    final union = set1.union(set2).length;
    
    return union == 0 ? 0.0 : intersection / union;
  }

  DrugInteraction predictInteraction(String drug1, String drug2) {
    if (_knownInteractions.isEmpty) {
      return DrugInteraction(
        drug1: drug1,
        drug2: drug2,
        mechanism: 'No training data available',
        alternatives: 'N/A',
        riskRating: 'Unknown'
      );
    }

    // Find similar drug pairs
    var similarInteractions = _knownInteractions.map((interaction) {
      double similarity1 = _calculateSimilarity(drug1, interaction.drug1) +
                         _calculateSimilarity(drug2, interaction.drug2);
      double similarity2 = _calculateSimilarity(drug1, interaction.drug2) +
                         _calculateSimilarity(drug2, interaction.drug1);
      
      return MapEntry(
        interaction,
        max(similarity1, similarity2) / 2 // Average similarity
      );
    }).toList();

    // Sort by similarity
    similarInteractions.sort((a, b) => b.value.compareTo(a.value));

    // If we have a good match (similarity > 0.5), use it
    if (similarInteractions.first.value > 0.5) {
      final bestMatch = similarInteractions.first.key;
      return DrugInteraction(
        drug1: drug1,
        drug2: drug2,
        mechanism: 'Predicted based on similar interaction: ${bestMatch.mechanism}',
        alternatives: bestMatch.alternatives,
        riskRating: bestMatch.riskRating
      );
    }

    // Calculate risk based on common patterns
    var riskPatterns = _analyzeRiskPatterns(drug1, drug2);
    return DrugInteraction(
      drug1: drug1,
      drug2: drug2,
      mechanism: riskPatterns.mechanism,
      alternatives: riskPatterns.alternatives,
      riskRating: riskPatterns.riskRating
    );
  }

  DrugInteraction _analyzeRiskPatterns(String drug1, String drug2) {
    // Count risk ratings for similar drug combinations
    Map<String, int> riskCounts = {'X': 0, 'D': 0, 'C': 0};
    
    for (var interaction in _knownInteractions) {
      double similarity = _calculateSimilarity(drug1, interaction.drug1) +
                         _calculateSimilarity(drug2, interaction.drug2);
      
      if (similarity > 0.3) {
        riskCounts[interaction.riskRating] = 
            (riskCounts[interaction.riskRating] ?? 0) + 1;
      }
    }

    // Determine most likely risk rating
    String predictedRisk = riskCounts.entries
        .sorted((a, b) => b.value.compareTo(a.value))
        .first.key;

    // Generate explanation based on chemical classes and common patterns
    String mechanism = 'Potential interaction predicted based on similar drug combinations. ' +
                      'Please consult a healthcare professional for verification.';
    
    String alternatives = 'Consider consulting a healthcare professional for specific alternatives.';

    return DrugInteraction(
      drug1: drug1,
      drug2: drug2,
      mechanism: mechanism,
      alternatives: alternatives,
      riskRating: predictedRisk
    );
  }
} 