import 'package:flutter/material.dart';

class TilePuzzle extends StatefulWidget {
  final Function(bool) onPuzzleSolved; // Callback to notify when the puzzle is solved

  const TilePuzzle({super.key, required this.onPuzzleSolved});

  @override
  _TilePuzzleState createState() => _TilePuzzleState();
}

class _TilePuzzleState extends State<TilePuzzle> with TickerProviderStateMixin {
  List<int> tiles = List.generate(9, (index) => index + 1)..last = 0;
  int emptyTileIndex = 8;
  bool isShuffled = false;

  @override
  void initState() {
    super.initState();
    _shuffleTiles();
  }

  void _shuffleTiles() {
    setState(() {
      do {
        tiles.shuffle();
        emptyTileIndex = tiles.indexOf(0);
      } while (!_isSolvable());
      isShuffled = true;
    });
  }

  bool _isSolvable() {
    int inversions = 0;
    for (int i = 0; i < tiles.length - 1; i++) {
      for (int j = i + 1; j < tiles.length; j++) {
        if (tiles[i] > tiles[j] && tiles[i] != 0 && tiles[j] != 0) {
          inversions++;
        }
      }
    }
    return inversions % 2 == 0;
  }

  void _swapTiles(int index) {
    if (_isAdjacent(index, emptyTileIndex)) {
      setState(() {
        tiles[emptyTileIndex] = tiles[index];
        tiles[index] = 0;
        emptyTileIndex = index;
      });
      if (_isSolved()) {
        widget.onPuzzleSolved(true); // Notify that the puzzle is solved
      }
    }
  }

  bool _isAdjacent(int index1, int index2) {
    final row1 = index1 ~/ 3;
    final col1 = index1 % 3;
    final row2 = index2 ~/ 3;
    final col2 = index2 % 3;
    return (row1 == row2 && (col1 - col2).abs() == 1) ||
           (col1 == col2 && (row1 - row2).abs() == 1);
  }

  bool _isSolved() {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) {
        return false;
      }
    }
    return true;
  }

  Color _getTileColor(int number) {
    switch (number) {
      case 1: return Colors.redAccent;
      case 2: return Colors.orangeAccent;
      case 3: return Colors.yellowAccent;
      case 4: return Colors.greenAccent;
      case 5: return Colors.tealAccent;
      case 6: return Colors.blueAccent;
      case 7: return Colors.indigoAccent;
      case 8: return Colors.purpleAccent;
      default: return Colors.white;
    }
  }

  void _solvePuzzleDirectly() {
  setState(() {
    // Arrange the tiles in the correct order
    tiles = List.generate(9, (index) => index + 1);
    tiles.last = 0; // Set the last tile as the empty tile
    emptyTileIndex = tiles.indexOf(0);
  });

  // Check and notify if the puzzle is solved
  if (_isSolved()) {
    widget.onPuzzleSolved(true);
  }
}


@override
Widget build(BuildContext context) {
  return Column(
    children: [
      Expanded(
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
          ),
          itemCount: tiles.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () => _swapTiles(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  color: tiles[index] == 0 ? Colors.white : _getTileColor(tiles[index]),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    if (tiles[index] != 0)
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      )
                  ],
                ),
                alignment: Alignment.center,
                child: tiles[index] != 0 ? Text(
                  tiles[index].toString(),
                  style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                ) : null,
              ),
            );
          },
        ),
      ),
      // ElevatedButton(
      //   onPressed: _solvePuzzleDirectly,
      //   child: const Text("Solve Puzzle"),
      //   style: ElevatedButton.styleFrom(
      //     backgroundColor: Colors.green,
      //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      //     textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      //   ),
      // ),
    ],
  );
}
}
