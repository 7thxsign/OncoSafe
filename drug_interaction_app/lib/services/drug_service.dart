import 'package:flutter/services.dart';
import 'package:csv/csv.dart';

class DrugService {
  static Future<List<String>> loadDrugs() async {
    try {
      // Load CSV file from assets
      print('Starting to load CSV file...');
      final String csvData = await rootBundle.loadString('assets/drug_interactions.csv');
      print('CSV file loaded, size: ${csvData.length} bytes');
      
      // Parse CSV data
      List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvData);
      print('CSV parsed, total rows: ${csvTable.length}');
      
      // Create a Set to store unique drug names (to avoid duplicates)
      Set<String> uniqueDrugs = {};
      
      // Skip header row and collect unique drugs from both columns
      for (var i = 1; i < csvTable.length; i++) {
        if (csvTable[i].length >= 2) {
          String drug1 = csvTable[i][0].toString().trim();
          String drug2 = csvTable[i][1].toString().trim();
          uniqueDrugs.add(drug1);
          uniqueDrugs.add(drug2);
          if (i == 1) {
            print('Sample row: Drug1="$drug1", Drug2="$drug2"'); // Print first row as sample
          }
        }
      }
      
      // Convert to list and sort alphabetically
      List<String> drugList = uniqueDrugs.toList()..sort();
      print('Loaded ${drugList.length} unique drugs');
      print('First 10 drugs: ${drugList.take(10).join(", ")}');
      return drugList;
    } catch (e, stackTrace) {
      print('Error loading drugs: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }
} 