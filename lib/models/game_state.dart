// lib/models/game_state.dart

import 'dart:math';

class GameState {
  int level = 1;
  int hp = 100;
  int maxHp = 100;
  int armor = 0;
  int healingPotions = 0;
  int gold = 0;
  int totalSteps = 0;
  int hpUpgradesPurchased = 0; // Счетчик покупок улучшения здоровья
  Position playerPosition = const Position(1, 1);
  Position exit = const Position(13, 13);  // boardSize - 2
  List<Position> walls = [];
  List<Enemy> enemies = [];
  List<Position> hearts = [];
  List<Chest> chests = [];

  static const int boardSize = 15;

  bool buyMaxHpUpgrade(int baseCost) {
    // Увеличиваем стоимость на 50 золота за каждое предыдущее улучшение
    int actualCost = baseCost + (hpUpgradesPurchased * 50);
    if (gold >= actualCost) {
      gold -= actualCost;
      maxHp += 20;
      hp = maxHp;
      hpUpgradesPurchased++;
      return true;
    }
    return false;
  }

  bool buyArmorUpgrade(int baseCost) {
    // Увеличиваем стоимость с каждым уровнем брони
    int actualCost = baseCost + (armor * 100);
    if (gold >= actualCost) {
      gold -= actualCost;
      armor += 1;
      return true;
    }
    return false;
  }

  bool buyHealingPotion(int cost) {
    if (gold >= cost) {
      gold -= cost;
      healingPotions += 1;
      return true;
    }
    return false;
  }

  void useHealingPotion() {
    if (healingPotions > 0) {
      healingPotions--;
      hp = (hp + 50).clamp(0, maxHp);
    }
  }

  void takeDamage(int damage) {
    // Уменьшаем эффективность брони с каждым уровнем
    // Начинаем с 5% и уменьшаем на 0.5% с каждым уровнем
    double totalReduction = 0.0;
    for (int i = 0; i < armor; i++) {
      totalReduction += (5.0 - (i * 0.5)) / 100.0;
    }
    // Ограничиваем максимальное снижение урона до 75%
    totalReduction = totalReduction.clamp(0.0, 0.75);
    
    int reducedDamage = (damage * (1 - totalReduction)).round();
    hp = (hp - reducedDamage).clamp(0, maxHp);
  }

  // Resets the game state
  void reset() {
    level = 1;
    hp = 100;
    maxHp = 100;
    armor = 0;
    healingPotions = 0;
    gold = 0;
    totalSteps = 0;
    hpUpgradesPurchased = 0; // Сбрасываем счетчик улучшений здоровья
    playerPosition = const Position(1, 1);
    exit = const Position(boardSize - 2, boardSize - 2);
    walls.clear();
    enemies.clear();
    hearts.clear();
    chests.clear();
  }

  // Calculate game rating
  int calculateRating() {
    return ((level * level * 1000 + gold * 2) / sqrt(totalSteps + 1)).floor();
  }

  // Check if move is valid
  bool isValidMove(Position newPosition) {
    // Check boundaries
    if (newPosition.x < 0 || 
        newPosition.x >= boardSize || 
        newPosition.y < 0 || 
        newPosition.y >= boardSize) {
      return false;
    }
    
    // Check walls
    return !walls.contains(newPosition);
  }

  // Process player move
  bool movePlayer(Position newPosition) {
    // Проверка границ
    if (newPosition.x < 0 ||
        newPosition.x >= boardSize ||
        newPosition.y < 0 ||
        newPosition.y >= boardSize) {
      return false;
    }
    
    // Проверка стен
    if (walls.contains(newPosition)) {
      return false;
    }
    
    totalSteps++;

    // Проверка столкновения с врагом
    Enemy? enemy;
    try {
      enemy = enemies.firstWhere((e) => e.position == newPosition && !e.defeated);
    } catch (e) {
      enemy = null;
    }

    if (enemy != null) {
      takeDamage(enemy.damage);
      gold += enemy.damage;
      enemy.defeated = true;
    }

    // Проверка сбора сердца
    final heartIndex = hearts.indexOf(newPosition);
    if (heartIndex != -1) {
      if (hp >= maxHp) {
      // Если здоровье полное, получаем зелье
      healingPotions++;
      } else {
      // Иначе восстанавливаем здоровье
      hp = maxHp;
      }
      hearts.removeAt(heartIndex);
    }

    // Проверка сбора сундука
    Chest? chest;
    try {
      chest = chests.firstWhere((c) => c.position == newPosition && !c.collected);
    } catch (e) {
      chest = null;
    }

    if (chest != null) {
      gold += chest.gold;
      chest.collected = true;
    }

    // Перемещение игрока
    playerPosition = newPosition;

    return true;

  }

