import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:voting_system/screens/voting_screen.dart';
import 'package:voting_system/screens/result_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:voting_system/hedera_service.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final _ninController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  HederaService? _hederaService;

  @override
  void initState() {
    super.initState();
    _initializeHederaService();
  }

  Future<void> _initializeHederaService() async {
    String privateKey = 'f2128476dae792d633638d43259b3c465a3eaf05eaabc9f5de7ee7de54de6ff7';
    _hederaService = HederaService(privateKey: privateKey);
  }

  String _generateNINHash(String nin) {
    final bytes = utf8.encode(nin);
    final digest = sha256.convert(bytes);
    return '0x${digest.toString()}';
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Check if this NIN has already voted
      if (_hederaService != null) {
        String ninHash = _generateNINHash(_ninController.text);
        bool hasVoted = await _hederaService!.checkIfVoted(ninHash);
        
        if (hasVoted) {
          if (mounted) {
            setState(() => _isLoading = false);
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Already Voted'),
                content: const Text(
                  'You have already cast your vote with this NIN. Each voter can only vote once.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
          return;
        }
      }

      // Store NIN and proceed to voting
      await _storage.write(key: 'user_nin', value: _ninController.text);
      
      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pushReplacementNamed(context, VotingScreen.routeName);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _ninController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo/Icon
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.how_to_vote_rounded,
                        size: 80,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ).animate()
                      .fadeIn(duration: 600.ms)
                      .scale(delay: 200.ms),
                    
                    const SizedBox(height: 32),
                    
                    // Company Name
                    Text(
                      'ElTech',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(delay: 250.ms)
                      .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    // Title
                    Text(
                      'Hedera Voting System',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(delay: 300.ms)
                      .slideY(begin: 0.3, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Secure, Transparent, Immutable',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[400],
                      ),
                      textAlign: TextAlign.center,
                    ).animate()
                      .fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 48),
                    
                    // NIN Input Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'National Identification Number',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your 11-digit NIN to continue',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _ninController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'NIN',
                                hintText: '12345678901',
                                prefixIcon: Icon(Icons.badge),
                              ),
                              maxLength: 11,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your NIN';
                                }
                                if (value.length != 11) {
                                  return 'NIN must be exactly 11 digits';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                    ).animate()
                      .fadeIn(delay: 500.ms)
                      .slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Sign In Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _signIn,
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Sign In'),
                      ),
                    ).animate()
                      .fadeIn(delay: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 16),
                    
                    // View Results Button
                    SizedBox(
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                Navigator.pushNamed(context, ResultScreen.routeName);
                              },
                        child: const Text('View Current Results'),
                      ),
                    ).animate()
                      .fadeIn(delay: 650.ms)
                      .slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 24),
                    
                    // Info Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[300],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your vote is anonymous and secured on the Hedera network',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.blue[200],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate()
                      .fadeIn(delay: 700.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}