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
  bool _isDialogOpen = false;

  void _requestFocus() {
    if (!_isDialogOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDialogOpen) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override 
  void setState(VoidCallback fn) {
    super.setState(fn);
    _requestFocus();
  }

  // Добавляем контроллер для управления уведомлениями
  void _showNotification(String message) {
    // Очищаем предыдущие уведомления
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          bottom: MediaQuery.of(context).size.height - 100,
          left: 20,
          right: 20,
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    gameState = GameState();
    gameState.generateMaze();
    _requestFocus();
  }


  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }


  void _showShop() {
    _isDialogOpen = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Shop'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your Gold: ${gameState.gold}'),
              const SizedBox(height: 16),
                ListTile(
                title: const Text('Increase Max HP (+20)'),
                subtitle: Text('Cost: ${100 + (gameState.hpUpgradesPurchased * 50)} gold'),
                trailing: ElevatedButton(
                  onPressed: () {
                    setState(() {
                        if (gameState.buyMaxHpUpgrade(100)) {
                        setDialogState(() {});
                        setState(() {});
                        _showNotification('Max HP increased!');
                        }

                    });
                  },
                  child: const Text('Buy'),
                ),
              ),
                ListTile(
                title: Text('Armor Upgrade (${(5.0 - (gameState.armor * 0.5)).toStringAsFixed(1)}% damage reduction)'),
                subtitle: Text('Cost: ${150 + (gameState.armor * 100)} gold'),
                trailing: ElevatedButton(
                  onPressed: () {
                  setState(() {
                    if (gameState.buyArmorUpgrade(150)) {
                    setDialogState(() {}); // Обновляем состояние диалога
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Armor upgraded!')),
                    );
                    }
                  });
                  },
                  child: const Text('Buy'),
                ),
                ),
              ListTile(
                title: const Text('Healing Potion (+50 HP)'),
                subtitle: const Text('Cost: 50 gold'),
                trailing: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (gameState.buyHealingPotion(50)) {
                        setDialogState(() {}); // Обновляем состояние диалога
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Healing potion bought!')),
                        );
                      }
                    });
                  },
                  child: const Text('Buy'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                    gameState.level++;
                    gameState.generateMaze();
                    gameState.playerPosition = const Position(1, 1);
                    _isDialogOpen = false;
                    _requestFocus();
                });
                },
              child: const Text('Continue to next level'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleMove(Position newPosition) {
    if (_isDialogOpen) return;
    
    if (gameState.movePlayer(newPosition)) {
      setState(() {});
      
      if (gameState.hp <= 0) {
        _showGameOver();
      } else if (gameState.playerPosition == gameState.exit) {
        _showShop();
      }
    }
  }





  void _showAchievements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Достижения'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Уровень подземелья'),
              subtitle: Text('Текущий уровень: ${gameState.level}'),
            ),
            ListTile(
              title: const Text('Собрано золота'),
              subtitle: Text('${gameState.gold}'),
            ),
            ListTile(
              title: const Text('Сделано шагов'),
              subtitle: Text('${gameState.totalSteps}'),
            ),
            ListTile(
              title: const Text('Рейтинг'),
              subtitle: Text('${gameState.calculateRating()}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showGameOver() {
    _isDialogOpen = true;
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
                _isDialogOpen = false;
                _requestFocus();
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
                    value: gameState.hp / gameState.maxHp,
                    backgroundColor: Colors.grey[300],
                    color: _getHpColor(gameState.hp),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${gameState.hp}/${gameState.maxHp}'),
              if (gameState.healingPotions > 0)
                IconButton(
                  icon: const Text('🧪', style: TextStyle(fontSize: 20)),
                  onPressed: () {
                    setState(() {
                      gameState.useHealingPotion();
                    });
                  },
                  tooltip: 'Use Healing Potion',
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('Gold: ${gameState.gold}'),
              Text('Armor: ${gameState.armor}'),
              Text('Potions: ${gameState.healingPotions}'),
              Text(
                'Rating: ${gameState.calculateRating()}',
                style: const TextStyle(
                  color: Colors.purple,
                  fontWeight: FontWeight.bold,
                ),
                ),
              ],
              ),
              const SizedBox(height: 8),
              Row(
              children: [
                const Text('Level: '),
                Text('${gameState.playerLevel}'),
                const SizedBox(width: 16),
                Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                  value: gameState.experience / gameState.experienceToNextLevel,
                  backgroundColor: Colors.grey[300],
                  color: Colors.purple,
                  minHeight: 10,
                  ),
                ),
                ),
                const SizedBox(width: 8),
                Text('${gameState.experience}/${gameState.experienceToNextLevel} XP'),
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
          // Строка с кнопками "Влево", "Зелье" и "Вправо"
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left, size: 40),
                onPressed: () {
                  _handleMove(gameState.playerPosition.translate(dx: -1));
                },
              ),
              if (gameState.healingPotions > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        gameState.useHealingPotion();
                      });
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🧪', style: TextStyle(fontSize: 20)),
                        Text('${gameState.healingPotions}'),
                      ],
                    ),
                  ),
                ),
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
        actions: [
          IconButton(
          icon: const Icon(Icons.emoji_events),
          onPressed: _showAchievements,
          tooltip: 'Достижения',
          ),
        ],
        ),
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: (RawKeyEvent event) {
            if (event is RawKeyDownEvent) {
            Position? newPosition;
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              newPosition = gameState.playerPosition.translate(dx: -1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              newPosition = gameState.playerPosition.translate(dx: 1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              newPosition = gameState.playerPosition.translate(dy: -1);
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              newPosition = gameState.playerPosition.translate(dy: 1);
            }
            
            if (newPosition != null) {
              _handleMove(newPosition);
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
