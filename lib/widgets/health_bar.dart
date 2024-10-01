import 'package:flutter/material.dart';

class HealthBar extends StatelessWidget {
  final int currentHealth;
  final int maxHealth;

  const HealthBar({
    super.key,
    required this.currentHealth,
    required this.maxHealth,
  });

  @override
  Widget build(BuildContext context) {
    double healthPercentage = currentHealth / maxHealth;
    return Stack(
      children: [
        Container(
          width: 150,  // Adjust the width as needed
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.red[700],
          ),
        ),
        Container(
          width: 150 * healthPercentage,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.green,
          ),
        ),
        Center(
          child: Text(
            '$currentHealth / $maxHealth',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
