// main.dart
import 'package:flutter/material.dart';
import 'package:plant_recognition_app/screens/identify_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Plant Identifier',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: const IdentifyScreen(),
    );
  }
}
