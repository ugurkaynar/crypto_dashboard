import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CryptoDashboardApp());
}

class CryptoDashboardApp extends StatelessWidget {
  const CryptoDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Pro Kripto Analiz',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0E17), 
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF151A22), 
          elevation: 0,
        ),
        cardColor: const Color(0xFF151A22),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2962FF),    
          secondary: Color(0xFF00E676),  
          error: Color(0xFFFF3D00),      
          surface: Color(0xFF151A22),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
