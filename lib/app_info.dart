import 'package:flutter/material.dart';

class AppInfoPage extends StatelessWidget {
  const AppInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('App Info')),
      body: const Center(
        child: Text(
          'Essential App\nVersion 1.0.0',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
