import 'package:flutter/material.dart';
import '../screens/new_page.dart';
import '../../products/screens/product_form_screen.dart';
import '../../products/widgets/product_list_widget.dart';
import './custom_card.dart';

class TopWindowSection extends StatelessWidget {
  final List<Color> cardColors;
  final double gap;
  final Function(Widget) setMainContent;

  const TopWindowSection({
    super.key,
    required this.cardColors,
    required this.gap,
    required this.setMainContent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(10, (index) {
          return CustomCard(
            color: cardColors[index % cardColors.length],
            text: 'Top ${index + 1}',
            gap: gap,
            onTap: () {
              if (index == 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewPage()),
                );
              } else if (index == 4) {
                setMainContent(ProductFormScreen());
              } else if (index == 5) {
                setMainContent(ProductListWidget());
              } else {
                setMainContent(Text(
                  'Conteúdo da Janela Superior ${index + 1}',
                  style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
                ));
              }
            },
          );
        }),
      ),
    );
  }
}

class MainWindowSection extends StatelessWidget {
  final Widget mainContent;

  const MainWindowSection({
    super.key,
    required this.mainContent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 14,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: mainContent,
          ),
        ),
      ),
    );
  }
}

class BottomWindowSection extends StatelessWidget {
  final List<Color> cardColors;
  final double gap;
  final Function(Widget) setMainContent;

  const BottomWindowSection({
    super.key,
    required this.cardColors,
    required this.gap,
    required this.setMainContent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 1,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(8, (index) {
          return CustomCard(
            color: cardColors[index % cardColors.length],
            text: 'Inf ${index + 1}',
            gap: gap,
            onTap: () {
              setMainContent(Text(
                'Conteúdo da Janela Inferior ${index + 1}',
                style: const TextStyle(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
              ));
            },
          );
        }),
      ),
    );
  }
}
