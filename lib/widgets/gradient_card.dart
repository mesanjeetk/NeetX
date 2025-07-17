import 'package:flutter/material.dart';

class GradientCard extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final List<Color> colors;

  const GradientCard({
    super.key,
    required this.title,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: colors),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white),
        onTap: onTap,
      ),
    );
  }
}
