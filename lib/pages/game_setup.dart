import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mygamemaster/pages/newchatroom.dart';

class GameSetupPage extends StatefulWidget {
  const GameSetupPage({super.key});

  @override
  _GameSetupPageState createState() => _GameSetupPageState();
}

class _GameSetupPageState extends State<GameSetupPage> {
  String? selectedCharacter;
  String? selectedStory;
  String? selectedWorld;
  String? storyDescription;
  String? worldDescription;
  Map<String, dynamic>? characterData;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch Dropdown Items from Firestore for the logged-in user
  Future<List<DropdownMenuItem<String>>> _buildDropdownItems(
      String collection, String field) async {
    User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception("User not logged in");
    }

    final snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('uid', isEqualTo: currentUser.uid)
        .get();

    return snapshot.docs
        .map((doc) => DropdownMenuItem<String>(
              value: doc.id,
              child: Text(doc[field]),
            ))
        .toList();
  }

Future<void> _fetchCharacterData(String characterId) async {
  DocumentSnapshot snapshot = await FirebaseFirestore.instance
      .collection('characters')
      .doc(characterId)
      .get();

  setState(() {
    characterData = snapshot.data() as Map<String, dynamic>?;
  });
}


  // Fetch Story Description from Firestore
  Future<void> _fetchStoryDescription(String storyId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('stories')
          .doc(storyId)
          .get();

      setState(() {
        storyDescription = snapshot['plot_description'] ??
            'No description available for this story.';
      });
    } catch (e) {
      setState(() {
        storyDescription = 'Failed to load story description: $e';
      });
    }
  }

  // Fetch World Description from Firestore
  Future<void> _fetchWorldDescription(String worldId) async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('worlds')
          .doc(worldId)
          .get();

      setState(() {
        worldDescription = snapshot['world_description'] ??
            'No description available for this world.';
      });
    } catch (e) {
      setState(() {
        worldDescription = 'Failed to load world description: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Character, Story, and World to Start',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown, // TRPG-like color
                ),
              ),

              const SizedBox(height: 20),

              // Character Dropdown
              FutureBuilder<List<DropdownMenuItem<String>>>(
                future: _buildDropdownItems('characters', 'name'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No characters available');
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedCharacter,
                    hint: const Text("Select a Character"),
                    items: snapshot.data,
                    onChanged: (value) {
                      setState(() {
                        selectedCharacter = value;
                        _fetchCharacterData(value!); // Fetch character data
                      });
                    },
                  );
                },
              ),

              // Display character data
              if (characterData != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      border: Border.all(color: Colors.grey, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Character Avatar
                        if (characterData!['avatar'] != null)
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: Colors.grey, width: 2.0),
                            ),
                            child: SvgPicture.string(
                              characterData![
                                  'avatar'], // Display the avatar SVG string
                              fit: BoxFit.cover,
                            ),
                          )
                        else
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors
                                  .grey[200], // Default background if no avatar
                            ),
                            child: const Icon(Icons.person, size: 40),
                          ),

                        const SizedBox(width: 16),
                        // Character Information
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                characterData!['name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Race: ${characterData!['race']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Class: ${characterData!['class']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                "Skill: ${characterData!['skill']}",
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 32),

              // Story Dropdown
              FutureBuilder<List<DropdownMenuItem<String>>>(
                future: _buildDropdownItems('stories', 'script_name'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No stories available');
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedStory,
                    hint: const Text("Select a Story"),
                    items: snapshot.data,
                    onChanged: (value) {
                      setState(() {
                        selectedStory = value;
                        _fetchStoryDescription(value!); // Use sample description
                      });
                    },
                  );
                },
              ),

              // Story Description (Styled TRPG Theme)
              if (storyDescription != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade300.withOpacity(0.8),
                      border: Border.all(color: Colors.brown, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      storyDescription!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),


              const SizedBox(height: 32),

              // World Dropdown
              FutureBuilder<List<DropdownMenuItem<String>>>(
                future: _buildDropdownItems('worlds', 'world_name'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No worlds available');
                  }

                  return DropdownButtonFormField<String>(
                    value: selectedWorld,
                    hint: const Text("Select a World"),
                    items: snapshot.data,
                    onChanged: (value) {
                      setState(() {
                        selectedWorld = value;
                        _fetchWorldDescription(
                            value!); // Use sample description
                      });
                    },
                  );
                },
              ),

              // World Description (Styled)
              if (worldDescription != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.brown.shade300.withOpacity(0.8),
                      border: Border.all(color: Colors.brown, width: 2.0),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      worldDescription!,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 32),

              // Start Game Button
// Inside the ElevatedButton onPressed in GameSetupPage
ElevatedButton(
  onPressed: (selectedCharacter != null && selectedStory != null && selectedWorld != null)
      ? () {
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => GameChatRoom(
      characterId: selectedCharacter!,
      storyId: selectedStory!,
      worldId: selectedWorld!,
      characterAvatar: characterData!['avatar'],  // Pass the avatar
    ),
  ),
);

        }
      : null,
  child: const Text('Start Game'),
),

            ],
          ),
        ),
      ),
    );
  }
}
