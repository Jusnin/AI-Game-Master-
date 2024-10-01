import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'roll_dice.dart'; // Import the dice rolling widget

class TutorialPage extends StatefulWidget {
  const TutorialPage({super.key});

  @override
  _TutorialPageState createState() => _TutorialPageState();
}

class _TutorialPageState extends State<TutorialPage> {
  List<Tutorial> tutorials = const [
    Tutorial(
      id: 1,
      title: 'How to Create a Character',
      description: 'Learn the steps to create your own character with stats, appearance, and background.',
      content: '''
Creating a character is the first step to starting your adventure. Follow these steps:

1. **Open the Character Creation Page:** Navigate to the character creation page from the main menu.
2. **Choose Your Stats:** Distribute points into Strength, Intelligence, Dexterity, and Charisma. Each stat affects gameplay in different ways:
   - Strength: Affects physical combat and tasks.
   - Intelligence: Affects spell casting and learning new abilities.
   - Dexterity: Helps with agility and ranged attacks.
   - Charisma: Useful for negotiations and interactions with NPCs.
3. **Customize Appearance:** Choose a unique look for your character with various options like skin color, hairstyles, and outfits.
4. **Background Story:** Write a backstory for your character. This helps define motivations and the type of quests you’ll take on.
5. **Save Your Character:** Once you’re happy with your creation, click the "Save" button. Now you’re ready to begin the game.
''',
      imagePath: 'assets/images/character_creation.jpg',
    ),
    Tutorial(
      id: 2,
      title: 'Understanding the Game World',
      description: 'A guide to understanding how the game world reacts to your choices and evolves over time.',
      content: '''
The game world is dynamic and reacts to the decisions you make during your journey. Here are key aspects to understand:

1. **NPC Relationships:** Non-playable characters (NPCs) remember your actions. Depending on how you interact with them, they can become allies, enemies, or neutral figures.
2. **Environmental Changes:** The game world can change based on your decisions. For example, a decision to help or harm a village may lead to a thriving or devastated community when you return later.
3. **Hidden Areas:** As you progress, new regions and hidden areas will unlock. Explore thoroughly to find valuable items, quests, and companions.
4. **Day-Night Cycle and Weather:** The game world features a day-night cycle and weather system. Some quests or items are only available at certain times or in specific weather conditions.
5. **Story Progression:** The main storyline progresses based on your actions. Multiple possible endings exist, so choose wisely.
''',
      imagePath: 'assets/images/game_world.jpg',
    ),
    Tutorial(
      id: 3,
      title: 'Basic Combat Mechanics',
      description: 'An introduction to how combat works and strategies for success in battles.',
      content: '''
Combat in this game is turn-based, meaning each participant gets a chance to act before passing the turn. Understanding the mechanics is essential to mastering battles:

1. **Turn-Based System:** Combat is not real-time, so you have time to think about your actions.
2. **Action Choices:**
   - Attack: Deal damage to an enemy using physical weapons or spells.
   - Defend: Increase your defenses for the next turn to reduce incoming damage.
   - Abilities: Use character-specific abilities that offer unique advantages like healing, buffing, or debuffing enemies.
   - Items: Use items such as potions, traps, or tools to gain an edge in battle.
3. **Health and Shields:** Keep an eye on your health bar. If it drops to zero, the character is knocked out. Shields offer extra protection and must be broken before taking health damage.
4. **Strategies:**
   - Always assess the situation before making your move.
   - Target enemies with low health or shields to reduce the number of foes quickly.
   - Use abilities and items wisely to gain advantages, such as healing yourself or weakening enemies.
   - Remember to retreat when outnumbered or under-leveled. Retreating can be the smarter choice at times.
''',
      imagePath: 'assets/images/combat_mechanics.jpg',
    ),
    Tutorial(
      id: 4,
      title: 'Questing and Storytelling',
      description: 'Discover how quests work and how they contribute to the game’s narrative.',
      content: '''
Quests are the backbone of the game, providing direction, rewards, and story progression. Here’s how they work:

1. **Main Quests:** These advance the central storyline of the game. Completing them is necessary to finish the game, but how you complete them is up to you.
2. **Side Quests:** These optional quests offer additional challenges and rewards. They can involve helping NPCs, finding hidden treasures, or defeating monsters.
3. **Quest Objectives:** Always pay attention to quest objectives. Some quests have multiple ways to complete them, affecting the game world in different ways.
4. **Dialogue Choices:** Conversations with NPCs during quests will often give you choices. These can lead to different outcomes, alliances, or enemies.
5. **Tracking Quests:** Use the in-game journal to track active and completed quests. The journal also provides hints on where to go and what to do next.
6. **Rewards:** Completing quests can reward you with gold, items, experience points, or improved relationships with characters.
''',
      imagePath: 'assets/images/questing.jpg',
    ),
    Tutorial(
      id: 5,
      title: 'Dice Rolling Mechanics',
      description: 'Learn about dice rolls and how to simulate them in-game.',
      content: '''
Dice rolls play a critical role in determining the outcome of various actions in the game. Whether it’s an attack, skill check, or negotiation, here’s how it works:

1. **Dice Types:** The game uses a standard six-sided die (D6) for determining outcomes.
2. **Chance and Probability:** Higher rolls result in better outcomes, whether it’s damage in combat or success in a skill check.
3. **Modifiers:** Your character's stats, abilities, and equipment can add modifiers to dice rolls. For example, a high Strength stat might give you a +2 bonus on physical attacks.

You can try rolling a dice to simulate the mechanics by pressing the button below:
''',
      imagePath: 'assets/images/dice_rolling.jpg',
      includeDiceTrial: true, // New field to indicate dice trial should be included
    ),
  ];

