import 'package:flutter/material.dart';

import 'features/home/presentation/pages/home.dart'; 

void main() {
  runApp(const VoxaApp());
}

class VoxaApp extends StatelessWidget {
  const VoxaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Voxa - CAA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.green, useMaterial3: true),
      home: const HomePage(), // Define a tua HomePage como a tela inicial
    );
  }
}
