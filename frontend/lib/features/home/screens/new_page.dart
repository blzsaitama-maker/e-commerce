import 'package:flutter/material.dart';

class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova Página'),
      ),
      body: const Center(
        child: Text('Esta é uma nova página.'),
      ),
    );
  }
}
