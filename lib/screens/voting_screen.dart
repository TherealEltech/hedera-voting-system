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
    _castVote();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a Candidate')),
      body: Column(
        children: [
          Expanded(
            // Instagram-like vertical feed: each candidate is a full-width card with image,
            // name overlay and a "Vote" button on the image.
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _candidates.length,
              itemBuilder: (context, index) {
                final name = _candidates[index];
                final imagePath = (index < _candidateImages.length)
                    ? _candidateImages[index]
                    : null;

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Material(
                      elevation: 2,
                      child: Stack(
                        children: [
                          // Candidate image (asset). If not found, show colored placeholder.
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

                          // Top-left name overlay
                          Positioned(
                            top: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black54,
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

                          // Vote button overlay (bottom center)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: SizedBox(
                                width: 160,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _selectedCandidateIndex ==
                                            index
                                        ? Colors.green[700]
                                        : null,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12, horizontal: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                  ),
                                  onPressed:
                                      _isLoading ? null : () => _onVotePressed(index),
                                  icon: _isLoading && _selectedCandidateIndex == index
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.how_to_vote),
                                  label: Text(
                                    _isLoading && _selectedCandidateIndex == index
                                        ? 'Voting...'
                                        : 'Vote',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // Small selection indicator (top-right)
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: (_selectedCandidateIndex == index)
                                    ? Colors.greenAccent.withOpacity(0.9)
                                    : Colors.black45,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _selectedCandidateIndex == index
                                    ? Icons.check
                                    : Icons.how_to_vote_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom controls: view results and a little spacing.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            Navigator.pushNamed(
                                context, ResultScreen.routeName);
                          },
                    child: const Text('View Current Results'),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 120,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            // If user wants to cast vote by pressing the bottom button,
                            // ensure a candidate is selected first.
                            _castVote();
                          },
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Cast Vote'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}