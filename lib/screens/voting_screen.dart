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

  // match images by index to _candidates; place your images in assets/images/
  final List<String> _candidateImages = [
    'assets/bola_tinubu.jpg',
    'assets/peter_obi.jpg',
    'assets/musa_kwankwoso.jpg',
    'assets/nasir_elrufai.jpg',
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
    String privateKey =
        'f2128476dae792d633638d43259b3c465a3eaf05eaabc9f5de7ee7de54de6ff7';
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
        const SnackBar(
            content:
                Text('Hedera service not initialized. Please set up your private key.')),
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
      String result =
          await _hederaService!.vote(_selectedCandidateIndex! + 1, ninHash);

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

        if (e.toString().contains('ALREADY_VOTED') ||
            e.toString().contains('You have already voted')) {
          errorTitle = 'Already Voted';
          errorMessage =
              'You have already cast your vote with this NIN. Each voter can only vote once.';
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

  // Called when user taps the vote button on a candidate card
  void _onVotePressed(int index) {
    if (_isLoading) return;
    setState(() => _selectedCandidateIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presidential Election 2027'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.how_to_vote_rounded,
                  size: 40,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select Your Candidate',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedCandidateIndex != null
                      ? 'Selected: ${_candidates[_selectedCandidateIndex!]}'
                      : 'Tap a candidate card to select',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _selectedCandidateIndex != null
                        ? Colors.green[400]
                        : Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final name = _candidates[index];
                final imagePath = (index < _candidateImages.length)
                    ? _candidateImages[index]
                    : null;
                final isSelected = _selectedCandidateIndex == index;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: GestureDetector(
                    onTap: _isLoading ? null : () {
                      setState(() => _selectedCandidateIndex = index);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Material(
                        elevation: isSelected ? 8 : 2,
                        child: Stack(
                          children: [
                            // Candidate image
                            SizedBox(
                              height: 420,
                              width: double.infinity,
                              child: imagePath != null
                                  ? Image.asset(
                                      imagePath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, stack) => Container(
                                        color: Colors.grey[300],
                                        alignment: Alignment.center,
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.person, size: 64),
                                            const SizedBox(height: 8),
                                            Text(
                                              name,
                                              style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 6),
                                            const Text('Image not found',
                                                style: TextStyle(
                                                    color: Colors.black54)),
                                          ],
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[300],
                                    ),
                            ),

                            // Selection overlay
                            if (isSelected)
                              Container(
                                height: 420,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.green,
                                    width: 4,
                                  ),
                                ),
                              ),

                            // Name overlay
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSelected 
                                      ? Colors.green.withOpacity(0.9)
                                      : Colors.black54,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),

                            // Selection indicator
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.black45,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.radio_button_unchecked,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Cast Vote button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _castVote,
                icon: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.how_to_vote),
                label: Text(
                  _isLoading ? 'Casting Vote...' : 'Cast Vote',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedCandidateIndex != null
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}