  // Генерация лабиринта
  void generateMaze() {
    final random = Random();
    walls.clear();
    enemies.clear();
    hearts.clear();
    chests.clear();

    // Add outer walls
    for (int i = 0; i < boardSize; i++) {
      walls.add(Position(0, i));
      walls.add(Position(boardSize - 1, i));
      walls.add(Position(i, 0));
      walls.add(Position(i, boardSize - 1));
    }

    // Generate random room dividers
    for (int i = 2; i < boardSize - 2; i += 3) {
      for (int j = 2; j < boardSize - 2; j += 3) {
        if (random.nextDouble() < 0.7) {
          if (random.nextDouble() < 0.5) {
            // Horizontal walls
            for (int k = 0; k < 3; k++) {
              if (random.nextDouble() < 0.8 &&
                  !(i == 1 && j + k == 1) &&
                  !(i == boardSize - 2 && j + k == boardSize - 2)) {
                walls.add(Position(i, j + k));
              }
            }
          } else {
            // Vertical walls
            for (int k = 0; k < 3; k++) {
              if (random.nextDouble() < 0.8 &&
                  !(i + k == 1 && j == 1) &&
                  !(i + k == boardSize - 2 && j == boardSize - 2)) {
                walls.add(Position(i + k, j));
              }
            }
          }
        }
      }
    }

    // Add enemies
    final numEnemies = 5 + (level * 1.5).floor();
    while (enemies.length < numEnemies) {
      final x = random.nextInt(boardSize - 2) + 1;
      final y = random.nextInt(boardSize - 2) + 1;
      final position = Position(x, y);

      if (!isPositionOccupied(position)) {
        enemies.add(generateEnemy(position));
      }
    }

    // Add hearts
    final numHearts = 1 + (level / 4).floor();
    while (hearts.length < numHearts) {
      final x = random.nextInt(boardSize - 2) + 1;
      final y = random.nextInt(boardSize - 2) + 1;
      final position = Position(x, y);

      if (!isPositionOccupied(position)) {
        hearts.add(position);
      }
    }

    // Add chests
    final numChests = 2 + (level / 3).floor();
    while (chests.length < numChests) {
      final x = random.nextInt(boardSize - 2) + 1;
      final y = random.nextInt(boardSize - 2) + 1;
      final position = Position(x, y);

      if (!isPositionOccupied(position)) {
        chests.add(generateChest(position));
      }
    }
  }

  Enemy generateEnemy(Position position) {
    final random = Random();
    final baseDamage = (level / 2).floor();
    const types = [
      {'damage': 10, 'color': 'red-400'},
      {'damage': 20, 'color': 'red-600'},
      {'damage': 30, 'color': 'red-800'},
      {'damage': 40, 'color': 'purple-600'},
    ];

    final typeIndex = min(
      (random.nextDouble() * (1 + level / 3)).floor(),
      types.length - 1,
    );

    final type = types[typeIndex];
    return Enemy(
      position: position,
      damage: (type['damage'] as int) + baseDamage,
      color: type['color'] as String,
    );
  }

  Chest generateChest(Position position) {
    final random = Random();
    const baseGold = 50;
    final goldAmount = baseGold + random.nextInt(level * 30);

    return Chest(
      position: position,
      gold: goldAmount,
    );
  }

  bool isPositionOccupied(Position position) {
    // Check if position is player start or exit
    if ((position.x == 1 && position.y == 1) ||
        (position.x == exit.x && position.y == exit.y)) {
      return true;
    }

    // Check walls
    if (walls.contains(position)) {
      return true;
    }

    // Check enemies
    if (enemies.any((enemy) => enemy.position == position)) {
      return true;
    }

    // Check hearts
    if (hearts.contains(position)) {
      return true;
    }

    // Check chests
    if (chests.any((chest) => chest.position == position)) {
      return true;
    }

    return false;
  }
}

class Position {
  final int x;
  final int y;

  const Position(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Position &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  Position translate({int dx = 0, int dy = 0}) {
    return Position(x + dx, y + dy);
  }
}

class Enemy {
  final Position position;
  final int damage;
  final String color;
  bool defeated;

  Enemy({
    required this.position,
    required this.damage,
    required this.color,
    this.defeated = false,
  });
}

class Chest {
  final Position position;
  final int gold;
  bool collected;

  Chest({
    required this.position,
    required this.gold,
    this.collected = false,
  });
}