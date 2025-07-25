import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(StudentDailyTrackerApp());
}

class StudentDailyTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Daily Tracker',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
