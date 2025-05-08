import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OncoSafe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        fontFamily: 'Gilroy',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.bold),
          displaySmall: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
          headlineSmall: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
          titleLarge: TextStyle(fontFamily: 'Gilroy', fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontFamily: 'Gilroy'),
          bodyMedium: TextStyle(fontFamily: 'Gilroy'),
        ),
      ),
      home: HomeScreen(),
    );
  }
}
