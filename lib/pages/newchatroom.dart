import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class GameChatRoom extends StatefulWidget {
  final String characterId;
  final String storyId;
  final String worldId;
  final String? characterAvatar; // Add avatar field

  const GameChatRoom({
    super.key,
    required this.characterId,
    required this.storyId,
    required this.worldId,
    this.characterAvatar, // Initialize avatar field
  });

  @override
  _GameChatRoomState createState() => _GameChatRoomState();
}


class _GameChatRoomState extends State<GameChatRoom> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];
  bool _gameStarted = false;
  bool _isLoading = true;
  int _currentScenario = 1;

  String? characterData;
  String? storyData;
  String? worldData;

  @override
  void initState() {
    super.initState();
    _fetchGameData();
  }

  // Fetch data from Firebase
  Future<void> _fetchGameData() async {
  try {
    // Fetch character, story, and world data from Firestore
    DocumentSnapshot characterSnapshot = await FirebaseFirestore.instance
        .collection('characters')
        .doc(widget.characterId)
        .get();
    DocumentSnapshot storySnapshot = await FirebaseFirestore.instance
        .collection('stories')
        .doc(widget.storyId)
        .get();
    DocumentSnapshot worldSnapshot = await FirebaseFirestore.instance
        .collection('worlds')
        .doc(widget.worldId)
        .get();

    if (characterSnapshot.exists &&
        storySnapshot.exists &&
        worldSnapshot.exists) {
      setState(() {
        // Explicitly cast the data from Firestore to Map<String, dynamic>
        characterData = json.encode(
            _processFirestoreData(characterSnapshot.data() as Map<String, dynamic>?));
        storyData = json.encode(
            _processFirestoreData(storySnapshot.data() as Map<String, dynamic>?));
        worldData = json.encode(
            _processFirestoreData(worldSnapshot.data() as Map<String, dynamic>?));
        _isLoading = false;
      });
    }
  } catch (e) {
    print("Error fetching game data: $e");
  }
}


// Helper function to convert Firestore data and handle Timestamps
Map<String, dynamic> _processFirestoreData(Map<String, dynamic>? data) {
  if (data == null) return {};

  data.forEach((key, value) {
    if (value is Timestamp) {
      data[key] = value.toDate().toIso8601String(); // Convert Timestamp to ISO String
    }
  });

  return data;
}

Future<String> fetchApiKey() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  try {
    // Set the config settings for fetch intervals and timeouts
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(seconds: 0), // Fetch immediately for dev mode
      ),
    );

    // Fetch and activate the remote config
    await remoteConfig.fetchAndActivate();

    // Retrieve the API key from remote config
    String apiKey = remoteConfig.getString('api_key_random_chatbot');
    return apiKey;
  } catch (e) {
    print("Failed to fetch API key: $e");
    return ''; // Return empty string or handle the error appropriately
  }
}

// Send initial core objective to Flask API
Future<void> _sendCoreObjective() async {
  if (storyData == null) return;

  setState(() {
    _messages.add({
      'role': 'system',
      'message': 'Fetching scenario from server...'
    });
  });

    // Fetch the API key from Firebase Remote Config
    String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

  try {
    final response = await http.post(
      Uri.parse(apiKey),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': 'start_game',
        'character': characterData,
        'story': storyData,
        'world': worldData,
        'game_started': _gameStarted ?? false,
        'scenario': _currentScenario ?? 1,
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String systemResponse = data['response'] ?? 'No response from AI';
      String scenarioDescription = data['description'] ?? 'No scenario description available';

      setState(() {
        _messages.add({'role': 'system', 'message': systemResponse});
        _messages.add({'role': 'system', 'message': scenarioDescription});

        // Extract game_state from the server's response
        final gameState = data['game_state'];
        _gameStarted = gameState['game_started'] ?? false;  // Update game_started
        _currentScenario = gameState['scenario'] ?? 1;  // Update scenario from game_state
        print("Game started: $_gameStarted, Scenario: $_currentScenario");
      });
    } else {
      _handleError();
    }

    _scrollToBottom();
  } catch (e) {
    print("API Error: $e");
    _handleError();
  }
}

// Send message to Flask API
Future<void> _sendMessage(String text) async {
  if (text.isEmpty || characterData == null || storyData == null || worldData == null) return;

  setState(() {
    _messages.add({'role': 'user', 'message': text});
    _controller.clear();
  });

  _scrollToBottom();

    // Fetch the API key from Firebase Remote Config
    String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

  try {
    final response = await http.post(
      Uri.parse(apiKey),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'message': text,
        'story': storyData,
        'game_started': _gameStarted ?? false,
        'scenario': _currentScenario ?? 1,  // Pass the scenario from the local state
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      String systemResponse = data['response'] ?? 'No response from AI';

      setState(() {
        _messages.add({'role': 'system', 'message': systemResponse});

        // Extract game_state from the server's response
        final gameState = data['game_state'];
        _gameStarted = gameState['game_started'] ?? _gameStarted;  // Update game_started from server
        _currentScenario = gameState['scenario'] ?? _currentScenario;  // Update scenario from server
        print("Updated state: Game started: $_gameStarted, Scenario: $_currentScenario");
      });
    } else {
      _handleError();
    }

    _scrollToBottom();
  } catch (e) {
    print("API Error: $e");
    _handleError();
  }
}

  // Scroll to bottom of the chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Handle errors in API requests
  void _handleError() {
    setState(() {
      _messages.add({
        'role': 'system',
        'message': 'Error: Could not process your message.'
      });
    });
    _scrollToBottom();
  }

@override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    appBar: AppBar(
      title: const Text('TRPG Game Master'),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              if (!_gameStarted)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _gameStarted = true;
                    });
                    _sendCoreObjective();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Start Game"),
                ),
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final bool isUserMessage = message['role'] == 'user';

                    return Row(
                      mainAxisAlignment: isUserMessage
                          ? MainAxisAlignment.end
                          : MainAxisAlignment.start,
                      children: [
                        // Removed the system message avatar display
                        
                        // The chat bubble
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            decoration: BoxDecoration(
                              color: isUserMessage
                                  ? (isDarkMode ? Colors.grey[800] : Colors.brown[100])
                                  : (isDarkMode ? Colors.blueGrey[900] : Colors.white),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              message['message'] ?? '',
                              style: TextStyle(
                                color: isUserMessage
                                    ? (isDarkMode ? Colors.white : Colors.brown[800])
                                    : (isDarkMode ? Colors.white : Colors.black87),
                              ),
                            ),
                          ),
                        ),

                        // Show avatar for user messages
                        if (isUserMessage && widget.characterAvatar != null) ...[
                          const SizedBox(width: 10),
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.transparent,
                            child: SvgPicture.string(
                              widget.characterAvatar!, // User's avatar (SVG string)
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[850] : Colors.white,
                          hintText: 'What would you do?',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () => _sendMessage(_controller.text),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton("Combat", Colors.red),
                  _buildActionButton("Move", Colors.blue),
                  _buildActionButton("Search", Colors.green),
                  _buildActionButton("Hide", Colors.purple),
                ],
              ),
            ],
          ),
  );
}


  // Create action buttons for user inputs
  Widget _buildActionButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () => _sendMessage(label.toLowerCase()),
      style: ElevatedButton.styleFrom(backgroundColor: color),
      child: Text(label),
    );
  }
}
