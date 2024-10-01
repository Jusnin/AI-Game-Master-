class Combatant {
  int health;
  int physicalShield;
  int magicShield;
  int attack;
  int defense;
  String image; 

  Combatant({
    required this.health,
    required this.physicalShield,
    required this.magicShield,
    required this.attack,
    required this.defense,
    required this.image,
  });

  int calculateDamage(int incomingAttack) {
    int damage = incomingAttack - defense;
    return damage > 0 ? damage : 0;
  }

  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) {
      health = 0;
    }
  }

  bool isAlive() {
    return health > 0;
  }
}


class Character extends Combatant {
  String name;

  Character({
    required this.name,
    required super.health,
    required super.attack,
    required super.defense,
    required super.physicalShield,
    required super.magicShield,
    required super.image, 
  });
}

class Enemy extends Combatant {
  String name;

  Enemy({
    required this.name,
    required super.health,
    required super.attack,
    required super.defense,
    required super.physicalShield,
    required super.magicShield,
    required super.image, 
  });
}

