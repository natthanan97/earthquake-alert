import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ProviderScope(child: EarthquakeApp()));
}

class EarthquakeApp extends StatelessWidget {
  const EarthquakeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earthquake Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepOrange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
