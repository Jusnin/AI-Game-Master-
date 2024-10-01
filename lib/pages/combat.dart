import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mygamemaster/model/combat_model.dart';
import 'package:mygamemaster/pages/roll_dice.dart';
import 'package:mygamemaster/services/combat_service.dart';
import 'package:mygamemaster/widgets/health_bar.dart';

class CombatScreen extends StatefulWidget {
  final Character player;
  final Enemy enemy;

  const CombatScreen({required this.player, required this.enemy, super.key});

  @override
  _CombatScreenState createState() => _CombatScreenState();
}

class _CombatScreenState extends State<CombatScreen>
    with SingleTickerProviderStateMixin {
  late Character _player;
  late Enemy _enemy;
  String _latestPlayerResponse = '';
  String _latestEnemyResponse = '';
  final List<String> _combatLog = [];
  bool _combatOver = false;
  bool _isPlayerTurn = true;
  int _combatResult = 0; // Initialize combat_result to 0 (ongoing)

  final ScrollController _scrollController = ScrollController();

  final List<String> _inventory = ["Healing Potion", "Magic Scroll"];
  final List<String> _abilities = ["Fireball", "Lightning Strike", "Heal"];
  final Map<String, int> _itemUsageCount = {
    "Healing Potion": 5,
    "Magic Scroll": 5,
  };

  @override
  void initState() {
    super.initState();
    _player = widget.player;
    _enemy = widget.enemy;
  }


   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900,
      appBar: AppBar(
        title: const Text("Combat"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildCharacterRow(),
            const SizedBox(height: 20),
            _buildCombatLog(),
            const SizedBox(height: 20),
            _buildActionButtons(),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showCombatLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
              ),
              child: const Text("View Combat Log"),
            ),
            if (_combatOver)
              ElevatedButton(
                onPressed: () {
                  if (_combatResult == 0) {
                    // Set combat_result to 2 (loss) if the player hasn't won or lost already
                    _combatResult = 2;
                  }
                  print("Combat result sent: ${_combatResult == 1 ? 'win' : 'lose'}");

                  // Pass the combat result back to ChatRoom
                  Navigator.pop(context, _combatResult);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                child: const Text("End Combat"),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterColumn(Combatant combatant, String imagePath) {
    const textColor =
        Color.fromARGB(255, 208, 208, 208); // Fixed color for text
    String combatantName = '';

    // Determine the combatant's name based on its type
    if (combatant is Character) {
      combatantName = combatant.name;
    } else if (combatant is Enemy) {
      combatantName = combatant.name;
    }

    return Expanded(
      child: Column(
        children: [
          Text(combatantName, // Display the correct character name
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const SizedBox(height: 5),
          HealthBar(
            currentHealth: combatant.health,
            maxHealth:
                combatant is Character ? 100 : 110, // Example max health values
          ),
          const SizedBox(height: 5),
          _buildShieldBar(combatant),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              color: Colors.grey.shade300, // Fixed background color
            ),
            child: Image.asset(imagePath,
                height: 100, width: 100), // Character image
          ),
        ],
      ),
    );
  }

Widget _buildCharacterRow() {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      _buildCharacterColumn(
          _player, _player.image), // Use player's image
      const SizedBox(width: 16),
      _buildCharacterColumn(
          _enemy, _enemy.image), // Use enemy's image
    ],
  );
}



  Widget _buildShieldBar(Combatant combatant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              flex: combatant.physicalShield,
              child: Container(
                height: 20.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.grey,
                      Colors.white
                    ], // Gradient for physical shield
                  ),
                ),
                child: Center(
                  child: Text(
                    '${combatant.physicalShield} / ${combatant.physicalShield}', // Physical shield value
                    style: const TextStyle(color: Colors.black, fontSize: 12),
                  ),
                ),
              ),
            ),
            Flexible(
              flex: combatant.magicShield,
              child: Container(
                height: 20.0,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4.0),
                  gradient: const LinearGradient(
                    colors: [
                      Colors.blue,
                      Colors.lightBlueAccent
                    ], // Gradient for magic shield
                  ),
                ),
                child: Center(
                  child: Text(
                    '${combatant.magicShield} / ${combatant.magicShield}', // Magic shield value
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCombatLog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          color: Colors.blueGrey.shade800,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: SingleChildScrollView(
          controller: _scrollController, // Attach the scroll controller
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _combatLog.map((entry) {
              return Column(
                children: [
                  Text(entry,
                      style:
                          const TextStyle(color: Colors.white, fontSize: 14)),
                  const Divider(
                      color: Colors
                          .white24), // Separator line for better readability
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton("Attack", _rollDiceAndAttack, Colors.redAccent),
            _buildActionButton("Defend", _defend, Colors.blueAccent),
            _buildActionButton("Use Ability", () => _showAbilitiesDialog(),
                Colors.purpleAccent),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
                "Use Item", () => _showItemsDialog(), Colors.greenAccent),
_buildActionButton("Give Up", () {
  _giveUp();
}, Colors.orangeAccent),

          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onPressed, Color color) {
    return ElevatedButton(
      onPressed: _combatOver || !_isPlayerTurn ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 24.0),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 16, color: Colors.white)),
    );
  }

  void _showItemsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select an Item',
              style: TextStyle(color: Colors.white)),
          backgroundColor:
              Colors.blueGrey.shade900, // Match background color to theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          children: _inventory.map((item) {
            int remaining = _itemUsageCount[item] ?? 0;
            return SimpleDialogOption(
              onPressed: () {
                if (remaining > 0) {
                  Navigator.pop(context);
                  _useItem(item);
                } else {
                  setState(() {
                    _latestPlayerResponse = 'You have no $item left!';
                    _combatLog.add(_latestPlayerResponse);
                  });
                }
              },
              child: Text('$item ($remaining left)',
                  style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAbilitiesDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: const Text('Select an Ability',
              style: TextStyle(color: Colors.white)),
          backgroundColor:
              Colors.blueGrey.shade900, // Match background color to theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          children: _abilities.map((ability) {
            return SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _useAbility(ability);
              },
              child: Text(ability, style: const TextStyle(color: Colors.white)),
            );
          }).toList(),
        );
      },
    );
  }

  void _showCombatLog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              const Text('Combat Log', style: TextStyle(color: Colors.white)),
          backgroundColor:
              Colors.blueGrey.shade900, // Match background color to theme
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _combatLog
                  .map((entry) => Text(entry,
                      style:
                          const TextStyle(fontSize: 14, color: Colors.white)))
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.teal)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _rollDiceAndAttack() async {
    await _performAction(() async {
      final diceRoll = await _rollDice();

      if (diceRoll != null) {
        int modifiedAttack = _player.attack;
        int damageDealt = 0;
        if (diceRoll == 1) {
          _latestPlayerResponse =
              'You rolled a 1! Your attack failed, and you were countered!';
          _player.takeDamage(10); // Player gets punished
        } else if (diceRoll == 2) {
          _latestPlayerResponse = 'You rolled a 2! Your attack failed.';
        } else if (diceRoll == 3 || diceRoll == 4) {
          modifiedAttack += diceRoll;
          damageDealt = modifiedAttack;
          _latestPlayerResponse =
              'You rolled a $diceRoll! Your attack succeeded, dealing $damageDealt damage!';
          _applyPhysicalDamage(_enemy, damageDealt);
        } else if (diceRoll == 5 || diceRoll == 6) {
          modifiedAttack += diceRoll;
          damageDealt = modifiedAttack + 5; // Extra reward
          _latestPlayerResponse =
              'You rolled a $diceRoll! Your attack was powerful, dealing $damageDealt damage!';
          _applyPhysicalDamage(_enemy, damageDealt);
        }

        CombatResult result = _checkCombatOver();
        if (result == CombatResult.ongoing) {
          _combatLog.add(_latestPlayerResponse);
        }
      }
    });
  }

  Future<void> _defend() async {
    await _performAction(() async {
      final diceRoll = await _rollDice();

      if (diceRoll != null) {
        if (diceRoll == 1) {
          int damage = (_enemy.attack * 1.5).round();
          _latestPlayerResponse =
              'You rolled a 1! Your defense failed spectacularly, and you took $damage damage!';
          _player.takeDamage(damage);
        } else if (diceRoll == 2) {
          int damage = _enemy.attack;
          _latestPlayerResponse =
              'You rolled a 2! Your defense failed, and you took $damage damage.';
          _player.takeDamage(damage);
        } else if (diceRoll == 3 || diceRoll == 4) {
          _latestPlayerResponse =
              'You rolled a $diceRoll! Your defense succeeded, and you blocked all damage.';
          // No damage taken, all damage blocked.
        } else if (diceRoll == 5 || diceRoll == 6) {
          int counterDamage =
              _player.attack * 2; // Double the player's attack for counter
          _latestPlayerResponse =
              'You rolled a $diceRoll! Your defense was exceptional, blocking all damage and countering with $counterDamage damage!';
          _applyPhysicalDamage(_enemy, counterDamage);
        }

        _combatLog.add(_latestPlayerResponse);
        CombatResult result = _checkCombatOver();
        if (result == CombatResult.ongoing) {
          _combatLog.add(_latestPlayerResponse);
        }
      }
    });
  }

  Future<void> _useAbility(String ability) async {
    await _performAction(() async {
      final diceRoll = await _rollDice();

      if (diceRoll != null) {
        int abilityDamage = _player.attack + 10; // Default ability effect
        int damageDealt = 0;
        int healingAmount = 20; // Default healing amount

        if (diceRoll == 1) {
          _latestPlayerResponse =
              'You rolled a 1! Your ability failed, and you were countered!';
          _player.takeDamage(10); // Player gets punished
        } else if (diceRoll == 2) {
          _latestPlayerResponse = 'You rolled a 2! Your ability failed.';
        } else if (diceRoll == 3 || diceRoll == 4) {
          if (ability == "Heal") {
            _player.health += healingAmount; // Heal ability restores health
            _latestPlayerResponse =
                'You rolled a $diceRoll! You heal for $healingAmount health points.';
          } else {
            damageDealt = abilityDamage;
            _latestPlayerResponse =
                'You rolled a $diceRoll! Your ability succeeded, dealing $damageDealt damage!';
            _applyMagicDamage(_enemy, damageDealt);
          }
        } else if (diceRoll == 5 || diceRoll == 6) {
          if (ability == "Heal") {
            _player.health += healingAmount * 2; // Double healing
            _latestPlayerResponse =
                'You rolled a $diceRoll! Your ability was powerful, healing you for ${healingAmount * 2} health points!';
          } else {
            damageDealt = abilityDamage + 5; // Extra reward
            _latestPlayerResponse =
                'You rolled a $diceRoll! Your ability was powerful, dealing $damageDealt damage!';
            _applyMagicDamage(_enemy, damageDealt);
          }
        }

        CombatResult result = _checkCombatOver();
        if (result == CombatResult.ongoing) {
          _combatLog.add(_latestPlayerResponse);
        }
      }
    });
  }

  Future<void> _useItem(String item) async {
    if (_itemUsageCount[item]! <= 0) {
      setState(() {
        _latestPlayerResponse = 'You have no $item left!';
        _combatLog.add(_latestPlayerResponse);
      });
      return;
    }

    await _performAction(() async {
      final diceRoll = await _rollDice();

      if (diceRoll != null) {
        String actionResponse = 'You used $item!\n';
        int damageDealt = 0;

        if (diceRoll == 1) {
          actionResponse =
              'You rolled a 1! Your item use failed, and you were countered!';
          _player.takeDamage(10); // Player gets punished
        } else if (diceRoll == 2) {
          actionResponse = 'You rolled a 2! Your item use failed.';
        } else if (diceRoll == 3 || diceRoll == 4) {
          actionResponse = 'You rolled a $diceRoll! Your item use succeeded.';
        } else if (diceRoll == 5 || diceRoll == 6) {
          actionResponse =
              'You rolled a $diceRoll! Your item use was powerful and had extra effect!';
        }

        if (item == "Healing Potion") {
          _player.health += 20;
          actionResponse += ' You restored 20 health points.';
        } else if (item == "Magic Scroll") {
          int scrollDamage = _player.attack + 15;
          damageDealt = scrollDamage;
          actionResponse +=
              ' You dealt $damageDealt magic damage to the enemy with the Magic Scroll.';
          _applyMagicDamage(_enemy, scrollDamage);
        }

        _itemUsageCount[item] = _itemUsageCount[item]! - 1;

        _latestPlayerResponse = actionResponse;
        _combatLog.add(actionResponse);

        _checkCombatOver();
      }
    });
  }


  Future<void> _giveUp() async {
    setState(() {
      _latestPlayerResponse = 'You have given up the fight!';
      _combatLog.add(_latestPlayerResponse);
      _combatOver = true;
      _combatResult = 2;  // Mark combat as lost if the player gives up
    });
  }


  Future<void> _performAction(Future<void> Function() action) async {
    setState(() {
      _isPlayerTurn = false;
    });

    await action();

    if (!_combatOver) {
      await Future.delayed(const Duration(seconds: 1));
      await _enemyTurn();
    }

    setState(() {
      _isPlayerTurn = true;
    });
  }

  Future<void> _enemyTurn() async {
    await Future.delayed(const Duration(seconds: 1));

    final diceRoll = Random().nextInt(6) + 1; // Simulate enemy dice roll (1-6)
    int damageDealt = _enemy.attack;
    String actionResponse = 'The enemy rolled a $diceRoll!\n';

    setState(() {
      if (diceRoll == 1) {
        actionResponse +=
            'The enemy rolled a 1! Its attack failed, and it took 10 damage from backlash!';
        _enemy.takeDamage(10); // Enemy takes self-damage
      } else if (diceRoll == 2) {
        actionResponse += 'The enemy rolled a 2! Its attack failed.';
        // No damage dealt to player
      } else if (diceRoll == 3 || diceRoll == 4) {
        actionResponse +=
            'The enemy rolled a $diceRoll! Its attack succeeded, dealing $damageDealt damage!';
        _applyPhysicalDamage(_player, damageDealt);
      } else if (diceRoll == 5 || diceRoll == 6) {
        damageDealt += 5; // Extra damage for successful roll
        actionResponse +=
            'The enemy rolled a $diceRoll! Its attack was powerful, dealing $damageDealt damage!';
        _applyPhysicalDamage(_player, damageDealt);
      }

      _latestEnemyResponse = actionResponse;
      _combatLog.add(actionResponse);

      _checkCombatOver();
    });
  }

  Future<int?> _rollDice() async {
    return await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return const RollingDiceWidget();
      },
    );
  }

  void _applyPhysicalDamage(Combatant combatant, int damage) {
    if (combatant.physicalShield > 0) {
      combatant.physicalShield -= damage;
      if (combatant.physicalShield < 0) {
        combatant.health +=
            combatant.physicalShield; // Spillover damage to health
        combatant.physicalShield = 0;
      }
    } else {
      combatant.takeDamage(damage);
    }
  }

  void _applyMagicDamage(Combatant combatant, int damage) {
    if (combatant.magicShield > 0) {
      combatant.magicShield -= damage;
      if (combatant.magicShield < 0) {
        combatant.health += combatant.magicShield; // Spillover damage to health
        combatant.magicShield = 0;
      }
    } else {
      combatant.takeDamage(damage);
    }
  }

  CombatResult _checkCombatOver() {
    if (_enemy.health <= 0) {
      setState(() {
        _latestPlayerResponse += ' The enemy is defeated! You have won the battle.';
        _combatLog.add(_latestPlayerResponse);
        _combatOver = true;
        _combatResult = 1;  // Set combat_result to 1 (win)
      });
      return CombatResult.playerWins;
    } else if (_player.health <= 0) {
      setState(() {
        _latestEnemyResponse += ' You were defeated by the enemy. You have lost the battle.';
        _combatLog.add(_latestEnemyResponse);
        _combatOver = true;
        _combatResult = 2;  // Set combat_result to 2 (loss)
      });
      return CombatResult.playerLoses;
    }
    return CombatResult.ongoing;
  }
}