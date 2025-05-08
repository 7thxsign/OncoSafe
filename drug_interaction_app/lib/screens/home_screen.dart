import 'package:flutter/material.dart';
import '../models/interaction_details.dart';
import '../services/api_service.dart';
import '../services/drug_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService(baseUrl: 'https://a9f5-35-230-171-11.ngrok-free.app');
  String? _selectedDrug1;
  String? _selectedDrug2;
  InteractionDetails? _currentInteraction;
  List<String> _availableDrugs = [];
  bool _isLoading = false;
  String? _errorMessage;
  final TextEditingController _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    _urlController.text = _apiService.baseUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final drugs = await DrugService.loadDrugs();
      setState(() {
        _availableDrugs = drugs;
      });
    } catch (e) {
      print('Error loading drugs: $e');
      setState(() {
        _errorMessage = 'Failed to load drug list: $e';
      });
    }
  }

  Future<void> _updateApiUrl() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a valid URL';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // First check internet connectivity
      final hasInternet = await _apiService.checkInternetConnectivity();
      if (!hasInternet) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'No internet connection available. Please check your device\'s internet connection.';
        });
        return;
      }

      print('Internet connectivity: OK');
      
      _apiService.updateBaseUrl(newUrl);
      final isConnected = await _apiService.testConnection();
      
      setState(() {
        _isLoading = false;
        if (!isConnected) {
          _errorMessage = 'Could not connect to the API. Please verify:\n'
              '1. The ngrok URL is correct and active\n'
              '2. Your Flask backend is running\n'
              '3. The endpoint responds to GET requests';
        } else {
          _errorMessage = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully connected to API'),
              backgroundColor: Colors.green,
            ),
          );
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error testing connection: $e';
      });
    }
  }

  void _checkInteraction() async {
    if (_selectedDrug1 != null && _selectedDrug2 != null) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        // First check internet connectivity
        final hasInternet = await _apiService.checkInternetConnectivity();
        if (!hasInternet) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection available. Please check your device\'s internet connection.';
          });
          return;
        }

        print('Sending request for drugs: $_selectedDrug1 and $_selectedDrug2');
        final interaction = await _apiService.checkDrugInteraction(_selectedDrug1!, _selectedDrug2!);
        setState(() {
          _currentInteraction = interaction;
          _isLoading = false;
        });
      } catch (e) {
        print('Error in home screen: $e');
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
          _currentInteraction = null;
        });
      }
    }
  }

  Widget _buildSearchableDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return GestureDetector(
      onTap: () {
        _showDrugSearchSheet(context, label, value, onChanged);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(Icons.medication, color: Colors.teal),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value ?? 'Select a drug',
                    style: TextStyle(
                      fontSize: 16,
                      color: value == null ? Colors.grey.shade600 : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
          ],
        ),
      ),
    );
  }

  void _showDrugSearchSheet(
    BuildContext context,
    String label,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return _DrugSearchSheet(
          label: label,
          currentValue: currentValue,
          availableDrugs: _availableDrugs,
          onDrugSelected: onChanged,
        );
      },
    );
  }

  Widget _buildRiskBadge(String riskRating) {
    String riskText = _getRiskDescription(riskRating);
    Color riskColor = _getRiskColor(riskRating);
    IconData riskIcon;
    
    switch (riskRating) {
      case 'X':
        riskIcon = Icons.dangerous;
        break;
      case 'D':
        riskIcon = Icons.warning;
        break;
      case 'C':
        riskIcon = Icons.info;
        break;
      default:
        riskIcon = Icons.help;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: riskColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: riskColor.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            riskIcon,
            color: Colors.white,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            'Risk Rating: $riskRating',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 4),
          Text(
            riskText,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ).animate()
      .fadeIn(duration: 300.ms)
      .scale(duration: 300.ms, curve: Curves.easeOut);
  }

  String _getRiskDescription(String riskRating) {
    switch (riskRating.toUpperCase()) {
      case 'X':
        return 'Avoid Combination\nContraindicated';
      case 'D':
        return 'Consider Therapy Modification\nSerious Interaction';
      case 'C':
        return 'Monitor Therapy\nModerate Interaction';
      default:
        return 'Risk Level Unknown\nConsult Healthcare Provider';
    }
  }

  Color _getRiskColor(String riskRating) {
    switch (riskRating.toUpperCase()) {
      case 'X':
        return Colors.red.shade700;
      case 'D':
        return Colors.orange.shade700;
      case 'C':
        return Colors.yellow.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'OncoSafe',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('API Configuration'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'API URL',
                          hintText: 'Enter your ngrok URL',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updateApiUrl();
                        Navigator.pop(context);
                      },
                      child: Text('Save'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Select Drugs to Check',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ).animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 16),
                    _buildSearchableDropdown(
                      label: 'Select First Drug',
                      value: _selectedDrug1,
                      onChanged: (value) {
                        setState(() {
                          _selectedDrug1 = value;
                          _currentInteraction = null;
                        });
                      },
                    ).animate()
                      .fadeIn(duration: 300.ms, delay: 100.ms)
                      .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 16),
                    _buildSearchableDropdown(
                      label: 'Select Second Drug',
                      value: _selectedDrug2,
                      onChanged: (value) {
                        setState(() {
                          _selectedDrug2 = value;
                          _currentInteraction = null;
                        });
                      },
                    ).animate()
                      .fadeIn(duration: 300.ms, delay: 200.ms)
                      .slideX(begin: -0.2, end: 0),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _selectedDrug1 != null && _selectedDrug2 != null && !_isLoading
                          ? _checkInteraction
                          : null,
                      icon: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Icon(Icons.search),
                      label: Text(_isLoading ? 'Checking...' : 'Check Interaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ).animate()
                      .fadeIn(duration: 300.ms, delay: 300.ms)
                      .slideX(begin: -0.2, end: 0),
                  ],
                ),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: 16),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(duration: 300.ms)
                .slideY(begin: 0.2, end: 0),
            ],
            if (_currentInteraction != null) ...[
              SizedBox(height: 16),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: _buildRiskBadge(_currentInteraction!.riskRating),
                      ),
                      SizedBox(height: 24),
                      Text(
                        'Mechanism of Interaction:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 400.ms),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentInteraction!.mechanismOfInteraction,
                          style: TextStyle(fontSize: 15),
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 500.ms),
                      SizedBox(height: 16),
                      Text(
                        'Alternatives:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 600.ms),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentInteraction!.alternatives,
                          style: TextStyle(fontSize: 15),
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 700.ms),
                      SizedBox(height: 16),
                      Text(
                        'Source:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.teal,
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 800.ms),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _currentInteraction!.source,
                          style: TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ).animate()
                        .fadeIn(duration: 300.ms, delay: 900.ms),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DrugSearchSheet extends StatefulWidget {
  final String label;
  final String? currentValue;
  final List<String> availableDrugs;
  final ValueChanged<String?> onDrugSelected;

  const _DrugSearchSheet({
    required this.label,
    required this.currentValue,
    required this.availableDrugs,
    required this.onDrugSelected,
  });

  @override
  _DrugSearchSheetState createState() => _DrugSearchSheetState();
}

class _DrugSearchSheetState extends State<_DrugSearchSheet> {
  late TextEditingController _searchController;
  List<String> _filteredDrugs = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _filteredDrugs = List.from(widget.availableDrugs);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select ${widget.label}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search drugs...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filteredDrugs = widget.availableDrugs
                          .where((drug) =>
                              drug.toLowerCase().contains(value.toLowerCase()))
                          .toList();
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredDrugs.length,
              itemBuilder: (context, index) {
                final drug = _filteredDrugs[index];
                final isSelected = drug == widget.currentValue;
                return ListTile(
                  title: Text(drug),
                  leading: Icon(
                    Icons.medication,
                    color: isSelected ? Colors.teal : Colors.grey,
                  ),
                  tileColor: isSelected ? Colors.teal.withOpacity(0.1) : null,
                  onTap: () {
                    widget.onDrugSelected(drug);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 