  List<int> completedTutorials = [];

  @override
  void initState() {
    super.initState();
    _loadCompletedTutorials();
  }

  Future<void> _loadCompletedTutorials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      completedTutorials = prefs.getStringList('completedTutorials')?.map((id) => int.parse(id)).toList() ?? [];
    });
  }

  Future<void> _saveCompletedTutorial(int tutorialId) async {
    if (!completedTutorials.contains(tutorialId)) {
      setState(() {
        completedTutorials.add(tutorialId);
      });
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setStringList('completedTutorials', completedTutorials.map((id) => id.toString()).toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorials'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: tutorials.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildTrpgIntroduction(context); // TRPG introduction at the start
          }
          final tutorial = tutorials[index - 1];
          final isCompleted = completedTutorials.contains(tutorial.id);
          return Card(
            color: isCompleted ? Colors.greenAccent.shade100 : Colors.blueGrey.shade800,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              title: Text(
                tutorial.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                    ),
              ),
              subtitle: Text(
                tutorial.description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              trailing: isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : null,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TutorialDetailPage(
                      tutorial: tutorial,
                      onComplete: () => _saveCompletedTutorial(tutorial.id),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrpgIntroduction(BuildContext context) {
    return Card(
      color: Colors.blueGrey.shade700,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'What is TRPG (Tabletop Role-Playing Game)?',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Image.asset('assets/images/trpg_example.jpg', height: 200),
            const SizedBox(height: 10),
            Text(
              '''
A Tabletop Role-Playing Game (TRPG) is a game where players assume the roles of characters in a fictional setting. Players use dice and their imaginations to interact with the game world and make decisions that impact the storyline.
TRPGs are known for their focus on storytelling, player freedom, and collaborative play, with the Game Master guiding the narrative.
''',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.help),
              label: const Text('Learn More About TRPG'),
              onPressed: () {
                _showTrpgDetails(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
          ],
        ),
      ),
    );
  }

  void _showTrpgDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('More About TRPG'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('In a TRPG, storytelling is key.'),
              SizedBox(height: 10),
              Text('• Players make decisions that influence the game world.'),
              Text('• The Game Master (GM) guides the narrative, setting challenges.'),
              Text('• Dice are used to add an element of chance to actions.'),
            ],
          ),
          actions: [
            ElevatedButton(
              child: const Text('Got It!'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSearchDialog(BuildContext context) {
    showSearch(
      context: context,
      delegate: TutorialSearchDelegate(tutorials),
    );
  }
}

class TutorialDetailPage extends StatelessWidget {
  final Tutorial tutorial;
  final VoidCallback onComplete;

  const TutorialDetailPage({
    super.key,
    required this.tutorial,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tutorial.title),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(tutorial.imagePath, height: 200),
            const SizedBox(height: 20),
            Text(
              tutorial.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                  ),
            ),
            if (tutorial.includeDiceTrial) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _showDiceRollingTrial(context); // Show dice rolling trial
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                child: const Text('Try Dice Rolling'),
              ),
            ],
          ],
        ),
      ),
      backgroundColor: Colors.blueGrey.shade900,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.check),
        onPressed: () {
          onComplete();
          Navigator.pop(context);
        },
      ),
    );
  }

  // Show Dice Rolling Trial Modal
  void _showDiceRollingTrial(BuildContext context) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return const RollingDiceWidget();
      },
    );

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You rolled a $result!')),
      );
    }
  }
}

class TutorialSearchDelegate extends SearchDelegate {
  final List<Tutorial> tutorials;

  TutorialSearchDelegate(this.tutorials);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [IconButton(icon: const Icon(Icons.clear), onPressed: () => query = '')];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => close(context, null));
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = tutorials.where((tutorial) => tutorial.title.toLowerCase().contains(query.toLowerCase())).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        return ListTile(
          title: Text(result.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => TutorialDetailPage(tutorial: result, onComplete: () {})),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return buildResults(context);
  }
}

class Tutorial {
  final int id;
  final String title;
  final String description;
  final String content;
  final String imagePath;
  final bool includeDiceTrial;

  const Tutorial({
    required this.id,
    required this.title,
    required this.description,
    required this.content,
    required this.imagePath,
    this.includeDiceTrial = false, // Default is false unless it's Dice Rolling Mechanics
  });
}
