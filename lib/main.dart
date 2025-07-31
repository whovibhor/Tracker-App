import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/expense.dart';
import 'models/user.dart';
import 'screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(PaymentMethodAdapter());
  Hive.registerAdapter(UserAdapter());

  // Open Hive boxes
  await Hive.openBox('assetsBox');
  await Hive.openBox('liabilitiesBox');
  await Hive.openBox('userBox');

  runApp(FinlyApp());
}

class FinlyApp extends StatelessWidget {
  const FinlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FINLY',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Color(0xFFF6F8FB),
        useMaterial3: false, // Disable Material 3 for better icon compatibility
        iconTheme: IconThemeData(color: Colors.black),
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
