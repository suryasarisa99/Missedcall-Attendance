import 'package:attendance/screens/Home.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences? prefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  prefs = await SharedPreferences.getInstance();
  runApp(const MainApp());
}

// theme
final seedColor = const Color.fromARGB(255, 255, 117, 117);
final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.light,
  ),
  useMaterial3: true,
);
final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
);

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      home: AttendanceScreen(),
    );
  }
}
