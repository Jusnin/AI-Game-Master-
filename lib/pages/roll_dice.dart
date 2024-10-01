import 'dart:math';
import 'package:flutter/material.dart';

class RollingDiceWidget extends StatefulWidget {
  const RollingDiceWidget({super.key});

  @override
  _RollingDiceWidgetState createState() => _RollingDiceWidgetState();
}

class _RollingDiceWidgetState extends State<RollingDiceWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _diceValue = 1;
  bool _rolling = false;
  bool _showResult = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );

    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        setState(() {
          _rolling = false;
          _diceValue = Random().nextInt(6) + 1; // Simulate dice roll (1-6)
          _showResult = true; // Show the result after rolling
        });

        // Display the result for 1.5 seconds before closing
        await Future.delayed(const Duration(seconds: 1, milliseconds: 500));
        Navigator.pop(context, _diceValue);
      }
    });
  }

  void _rollDice() {
    setState(() {
      _rolling = true;
      _showResult = false;
    });
    _controller.forward(from: 0.0); // Start the dice roll animation
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.blueGrey.shade900,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: const Text('Rolling Dice', style: TextStyle(color: Colors.white)),
      content: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rolling ? _animation.value * 2.0 * pi : 0,
            child: Image.asset('assets/images/dice_$_diceValue.png'), // Placeholder image path for dice faces
          );
        },
      ),
      actions: [
        ElevatedButton(
          onPressed: _rolling ? null : _rollDice,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          child: const Text('Roll Dice', style: TextStyle(color: Colors.white)),
        ),
        if (_showResult)
          Padding(
            padding: const EdgeInsets.only(top: 10.0),
            child: Text('Result: $_diceValue', style: const TextStyle(fontSize: 18, color: Colors.white)),
          ),
      ],
    );
  }
}
