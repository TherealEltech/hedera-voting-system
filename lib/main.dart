import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:voting_system/screens/login_screen.dart';
import 'package:voting_system/screens/result_screen.dart';
import 'package:voting_system/screens/voting_screen.dart';
import 'package:voting_system/theme/app_theme.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hedera Voting DApp',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        VotingScreen.routeName: (context) => const VotingScreen(),
        ResultScreen.routeName: (context) => const ResultScreen(),
      },
    );
  }
}