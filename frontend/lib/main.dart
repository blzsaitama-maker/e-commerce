import 'package:flutter/material.dart';
import 'package:frontend/features/home/screens/home_screen.dart';
import 'package:desktop_window/desktop_window.dart'; // NOVO: Para controle de janela

void main() async {
  // Garante que o Flutter está inicializado antes de chamar APIs nativas (como desktop_window)
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Configura a janela para Fullscreen ou tamanho máximo no Desktop (Linux)
  await DesktopWindow.setFullScreen(true);
  // Opcional: Definir tamanho mínimo para evitar que o usuário diminua demais
  await DesktopWindow.setMinWindowSize(const Size(1200, 768));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sistema de Gestão E-commerce PDV',
      debugShowCheckedModeBanner: false,
      // O tema Dark aqui garante que o PDV (SalesScreen) fique escuro
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}