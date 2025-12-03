import 'package:flutter/material.dart';
import '../../../app/core/theme/app_colors.dart';
import '../widgets/bento_box_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Widget _mainContent = const Center(
    child: Text(
      'Janela Principal (Conteúdo Dinâmico)',
      style: TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
    ),
  );

  void _setMainContent(Widget content) {
    setState(() {
      _mainContent = content;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double gap = 1.0;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Layout Bento Grid', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.grey[200],
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: EdgeInsets.all(gap),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                TopWindowSection(
                  cardColors: AppColors.cardColors,
                  gap: gap,
                  setMainContent: _setMainContent,
                ),
                SizedBox(height: gap),
                MainWindowSection(
                  mainContent: _mainContent,
                ),
                SizedBox(height: gap),
                BottomWindowSection(
                  cardColors: AppColors.cardColors,
                  gap: gap,
                  setMainContent: _setMainContent,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
