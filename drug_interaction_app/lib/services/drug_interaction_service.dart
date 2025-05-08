import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/drug_interaction.dart';
import 'ml_prediction_service.dart';

class DrugInteractionService {
  static final DrugInteractionService _instance = DrugInteractionService._internal();
  factory DrugInteractionService() => _instance;
  DrugInteractionService._internal();

  final MLPredictionService _mlService = MLPredictionService();
  List<DrugInteraction> _interactions = [];
  Set<String> _availableDrugs = {};

  Future<void> loadData() async {
    try {
      final String csvData = await rootBundle.loadString('assets/drug_interactions.csv');
      final List<String> rows = const LineSplitter().convert(csvData);
      
      // Skip header row and empty rows
      _interactions = rows.skip(1).where((row) => row.trim().isNotEmpty).map((row) {
        final List<String> columns = row.split(',');
        if (columns.length >= 5) {
          final drug1 = columns[0].trim();
          final drug2 = columns[1].trim();
          if (drug1.isNotEmpty) _availableDrugs.add(drug1);
          if (drug2.isNotEmpty) _availableDrugs.add(drug2);
          return DrugInteraction(
            drug1: drug1,
            drug2: drug2,
            mechanism: columns[2].trim(),
            alternatives: columns[3].trim(),
            riskRating: columns[4].trim(),
          );
        }
        throw FormatException('Invalid row format: $row');
      }).toList();

      print('Loaded ${_interactions.length} interactions');
      print('Available drugs: ${_availableDrugs.length}');

      // Train the ML model with known interactions
      _mlService.trainModel(_interactions);
    } catch (e) {
      print('Error loading drug interaction data: $e');
      _interactions = [];
    }
  }

  List<String> getAvailableDrugs() {
    return _availableDrugs.toList()..sort();
  }

  DrugInteraction findInteraction(String drug1, String drug2) {
    try {
      // First try exact match
      return _interactions.firstWhere(
        (interaction) => 
          (interaction.drug1.toLowerCase() == drug1.toLowerCase() && 
           interaction.drug2.toLowerCase() == drug2.toLowerCase()) ||
          (interaction.drug1.toLowerCase() == drug2.toLowerCase() && 
           interaction.drug2.toLowerCase() == drug1.toLowerCase()),
      );
    } catch (e) {
      // If no exact match is found, use ML to predict interaction
      return _mlService.predictInteraction(drug1, drug2);
    }
  }

  List<DrugInteraction> searchInteractions(String query) {
    if (query.isEmpty) return [];
    
    query = query.toLowerCase();
    return _interactions.where((interaction) =>
      interaction.drug1.toLowerCase().contains(query) ||
      interaction.drug2.toLowerCase().contains(query)
    ).toList();
  }
} 