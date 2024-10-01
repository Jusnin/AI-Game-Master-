class Door {
  int health;
  int maxHealth = 400;

  Door({this.health = 400});

  void takeDamage(int damage) {
    health -= damage;
    if (health < 0) health = 0;
  }
}

