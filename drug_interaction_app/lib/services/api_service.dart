import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/interaction_details.dart';
import 'network_service.dart';
import 'dart:async';

class ApiService {
  String baseUrl;

  ApiService({required String baseUrl})
      : baseUrl = baseUrl.endsWith('/')
            ? baseUrl.substring(0, baseUrl.length - 1)
            : baseUrl;

  // Method to test general internet connectivity
  Future<bool> checkInternetConnectivity() async {
    try {
      // First use the native connectivity check
      final hasNativeConnection = await NetworkService.checkConnectivity();
      if (!hasNativeConnection) {
        print('No network connection detected by native APIs');
        return false;
      }

      // If native check passes, try an actual connection
      final response = await http.get(
        Uri.parse('https://8.8.8.8'),  // Use Google's DNS instead of domain name
        headers: {'Connection': 'close'},
      ).timeout(Duration(seconds: 5));
      
      print('Internet connectivity test status code: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Internet connectivity test error: $e');
      // If Google DNS fails, try a different reliable IP
      try {
        final response = await http.get(
          Uri.parse('https://1.1.1.1'),  // Cloudflare's DNS
          headers: {'Connection': 'close'},
        ).timeout(Duration(seconds: 5));
        return response.statusCode == 200;
      } catch (e) {
        print('Secondary internet connectivity test error: $e');
        return false;
      }
    }
  }

  // Method to test the API connection
  Future<bool> testConnection() async {
    try {
      // First check internet connectivity
      final hasInternet = await checkInternetConnectivity();
      if (!hasInternet) {
        print('No internet connectivity');
        return false;
      }

      final uri = Uri.parse(baseUrl);
      print('Testing connection to: $uri');
      final response = await http.get(uri).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );
      print('Test connection status code: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('Test connection error: $e');
      return false;
    }
  }

  // Method to update the base URL
  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl.endsWith('/')
        ? newUrl.substring(0, newUrl.length - 1)
        : newUrl;
  }

  Future<InteractionDetails> checkDrugInteraction(String drug1, String drug2) async {
    try {
      // Check internet connectivity first
      final hasInternet = await checkInternetConnectivity();
      if (!hasInternet) {
        throw Exception('No internet connection available');
      }

      final uri = Uri.parse('$baseUrl/predict_ddi');
      print('Sending request to: $uri');
      print('Sending request body: {"drug1": "$drug1", "drug2": "$drug2"}');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'drug1': drug1,
          'drug2': drug2,
        }),
      ).timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Request timed out');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (!data.containsKey('DRUG 1')) {
          data['DRUG 1'] = data['drug1'] ?? drug1;
          data['DRUG 2'] = data['drug2'] ?? drug2;
          data['MECHANISM OF INTERACTION'] = data['mechanism'] ?? data['mechanism_of_interaction'] ?? 'No mechanism provided';
          data['ALTERNATIVES'] = data['alternatives'] ?? 'No alternatives provided';
          data['RISK RATING'] = data['risk_rating'] ?? data['risk'] ?? 'Unknown';
          data['SOURCE'] = data['source'] ?? 'API';
        }
        return InteractionDetails.fromJson(data);
      } else {
        throw Exception('Failed to fetch drug interaction. Status code: ${response.statusCode}. Response: ${response.body}');
      }
    } catch (e) {
      print('Error details: $e');
      throw Exception('Error checking drug interaction: $e');
    }
  }
} 