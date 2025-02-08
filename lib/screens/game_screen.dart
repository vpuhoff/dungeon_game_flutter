import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_state.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState gameState;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.generateMaze();
    // Запрос фокуса для получения событий клавиатуры
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleMove(Position newPosition) {
    // Выполняем движение игрока
    gameState.movePlayer(newPosition);
    setState(() {});
    // Если здоровье игрока стало 0 или меньше, показываем Game Over
    if (gameState.hp <= 0) {
      _showGameOver();
    }
  }


  void _showGameOver() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Game Over'),
        content: Text(
          'You reached Floor ${gameState.level}\n'
          'Total Gold: ${gameState.gold}\n'
          'Steps Made: ${gameState.totalSteps}\n'
          'Final Rating: ${gameState.calculateRating()}',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                gameState.reset();
                gameState.generateMaze();
              });
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  Widget buildCell(int x, int y) {
    final position = Position(x, y);
    final isWall = gameState.walls.contains(position);
    final isPlayer = gameState.playerPosition == position;
    final enemy = gameState.enemies.firstWhere(
      (e) => e.position == position && !e.defeated,
      orElse: () => Enemy(
        position: const Position(-1, -1),
        damage: 0,
        color: 'none',
      ),
    );
    final isHeart = gameState.hearts.contains(position);
    final chest = gameState.chests.firstWhere(
      (c) => c.position == position && !c.collected,
      orElse: () => Chest(
        position: const Position(-1, -1),
        gold: 0,
      ),
    );
    final isExit = gameState.exit == position;

    return Container(
      decoration: BoxDecoration(
        color: isWall ? Colors.grey[800] : Colors.white,
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: _buildCellContent(
          isPlayer: isPlayer,
          enemy: enemy.position == position ? enemy : null,
          isHeart: isHeart,
          chest: chest.position == position ? chest : null,
          isExit: isExit,
        ),
      ),
    );
  }

  Widget _buildCellContent({
    required bool isPlayer,
    Enemy? enemy,
    required bool isHeart,
    Chest? chest,
    required bool isExit,
  }) {
    if (isPlayer) {
      return Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          color: Colors.blue,
          shape: BoxShape.circle,
        ),
      );
    }

    if (enemy != null) {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: _getEnemyColor(enemy.color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '${enemy.damage}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    if (isHeart) {
      return const Text('❤️', style: TextStyle(fontSize: 16));
    }

    if (chest != null) {
      return const Text('📦', style: TextStyle(fontSize: 14));
    }

    if (isExit) {
      return const Text('🚪', style: TextStyle(fontSize: 16));
    }

    return const SizedBox.shrink();
  }

  Color _getEnemyColor(String colorName) {
    switch (colorName) {
      case 'red-400':
        return Colors.red[400]!;
      case 'red-600':
        return Colors.red[600]!;
      case 'red-800':
        return Colors.red[800]!;
      case 'purple-600':
        return Colors.purple[600]!;
      default:
        return Colors.red;
    }
  }

  Widget buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text('HP: '),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: gameState.hp / 100,
                    backgroundColor: Colors.grey[300],
                    color: _getHpColor(gameState.hp),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${gameState.hp}%'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Gold: ${gameState.gold}'),
              Text('Steps: ${gameState.totalSteps}'),
              Text(
                'Rating: ${gameState.calculateRating()}',
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getHpColor(int hp) {
    if (hp > 60) return Colors.green;
    if (hp > 30) return Colors.orange;
    return Colors.red;
  }

  /// Виджет джойстика для управления игроком.
  Widget buildJoystick() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Кнопка "Вверх"
          IconButton(
            icon: const Icon(Icons.arrow_drop_up, size: 40),
            onPressed: () {
              _handleMove(gameState.playerPosition.translate(dy: -1));
            },
          ),
          // Строка с кнопками "Влево" и "Вправо"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, size: 40),
                onPressed: () {
                  _handleMove(gameState.playerPosition.translate(dx: -1));
                },
              ),
              const SizedBox(width: 30),
              IconButton(
                icon: const Icon(Icons.arrow_right, size: 40),
                onPressed: () {
                  _handleMove(gameState.playerPosition.translate(dx: 1));
                },
              ),
            ],
          ),
          // Кнопка "Вниз"
          IconButton(
            icon: const Icon(Icons.arrow_drop_down, size: 40),
            onPressed: () {
              _handleMove(gameState.playerPosition.translate(dy: 1));
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Floor ${gameState.level}'),
      ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (RawKeyEvent event) {
          if (event is RawKeyDownEvent) {
            // Обработка нажатий клавиш-стрелок
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              _handleMove(gameState.playerPosition.translate(dx: -1));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              _handleMove(gameState.playerPosition.translate(dx: 1));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _handleMove(gameState.playerPosition.translate(dy: -1));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _handleMove(gameState.playerPosition.translate(dy: 1));
            }
          }
        },
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                // При необходимости можно оставить обработчики свайпов
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: GameState.boardSize,
                  ),
                  itemCount: GameState.boardSize * GameState.boardSize,
                  itemBuilder: (context, index) {
                    final x = index % GameState.boardSize;
                    final y = index ~/ GameState.boardSize;
                    return buildCell(x, y);
                  },
                ),
              ),
            ),
            // Отрисовка джойстика под картой
            buildJoystick(),
            // Статус-бар
            buildStatusBar(),
          ],
        ),
      ),
    );
  }
}
