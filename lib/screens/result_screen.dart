import 'package:flutter/material.dart';
import 'package:voting_system/hedera_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});
  static const routeName = '/result';

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  HederaService? _hederaService;
  bool _isLoading = true;
  List<Map<String, dynamic>> _candidates = [];
  int _totalVotes = 0;

  @override
  void initState() {
    super.initState();
    _initializeAndFetchResults();
  }

  Future<void> _initializeAndFetchResults() async {
    String privateKey = 'f2128476dae792d633638d43259b3c465a3eaf05eaabc9f5de7ee7de54de6ff7';    
    _hederaService = HederaService(privateKey: privateKey);
    await _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);
    
    if (_hederaService != null) {
      // Add a small delay to ensure blockchain has updated
      await Future.delayed(const Duration(seconds: 2));
      
      final candidates = await _hederaService!.getAllCandidates();
      int total = 0;
      for (var candidate in candidates) {
        total += candidate['voteCount'] as int;
      }
      
      setState(() {
        _candidates = candidates;
        _totalVotes = total;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Voting Results'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchResults,
            tooltip: 'Refresh Results',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Success Icon
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  
                  // Title
                  Text(
                    'Vote Cast Successfully!',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  // Total Votes
                  Text(
                    'Total Votes: $_totalVotes',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Results Title
                  Text(
                    'Current Results',
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // Candidates List
                  ..._candidates.map((candidate) {
                    final percentage = _totalVotes > 0
                        ? (candidate['voteCount'] / _totalVotes * 100)
                        : 0.0;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    candidate['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${candidate['voteCount']} votes',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            
                            // Progress Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: _totalVotes > 0 ? percentage / 100 : 0,
                                minHeight: 10,
                                backgroundColor: Colors.grey[300],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getColorForCandidate(candidate['id']),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            
                            // Percentage
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 24),
                  
                  // Back Button
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/',
                      (route) => false,
                    ),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
    );
  }

  Color _getColorForCandidate(int id) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
    ];
    return colors[(id - 1) % colors.length];
  }
}