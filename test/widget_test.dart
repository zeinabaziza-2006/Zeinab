import 'package:flutter/material.dart';

void main() {
  runApp(const DiabeticFootApp());
}

class DiabeticFootApp extends StatelessWidget {
  const DiabeticFootApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Diabetic Foot',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Diabetic Foot'),
        ),
        body: const Center(
          child: Text(
            'Welcome to Diabetic Foot',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}