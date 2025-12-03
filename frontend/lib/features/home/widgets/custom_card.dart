import 'package:flutter/material.dart';

class CustomCard extends StatelessWidget {
  final Color color;
  final String text;
  final double gap;
  final VoidCallback onTap;

  const CustomCard({
    super.key,
    required this.color,
    required this.text,
    required this.gap,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          margin: EdgeInsets.all(gap),
          elevation: 2,
          color: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Center(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
