import 'package:flutter/material.dart';
import 'data/local/database.dart';
import 'presentation/screens/claim_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database
  await OrynDatabase.getInstance();

  runApp(const OrynApp());
}

class OrynApp extends StatelessWidget {
  const OrynApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oryn',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.grey,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      ),
      home: const ClaimListScreen(),
    );
  }
}