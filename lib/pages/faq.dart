import 'package:flutter/material.dart';

class FAQsPage extends StatelessWidget {
  const FAQsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FAQ', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: const [
          ExpansionTile(
            title: Text('What is MyGameMaster?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'MyGameMaster is a dialogue-based TRPG where players can interact with an AI game master.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('How do I change my settings?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You can change your settings by navigating to the Settings page.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('How do I create a new character?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You can create a new character by navigating to the Character Creation page from the main menu.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('Can I save my game progress?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes, your game progress is automatically saved to the cloud. You can resume your game from the last checkpoint whenever you return.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('Is there a multiplayer mode?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Currently, MyGameMaster is a single-player experience with plans to introduce multiplayer in future updates. Stay tuned!',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('How do I contact support?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You can contact support by navigating to the Help & Support section in the Settings.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('Are there any in-app purchases?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes, MyGameMaster offers in-app purchases for additional content such as story expansions and character customization options.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('How do I reset my password?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'To reset your password, go to the login screen and tap on "Forgot Password?". Follow the instructions to receive an email to reset your password.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('How can I customize my character?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'You can customize your character\'s appearance, skills, and equipment by going to the Character Profile page in the game.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('Can I switch between light and dark mode?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes, you can toggle between light and dark mode in the Settings section of the app.',
                ),
              ),
            ],
          ),
          Divider(),
          ExpansionTile(
            title: Text('Is there offline play available?'),
            children: [
              Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Yes, some features of MyGameMaster are available offline. However, for the best experience, including cloud saves and updates, a stable internet connection is recommended.',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
