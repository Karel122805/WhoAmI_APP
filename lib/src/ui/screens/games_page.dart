import 'package:flutter/material.dart';
import '../theme.dart';

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Juegos'),
        backgroundColor: kBlue,
      ),
      body: const Center(
        child: Text(
          'Aquí irán los juegos interactivos 🎮',
          style: TextStyle(fontSize: 18, color: kInk),
        ),
      ),
    );
  }
}
