import 'package:flutter/material.dart';
import 'package:voting_system/screens/result_screen.dart';
import 'package:voting_system/hedera_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class VotingScreen extends StatefulWidget {
  const VotingScreen({super.key});
  static const routeName = '/voting';

  @override
  State<VotingScreen> createState() => _VotingScreenState();
}


class _VotingScreenState extends State<VotingScreen> {
  // In a real app, this would come from your HederaService
  final List<String> _candidates = [
    "Bola Ahmed Tinubu",
    "Peter Obi",
    "Musa Kwankwoso",
    "Nasir El-Rufai",
  ];

  final _storage = const FlutterSecureStorage();
  HederaService? _hederaService;
  bool _isLoading = false;

  int? _selectedCandidateIndex;

  @override

  void initState() {
  super.initState();
  _initializeHederaService();
  }

  Future<void> _initializeHederaService() async {
  // Use your funded wallet instead of generating new one
  String privateKey = 'f2128476dae792d633638d43259b3c465a3eaf05eaabc9f5de7ee7de54de6ff7';
  _hederaService = HederaService(privateKey: privateKey);
  
  // Debug: Check contract state
  await _hederaService!.debugContractState();
}

String _generateNINHash(String nin) {
  // Generate hash of NIN for privacy
  final bytes = utf8.encode(nin);
  final digest = sha256.convert(bytes);
  return '0x${digest.toString()}';
}

  Future<void> _castVote() async {
  if (_selectedCandidateIndex == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select a candidate to vote.')),
    );
    return;
  }

  if (_hederaService == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hedera service not initialized. Please set up your private key.')),
    );
    return;
  }

  // Get NIN from storage
  String? nin = await _storage.read(key: 'user_nin');
  if (nin == null) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NIN not found. Please login again.')),
      );
    }
    return;
  }

  setState(() => _isLoading = true);

  try {
    // Generate NIN hash and call the smart contract
    String ninHash = _generateNINHash(nin);
    String result = await _hederaService!.vote(_selectedCandidateIndex! + 1, ninHash);
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vote cast successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Wait for transaction to be confirmed (3 seconds)
      await Future.delayed(const Duration(seconds: 3));
      
      if (mounted) {
        Navigator.pushReplacementNamed(context, ResultScreen.routeName);
      }
    }
  } catch (e) {
  print('Caught error: $e');
  
  if (mounted) {
    setState(() => _isLoading = false);
    
    String errorTitle = 'Voting Error';
    String errorMessage = 'Failed to submit vote. Please try again.';
    
    if (e.toString().contains('ALREADY_VOTED') || e.toString().contains('You have already voted')) {
      errorTitle = 'Already Voted';
      errorMessage = 'You have already cast your vote with this NIN. Each voter can only vote once.';
    } else if (e.toString().contains('Invalid candidate')) {
      errorMessage = 'Invalid candidate selected.';
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(errorTitle),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Candidate')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _candidates.length,
                itemBuilder: (context, index) {
                  return RadioListTile<int>(
                    title: Text(_candidates[index]),
                    value: index,
                    groupValue: _selectedCandidateIndex,
                    onChanged: (value) =>
                        setState(() => _selectedCandidateIndex = value),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _castVote,
              child: _isLoading 
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
            )
              : const Text('Cast Vote'),
            ),

            const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(context, ResultScreen.routeName);
                },
                child: const Text('View Current Results'),
              ),

          ],
        ),
      ),
    );
  }
}