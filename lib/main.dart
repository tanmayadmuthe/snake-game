import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'dart:math';

void main() {
  runApp(const SnakeGame());
}

class SnakeGame extends StatelessWidget {
  const SnakeGame({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Snake Game',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      debugShowCheckedModeBanner: false, // Remove debug banner
      home: const SnakeGamePage(),
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({Key? key}) : super(key: key);

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

class _SnakeGamePageState extends State<SnakeGamePage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final int rows = 20;
  final int columns = 20;
  final int initialSnakeLength = 5;
  final Duration snakeSpeed = const Duration(milliseconds: 100); // Increased duration for slower speed

  List<int> snake = [];
  int food = -1;
  int direction = 1; // 0 - up, 1 - right, 2 - down, 3 - left
  bool isPlaying = false;
  int score = 0;

  late Ticker _ticker;

  @override
  void initState() {
    super.initState();
    startGame();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void startGame() {
    snake.clear();
    snake.add(44); // Initial head position at the center of the grid
    generateFood();
    score = 0;

    if (!isPlaying) {
      isPlaying = true;
      _ticker = createTicker((_) => gameLoop());
      _ticker.start();
    }
  }

  void generateFood() {
    final random = Random();
    food = random.nextInt(rows * columns);
  }

  void gameLoop() {
    if (!isPlaying) {
      _ticker.stop();
      return;
    }

    setState(() {
      final currentHead = snake.last;
      int nextCell = -1;

      switch (direction) {
        case 0: // Up
          nextCell = currentHead - columns;
          if (nextCell < 0) nextCell += rows * columns;
          break;
        case 1: // Right
          nextCell = currentHead + 1;
          if (nextCell % columns == 0) nextCell -= columns;
          break;
        case 2: // Down
          nextCell = currentHead + columns;
          if (nextCell >= rows * columns) nextCell -= rows * columns;
          break;
        case 3: // Left
          nextCell = currentHead - 1;
          if ((nextCell + 1) % columns == 0) nextCell += columns;
          break;
      }

      if (snake.contains(nextCell)) {
        // Game over
        isPlaying = false;
        _ticker.stop();
        showGameOverSnackbar();
        return;
      }

      snake.add(nextCell);

      if (nextCell == food) {
        generateFood();
        score++;
      } else {
        snake.removeAt(0);
      }
    });

    if (isPlaying) {
      _ticker.start();
    }
  }

  void showGameOverSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Game Over!',
          style: TextStyle(fontSize: 24),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Play Again',
          textColor: Colors.white,
          onPressed: startGame,
        ),
      ),
    );
  }

  void togglePause() {
    setState(() {
      if (isPlaying) {
        isPlaying = false;
        _ticker.stop();
        showPauseDialog();
      } else {
        Navigator.of(context).pop();
        isPlaying = true;
        _ticker.start();
      }
    });
  }

  void showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Game Paused'),
          content: const Text('What would you like to do?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                togglePause();
              },
              child: const Text('Resume'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                exitGame();
              },
              child: const Text('Exit'),
            ),
          ],
        );
      },
    );
  }

  void exitGame() {
    setState(() {
      isPlaying = false;
      _ticker.stop();
      snake.clear();
    });
  }

  Widget buildGrid() {
    const cellSize = 20.0;

    return Container(
      width: columns * cellSize,
      height: rows * cellSize,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
        ),
        itemBuilder: (BuildContext context, int index) {
          final isSnakeBody = snake.contains(index);
          final isFood = food == index;

          return Container(
            decoration: BoxDecoration(
              color: isSnakeBody
                  ? Colors.green[800]
                  : isFood
                  ? Colors.red[800]
                  : Colors.grey[900],
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: const Text(
          'Snake Game',
          style: TextStyle(fontSize: 24),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (details) {
          if (details.delta.dy > 0 && direction != 0) {
            direction = 2; // Down
          } else if (details.delta.dy < 0 && direction != 2) {
            direction = 0; // Up
          }
        },
        onHorizontalDragUpdate: (details) {
          if (details.delta.dx > 0 && direction != 3) {
            direction = 1; // Right
          } else if (details.delta.dx < 0 && direction != 1) {
            direction = 3; // Left
          }
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Score: $score',
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 16),
              buildGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: togglePause,
        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      ),
    );
  }
}
