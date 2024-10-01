// lib/services/combat_service.dart
import 'package:mygamemaster/model/combat_model.dart';

enum CombatResult { playerWins, playerLoses, ongoing }

class Combat {
  final Character player;
  final Enemy enemy;

  Combat({required this.player, required this.enemy});

  CombatResult fightTurn() {
    // Player attacks first
    int damageToEnemy = enemy.calculateDamage(player.attack);
    enemy.takeDamage(damageToEnemy);
    print("${player.name} attacks ${enemy.name} for $damageToEnemy damage!");

    if (!enemy.isAlive()) {
      print("${enemy.name} is defeated!");
      return CombatResult.playerWins;
    }

    // Enemy attacks back
    int damageToPlayer = player.calculateDamage(enemy.attack);
    player.takeDamage(damageToPlayer);
    print("${enemy.name} attacks ${player.name} for $damageToPlayer damage!");

    if (!player.isAlive()) {
      print("${player.name} is defeated!");
      return CombatResult.playerLoses;
    }

    return CombatResult.ongoing;
  }
}

