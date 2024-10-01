import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:mygamemaster/model/combat_model.dart';
import 'package:mygamemaster/pages/combat.dart';
import 'package:mygamemaster/pages/roll_dice.dart';
import 'package:mygamemaster/pages/puzzle.dart';
import 'package:http/http.dart' as http;
import 'dart:math';

class ChatRoom extends StatefulWidget {
  const ChatRoom({super.key});

  @override
  _ChatRoomState createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];

  bool _gameStarted = false; 
  int _currentState = 0;
  int _combatResult = 0;
  bool _hasNote = false;  
  bool _puzzleSolved = false;
  bool _doorBreak = false;
  bool _bossCombat = false;
  bool _getBook = false;
  bool _getNecklace = false;
  bool _trueEnding = false;
  bool _gameOver = false;
  bool _killByCultists = false;
  bool _killByBoss = false;
  bool _combatPending = false; 

  @override
  void initState() {
    super.initState();
  }

  void _checkAndResetGame() {
  if (_trueEnding || _gameOver) {
    setState(() {
      _gameStarted = false;
      _currentState = 0;
      _combatResult = 0;
      _hasNote = false;
      _puzzleSolved = false;
      _doorBreak = false;
      _bossCombat = false;
      _getBook = false;
      _getNecklace = false;
      _trueEnding = false;
      _gameOver = false;
      _killByCultists = false;
      _killByBoss = false;
      _combatPending = false;

      _messages.add({
        'role': 'system',
        'message': 'Game has ended. All game variables have been reset!',
      });
    });

    // Optionally auto-save the reset state
    _autoSaveGame();
  }
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
    String apiKey = remoteConfig.getString('api_key_preset_chatbot');
    return apiKey;
  } catch (e) {
    print("Failed to fetch API key: $e");
    return ''; // Return empty string or handle the error appropriately
  }
}

  Future<void> _sendMessage(String text) async {
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'message': text});
      _controller.clear();
    });

    _scrollToBottom();

  try {
    // Fetch the API key before making the request
    String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      _messages.add({'role': 'system', 'message': 'Error: API key is missing.'});
      return;
    }

    print("Sending user message: $text with current_state: $_currentState");

    final response = await http.post(
      Uri.parse(apiKey),  // Use the API key (URL) fetched from Firebase Remote Config
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'message': text,
        'current_state': _currentState, 
        'combat_result': _combatResult,
        'in_combat': _combatPending,
        'puzzle_solved': _puzzleSolved,
        'door_breaking': _doorBreak,
        'in_boss_combat': _bossCombat,
        'get_book': _getBook,
        'get_necklace': _getNecklace,
        'true_ending': _trueEnding,
        'killed_by_cultists': _killByCultists,
        'killed_by_boss': _killByBoss,
      }),
    );

      print("Received response with status code: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print("Response data: $data");

        String systemResponse = data['response'] ?? 'No response from AI';
        int newState = data['current_state']; // Get the updated state from backend
        bool combatTrigger = data['in_combat'] ?? false; // Check for combat flag
        bool hasNote = data['have_note'] ?? false; // Get the have_note flag from the response
        bool puzzleSolved = data['puzzle_solved'] ?? false;
        bool doorBreaking = data['door_breaking'] ?? false;
        bool bossCombat = data['in_boss_combat'] ?? false;
        bool getBook = data['get_book'] ?? false;  // Get get_book from backend
        bool getNecklace = data['get_necklace'] ?? false;  // Get get_necklace from backend
        bool trueEnding = data['true_ending'] ?? false;  // Get true_ending from backend
        bool gameOver = data['game_over'] ?? false;
        bool killByBoss = data['killed_by_boss'] ?? false;
        bool killByCultists = data['killed_by_cultists'] ?? false;

        print("Boss combat trigger received: $bossCombat");  // Debug print

        setState(() {
          _messages.add({'role': 'system', 'message': systemResponse});
          _currentState = newState; // Update the state in the frontend
          _combatPending = combatTrigger; // Set combat pending if triggered
          _hasNote = hasNote; // Update the hasNote flag
          _puzzleSolved = puzzleSolved;
          _doorBreak = doorBreaking;
          _bossCombat = bossCombat;
          _getBook = getBook;  // Update get_book state
          _getNecklace = getNecklace;  // Update get_necklace state
          _trueEnding = trueEnding;  // Update true_ending state
          _gameOver = gameOver; // Update game over state
          _killByBoss = killByBoss;
          _killByCultists = killByCultists;
        });


          
      _checkAndResetGame();

      } else {
        print("API error occurred: ${response.body}");
        _handleError();
      }

      _scrollToBottom();
    } catch (e) {
      print("Exception occurred during API call: $e");
      _handleError();
    }
  }

void _showPuzzle() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Solve the Puzzle'),
        content: SizedBox(
          height: 350,  
          width: 350,   
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxHeight: 300, 
              ),
              child: TilePuzzle(
                key: UniqueKey(), // Add a unique key to reset the puzzle state
                onPuzzleSolved: (bool solved) {
                  _notifyPuzzleSolved(solved);
                  Navigator.of(context).pop(); 
                },
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog without solving
            },
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // Trigger the reset by rebuilding the puzzle with a new key
              Navigator.of(context).pop(); // Close the dialog
              _showPuzzle(); // Reopen the puzzle to reset
            },
            child: const Text('Reset Puzzle'),
          ),
        ],
      );
    },
  );
}


Future<void> _notifyPuzzleSolved(bool solved) async {
  try {
    print("Notifying server the puzzle is solved");

    // Fetch the API key from Firebase Remote Config
    String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

    final response = await http.post(
      Uri.parse(apiKey),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'message': 'search',
        'current_state': _currentState, // Send current state to the backend
        'combat_result': _combatResult, // Send combat result
        'in_combat': _combatPending,  // Send in_combat state
        'puzzle_solved': _puzzleSolved, // Send puzzle_solved state
        'door_breaking': _doorBreak,  // Send door_breaking state
        'in_boss_combat': _bossCombat,  // Send in_boss_combat state
        'get_book': _getBook,  // Send get_book state
        'get_necklace': _getNecklace,  // Send get_necklace state
        'true_ending': _trueEnding,  // Send true_ending state
        'killed_by_cultists': _killByCultists,
        'killed_by_boss': _killByBoss
      }),
    );

    if (response.statusCode == 200) {
      print("Puzzle solved message sent successfully.");
      final data = json.decode(response.body);
      String serverResponse = data['response'];
      int newState = data['current_state'];
      bool combatTrigger = data['in_combat'] ?? false; // Check for combat flag
      bool hasNote = data['have_note'] ?? false; // Get the have_note flag from the response
      bool puzzleSolved = data['puzzle_solved'] ?? false;
      bool doorBreaking = data['door_breaking'] ?? false;
      bool bossCombat = data['in_boss_combat'] ?? false;
      bool getBook = data['get_book'] ?? false;  // Get get_book from backend
      bool getNecklace = data['get_necklace'] ?? false;  // Get get_necklace from backend
      bool trueEnding = data['true_ending'] ?? false;  // Get true_ending from backend
      bool gameOver = data['game_over'] ?? false;
      bool killByBoss = data['killed_by_boss'] ?? false;
      bool killByCultists = data['killed_by_cultists'] ?? false;

      setState(() {
        _currentState = newState; // Update the current state from the server's response
        _messages.add({
          'role': 'system',
          'message': serverResponse // Add the server's response to the chat messages
        });
        _combatPending = combatTrigger; // Set combat pending if triggered
        _hasNote = hasNote; // Update the hasNote flag
        _puzzleSolved = puzzleSolved;
        _doorBreak = doorBreaking;
        _bossCombat = bossCombat;
        _getBook = getBook;  // Update get_book state
        _getNecklace = getNecklace;  // Update get_necklace state
        _trueEnding = trueEnding;  // Update true_ending state
        _gameOver = gameOver; // Update game over state
        _killByBoss = killByBoss;
        _killByCultists = killByCultists;
      });
      _scrollToBottom(); // Ensure the new message is visible
    } else {
      print("Failed to notify puzzle solved: ${response.body}");
      _handleError();
    }
  } catch (e) {
    print("Exception occurred during API call: $e");
    _handleError();
  }
}



  Future<void> _startGame() async {
    setState(() {
      _gameStarted = true; // Update the state to indicate the game has started
    });
    await _sendMessage('start_game');
  }

  Future<void> _showDoorBreaking(BuildContext context) async {
    // Define a player character
    Character player = Character(
      name: "Hero",
      health: 100,
      attack: 20,
      defense: 5,
      physicalShield: 50,
      magicShield: 40,
      image: 'assets/images/player.jpg'
    );
    // Define the door as an enemy with specific attributes
    Enemy door = Enemy(
      name: "Sturdy Door",
      health: 500,
      attack: 0,
      defense: 0,
      physicalShield: 0,
      magicShield: 0,
      image: 'assets/images/door.png'
    );

    // Navigate to the CombatScreen and await the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(player: player, enemy: door), 
      ),
    );

    // Handle the result of the door breaking: true for success, false for fail
    if (result != null) {
      setState(() {
        _combatResult = result; // Store the combat result from CombatScreen
      });

      // Send combat result to backend, adapt if needed to handle door-breaking scenario
      await _sendDoorBreakingResult(_combatResult);
    }

    _scrollToBottom();
  }

Future<void> _sendDoorBreakingResult(int doorResult) async {
  try {
    print("Sending door breaking result: ${doorResult == 1 ? 'success' : 'failure'}");

        String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

    final response = await http.post(
      Uri.parse(apiKey),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'combat_result': doorResult,
        'message': "combat",
        'current_state': _currentState, // Send current state to the backend
        'in_combat': _combatPending,  // Send in_combat state
        'puzzle_solved': _puzzleSolved, // Send puzzle_solved state
        'door_breaking': _doorBreak,  // Send door_breaking state
        'in_boss_combat': _bossCombat,  // Send in_boss_combat state
        'get_book': _getBook,  // Send get_book state
        'get_necklace': _getNecklace,  // Send get_necklace state
        'true_ending': _trueEnding,  // Send true_ending state
        'killed_by_cultists': _killByCultists,
        'killed_by_boss': _killByBoss
      }),
    );

    if (response.statusCode == 200) {
      print("Door breaking result and message sent successfully.");
      final data = json.decode(response.body);

      // Extract the relevant data from the response
      String systemResponse = data['response'] ?? 'No response from AI';
      int newState = data['current_state'] ?? _currentState;
      bool doorBreakingTrigger = data['door_breaking'] ?? false;
      bool getBook = data['get_book'] ?? false;
      bool getNecklace = data['get_necklace'] ?? false;
      bool trueEnding = data['true_ending'] ?? false;
      bool puzzleSolved = data['puzzle_solved'] ?? false;
      bool bossCombat = data['in_boss_combat'] ?? false;
      bool gameOver = data['game_over'] ?? false;
      bool killByBoss = data['killed_by_boss'] ?? false;
      bool killByCultists = data['killed_by_cultists'] ?? false;

      // Update the state in Flutter
      setState(() {
        _messages.add({'role': 'system', 'message': systemResponse});
        _currentState = newState; // Update the current state
        _doorBreak = doorBreakingTrigger; // Update door-breaking state
        _getBook = getBook; // Update book state
        _getNecklace = getNecklace; // Update necklace state
        _trueEnding = trueEnding; // Update true ending state
        _puzzleSolved = puzzleSolved; // Update puzzle solved state
        _bossCombat = bossCombat; // Update boss combat state
        _gameOver = gameOver; // Update game over state
        _killByBoss = killByBoss;
        _killByCultists = killByCultists;
      });

      _checkAndResetGame();

      _scrollToBottom();
    } else {
      print("Failed to send door breaking result: ${response.body}");
    }
  } catch (e) {
    print("Error sending door breaking result: $e");
  }
}

  Future<void> _showCombat(BuildContext context) async {
    // Define a player character
    Character player = Character(
      name: "Hero",
      health: 100,
      attack: 20,
      defense: 5,
      physicalShield: 50,
      magicShield: 40,
      image: 'assets/images/player.jpg'
    );

    // Define an enemy
    Enemy enemy = Enemy(
      name: "Cultist",
      health: 110,
      attack: 15,
      defense: 3,
      physicalShield: 50,
      magicShield: 60,
      image: 'assets/images/enemy.jpg'
    );

    // Navigate to the CombatScreen and await the result
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CombatScreen(player: player, enemy: enemy),
      ),
    );

    // Handle the result of the combat: true for win, false for loss
    if (result != null) {
      setState(() {
        _combatResult = result;  // Store the combat result from CombatScreen
      });

      // Send combat result to backend
      await _sendCombatResult(_combatResult);
    }

    _scrollToBottom();
  }

  Future<void> _sendCombatResult(int combatResult) async {
    try {
      print("Sending combat result: ${combatResult == 1 ? 'win' : 'lose'}");

    String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

      final response = await http.post(
        Uri.parse(apiKey),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'combat_result': combatResult,
          'message': "combat",
          'current_state': _currentState, // Send current state to the backend
          'in_combat': _combatPending,  // Send in_combat state
          'puzzle_solved': _puzzleSolved, // Send puzzle_solved state
          'door_breaking': _doorBreak,  // Send door_breaking state
          'in_boss_combat': _bossCombat,  // Send in_boss_combat state
          'get_book': _getBook,  // Send get_book state
          'get_necklace': _getNecklace,  // Send get_necklace state
          'true_ending': _trueEnding,  // Send true_ending state
          'killed_by_cultists': _killByCultists,
          'killed_by_boss': _killByBoss
        }),
      );

      if (response.statusCode == 200) {
        print("Combat result and message sent successfully.");
        final data = json.decode(response.body);

        // Extract data from the Flask response
        String systemResponse = data['response'] ?? 'No response from AI';
        int newState = data['current_state'] ?? _currentState;
        bool combatTrigger = data['in_combat'] ?? false;
        bool hasNote = data['have_note'] ?? false;
        bool puzzleSolved = data['puzzle_solved'] ?? false;
        bool doorBreaking = data['door_breaking'] ?? false;
        bool bossCombat = data['in_boss_combat'] ?? false;
        bool getBook = data['get_book'] ?? false;
        bool getNecklace = data['get_necklace'] ?? false;
        bool trueEnding = data['true_ending'] ?? false;
        bool gameOver = data['game_over'] ?? false;
        bool killByBoss = data['killed_by_boss'] ?? false;
        bool killByCultists = data['killed_by_cultists'] ?? false;

        setState(() {
          _messages.add({'role': 'system', 'message': systemResponse});
          _currentState = newState;
          _combatPending = combatTrigger;
          _hasNote = hasNote; // Update note state
          _puzzleSolved = puzzleSolved; // Update puzzle solved state
          _doorBreak = doorBreaking; // Update door-breaking state
          _bossCombat = bossCombat; // Update boss combat state
          _getBook = getBook; // Update if book is obtained
          _getNecklace = getNecklace; // Update if necklace is obtained
          _trueEnding = trueEnding; // Update true ending state
          _gameOver = gameOver; // Update game over state
          _killByBoss = killByBoss;
          _killByCultists = killByCultists;
        });

        _checkAndResetGame();

        _scrollToBottom();
      } else {
        print("Failed to send combat result: ${response.body}");
      }
    } catch (e) {
      print("Error sending combat result: $e");
    }
  }

Future<void> _showBossCombat(BuildContext context) async {
  // Define a player character
  Character player = Character(
    name: "Hero",
    health: 100,
    attack: 20,
    defense: 5,
    physicalShield: 50,
    magicShield: 40,
    image: 'assets/images/player.jpg', 
  );

  Enemy enemy = Enemy(
    name: "Dweller from the Depth",
    health: 300,
    attack: 20,
    defense: 5,
    physicalShield: 0,
    magicShield: 0,
    image: 'assets/images/boss.png', 
  );

  // Navigate to the CombatScreen and await the result
  final result = await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => CombatScreen(player: player, enemy: enemy),
    ),
  );

  // Handle the result of the combat: true for win, false for loss
  if (result != null) {
    setState(() {
      _combatResult = result;  // Store the combat result from CombatScreen
    });

    // Send combat result to backend
    await _sendBossCombatResult(_combatResult);
  }

  _scrollToBottom();
}

  Future<void> _sendBossCombatResult(int combatResult) async {
  try {
    print("Sending combat result: ${combatResult == 1 ? 'win' : 'lose'}");

    String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

    final response = await http.post(
      Uri.parse(apiKey),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'combat_result': combatResult,
        'message': "combat",
        'current_state': _currentState, // Send current state to the backend
        'in_combat': _combatPending,  // Send in_combat state
        'puzzle_solved': _puzzleSolved, // Send puzzle_solved state
        'door_breaking': _doorBreak,  // Send door_breaking state
        'in_boss_combat': _bossCombat,  // Send in_boss_combat state
        'get_book': _getBook,  // Send get_book state
        'get_necklace': _getNecklace,  // Send get_necklace state
        'true_ending': _trueEnding,  // Send true_ending state
        'killed_by_cultists': _killByCultists,
        'killed_by_boss': _killByBoss
      }),
    );

    if (response.statusCode == 200) {
      print("Combat result and message sent successfully.");
      final data = json.decode(response.body);

      // Extract the relevant data from the response
      String systemResponse = data['response'] ?? 'No response from AI';
      int newState = data['current_state'] ?? _currentState;
      bool bossCombat = data['in_boss_combat'] ?? false;
      bool getBook = data['get_book'] ?? false;
      bool getNecklace = data['get_necklace'] ?? false;
      bool trueEnding = data['true_ending'] ?? false;
      bool puzzleSolved = data['puzzle_solved'] ?? false;
      bool gameOver = data['game_over'] ?? false;
      bool killByBoss = data['killed_by_boss'] ?? false;
      bool killByCultists = data['killed_by_cultists'] ?? false;

      // Update the state in Flutter
      setState(() {
        _messages.add({'role': 'system', 'message': systemResponse});
        _currentState = newState; // Update the current state
        _bossCombat = bossCombat; // Update boss combat state
        _getBook = getBook; // Update book state
        _getNecklace = getNecklace; // Update necklace state
        _trueEnding = trueEnding; // Update true ending state
        _puzzleSolved = puzzleSolved; // Update puzzle solved state
        _gameOver = gameOver; // Update game over state
        _killByBoss = killByBoss;
        _killByCultists = killByCultists;
      });

      _checkAndResetGame();

      _scrollToBottom();
    } else {
      print("Failed to send combat result: ${response.body}");
    }
  } catch (e) {
    print("Error sending combat result: $e");
  }
}

  // Handles errors by adding an error message to the chat
  void _handleError() {
    setState(() {
      _messages.add({
        'role': 'system',
        'message': 'Error: Could not process your message.'
      });
    });

    _scrollToBottom();
  }

  // Scroll to the bottom of the ListView
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Function to show the rolling dice widget
  Future<void> _showDiceRoll(BuildContext context) async {
    // Show the RollingDiceWidget and wait for the result
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        return const RollingDiceWidget(); 
      },
    );

    // Once the result is received, add it to the chat
    if (result != null) {
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'The dice roll result is: $result',
        });
      });

      _scrollToBottom();
    }
  }

  void _showSaveGameDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot saveSlots = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_saves')
          .get();

      List<Map<String, dynamic>> slots = saveSlots.docs
          .map((doc) => {'slotName': doc.id, 'data': doc.data()})
          .toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Save Game'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (slots.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('Slot ${slots[index]['slotName']}'),
                            subtitle: Text(
                                'Last saved: ${slots[index]['data']['timestamp']?.toDate() ?? 'No time'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _removeGameSlot(slots[index]
                                    ['slotName']); 
                                Navigator.pop(
                                    context); 
                                _showSaveGameDialog(
                                    context); 
                              },
                            ),
                            onTap: () {
                              _saveGame(slots[index]['slotName']); 
                              Navigator.pop(context); 
                            },
                          );
                        },
                      ),
                    ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.add),
                    title: const Text('Create New Save'),
                    onTap: () {
                      _saveGame(DateTime.now()
                          .millisecondsSinceEpoch
                          .toString()); 
                      Navigator.pop(context); 
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Error: You are not logged in.',
        });
      });
    }
  }

  void _saveGame(String slotName) async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      Map<String, dynamic> gameData = {
        'slotName': slotName,
        'timestamp': FieldValue.serverTimestamp(),
        'current_state': _currentState,
        'combat_result': _combatResult,
        'in_combat': _combatPending,
        'puzzle_solved': _puzzleSolved,
        'door_breaking': _doorBreak,
        'in_boss_combat': _bossCombat,
        'get_book': _getBook,  
        'get_necklace': _getNecklace,  
        'true_ending': _trueEnding,  
        'game_over': _gameOver,
        'killed_by_cultists': _killByCultists,
        'killed_by_boss': _killByBoss,
        'latest_response': _messages.isNotEmpty ? _messages.last['message'] : 'No response', 
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_saves')
          .doc(slotName)
          .set(gameData);

      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Game saved successfully in slot $slotName!',
        });
      });
    } catch (e) {
      print("Error saving game: $e");
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Error: Unable to save the game.',
        });
      });
    }
  } else {
    setState(() {
      _messages.add({
        'role': 'system',
        'message': 'Error: You are not logged in.',
      });
    });
  }

  _scrollToBottom();
}

void _autoSaveGame() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      // Generate a random number
      int randomNumber = Random().nextInt(100000); 
      String slotName = "auto_save_$randomNumber"; 

      Map<String, dynamic> gameData = {
        'slotName': slotName,
        'timestamp': FieldValue.serverTimestamp(),
        'current_state': _currentState,
        'combat_result': _combatResult,
        'in_combat': _combatPending,
        'puzzle_solved': _puzzleSolved,
        'door_breaking': _doorBreak,
        'in_boss_combat': _bossCombat,
        'get_book': _getBook, 
        'get_necklace': _getNecklace,  
        'true_ending': _trueEnding,  
        'game_over': _gameOver,
        'killed_by_cultists': _killByCultists,
        'killed_by_boss': _killByBoss,
        'latest_response': _messages.isNotEmpty ? _messages.last['message'] : 'No response', 
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_saves')
          .doc(slotName)
          .set(gameData);

      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Game auto-saved successfully in slot $slotName!',
        });
      });
    } catch (e) {
      print("Error during auto-save: $e");
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Error: Unable to auto-save the game.',
        });
      });
    }
  } else {
    setState(() {
      _messages.add({
        'role': 'system',
        'message': 'Error: You are not logged in for auto-saving.',
      });
    });
  }

  _scrollToBottom();
}

  void _showLoadGameDialog(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      QuerySnapshot saveSlots = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_saves')
          .get();

      List<Map<String, dynamic>> slots = saveSlots.docs
          .map((doc) => {'slotName': doc.id, 'data': doc.data()})
          .toList();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Load Game'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (slots.isNotEmpty)
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: slots.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            title: Text('Slot ${slots[index]['slotName']}'),
                            subtitle: Text(
                                'Last saved: ${slots[index]['data']['timestamp']?.toDate() ?? 'No time'}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                _removeGameSlot(slots[index]
                                    ['slotName']); 
                                Navigator.pop(
                                    context); 
                                _showLoadGameDialog(
                                    context); 
                              },
                            ),
                            onTap: () {
                              _loadGame(slots[index]
                                  ['slotName']); 
                              Navigator.pop(context); 
                            },
                          );
                        },
                      ),
                    )
                  else
                    const Text('No saved games available.'),
                ],
              ),
            ),
          );
        },
      );
    } else {
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Error: You are not logged in.',
        });
      });
    }
  }

  void _loadGame(String slotName) async {
  final user = FirebaseAuth.instance.currentUser;
  _gameStarted = true;

  if (user != null) {
    try {
      // Fetch the saved game data from Firebase
      DocumentSnapshot gameSave = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('game_saves')
          .doc(slotName)
          .get();

          String apiKey = await fetchApiKey();

    if (apiKey.isEmpty) {
      print("API key is missing.");
      _handleError();
      return;
    }

      if (gameSave.exists) {
        Map<String, dynamic> gameData =
            gameSave.data() as Map<String, dynamic>;

        // Send the saved state to the Flask backend
        final response = await http.post(
          Uri.parse(apiKey), 
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'message': 'load_game',
            'current_state': gameData['current_state'],
            'combat_result': gameData['combat_result'],
            'in_combat': gameData['in_combat'],
            'puzzle_solved': gameData['puzzle_solved'],
            'door_breaking': gameData['door_breaking'],
            'in_boss_combat': gameData['in_boss_combat'],
            'get_book': gameData['get_book'],  
            'get_necklace': gameData['get_necklace'],  
            'true_ending': gameData['true_ending'], 
            'game_over': gameData['game_over'],
            'killed_by_cultists': gameData['killed_by_cultists'],
            'killed_by_boss': gameData['killed_by_boss']
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          String systemResponse = data['response'];
          int newState = data['current_state'];
          bool combatTrigger = data['in_combat'] ?? false;
          bool hasNote = data['have_note'] ?? false;
          bool puzzleSolved = data['puzzle_solved'] ?? false;
          bool doorBreaking = data['door_breaking'] ?? false;
          bool bossCombat = data['in_boss_combat'] ?? false;
          bool getBook = data['get_book'] ?? false;
          bool getNecklace = data['get_necklace'] ?? false;
          bool trueEnding = data['true_ending'] ?? false;
          bool gameOver = data['game_over'] ?? false;
          bool killByBoss = data['killed_by_boss'] ?? false;
          bool killByCultists = data['killed_by_cultists'] ?? false;

          // Get the latest response from the saved data
          String latestResponse = gameData['latest_response'] ?? 'No saved response';

          setState(() {
            _messages.add({
              'role': 'system',
              'message': 'Game loaded successfully from slot $slotName. Current state: $newState',
            });

            _messages.add({
              'role': 'system',
              'message': latestResponse, // Show the saved response
            });

            // Update the game state
            _currentState = newState;
            _combatPending = combatTrigger;
            _hasNote = hasNote;
            _puzzleSolved = puzzleSolved;
            _doorBreak = doorBreaking;
            _bossCombat = bossCombat;
            _getBook = getBook;  // Update get_book state
            _getNecklace = getNecklace;  // Update get_necklace state
            _trueEnding = trueEnding;  // Update true_ending state
            _gameOver = gameOver;
            _killByBoss = killByBoss;
            _killByCultists = killByCultists;
          });
        } else {
          setState(() {
            _messages.add({
              'role': 'system',
              'message': 'Error: Failed to load the game from backend.',
            });
          });
        }
      } else {
        setState(() {
          _messages.add({
            'role': 'system',
            'message': 'No saved game found in slot $slotName.',
          });
        });
      }
    } catch (e) {
      print("Error loading game: $e");
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Error: Unable to load the game.',
        });
      });
    }
  } else {
    setState(() {
      _messages.add({
        'role': 'system',
        'message': 'Error: You are not logged in.',
      });
    });
  }

  _scrollToBottom();
}


  Future<void> _removeGameSlot(String slotName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('game_saves')
            .doc(slotName)
            .delete();

        setState(() {
          _messages.add({
            'role': 'system',
            'message': 'Game slot $slotName deleted successfully!',
          });
        });
      } catch (e) {
        print("Error deleting game slot: $e");
        setState(() {
          _messages.add({
            'role': 'system',
            'message': 'Error: Unable to delete the game slot.',
          });
        });
      }
    } else {
      setState(() {
        _messages.add({
          'role': 'system',
          'message': 'Error: You are not logged in.',
        });
      });
    }
  }

  // Mock function to simulate exporting the game data
  void _exportGame() {
    print("Game Exported");
    // Add any logic for exporting the game data here.
  }

@override
Widget build(BuildContext context) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    backgroundColor: isDarkMode
        ? Colors.black87
        : const Color(0xFFF3E5AB), // Parchment-like background for light mode
    appBar: AppBar(
      backgroundColor: isDarkMode ? Colors.black54 : const Color(0xFF6B4226),
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Whispers of the Abandoned', style: TextStyle(fontSize: 18)),
          Text('Ai Game Master', style: TextStyle(fontSize: 14)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            _showBottomSheet(
                context); // Show the bottom sheet when "+" is clicked
          },
        ),
      ],
    ),
    body: Column(
      children: [
        if (!_gameStarted) // Conditionally render the Start Game button
          ElevatedButton(
            onPressed: _startGame,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text("Start Game"),
          ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final message = _messages[index];
              return Align(
                alignment: message['role'] == 'user'
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  constraints: const BoxConstraints(maxWidth: 300),
                  decoration: BoxDecoration(
                    color: message['role'] == 'user'
                        ? (isDarkMode ? Colors.grey[800] : Colors.brown[100])
                        : (isDarkMode ? Colors.blueGrey[900] : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message['role'] == 'user'
                          ? (isDarkMode ? Colors.grey : Colors.brown[300]!)
                          : (isDarkMode
                              ? Colors.blueGrey[700]!
                              : Colors.brown[400]!),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      color: message['role'] == 'user'
                          ? (isDarkMode ? Colors.white : Colors.brown[800])
                          : (isDarkMode ? Colors.white : Colors.black87),
                      fontFamily:
                          'MedievalSharp', // Custom font for TRPG effect
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Show the "Start Combat" button when combat is pending
        if (_combatPending)
          ElevatedButton(
            onPressed: () {
              _showCombat(context); // Manually trigger combat
              setState(() {
                _combatPending = false; // Reset combat flag after starting combat
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Start Combat'),
          ),
        if (_bossCombat)
          ElevatedButton(
            onPressed: () {
              _showBossCombat(context); // Manually trigger combat
              setState(() {
                _bossCombat = false; // Reset combat flag after starting combat
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Start Combat'),
          ),
        if (_doorBreak)
          ElevatedButton(
            onPressed: () {
              _showDoorBreaking(context); // Manually trigger combat
              setState(() {
                _doorBreak = false; // Reset combat flag after starting combat
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Break the Door'),
          ),
        if (_hasNote) // Show "Access Puzzle" button when _hasNote is true
          ElevatedButton(
            onPressed: _showPuzzle,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Solve Puzzle'),
          ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(
                          color: isDarkMode ? Colors.white : Colors.black87),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor:
                            isDarkMode ? Colors.grey[850] : Colors.white,
                        hintText: 'What would you do?',
                        hintStyle: TextStyle(
                            color: isDarkMode
                                ? Colors.grey[400]
                                : Colors.grey[700]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          borderSide: BorderSide(
                            color: isDarkMode
                                ? Colors.blueGrey[300]!
                                : Colors.brown[400]!,
                          ),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send,
                        color: isDarkMode ? Colors.white : Colors.brown[800]),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Wrap(
                spacing: 5,
                runSpacing: 5,
                children: [
                  _buildChatActionButton('Combat', Colors.red),
                  _buildChatActionButton('Move', Colors.blue),
                  _buildChatActionButton('Search', Colors.green),
                  _buildChatActionButton('Hide', Colors.purple),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}


  // Function to create chat action buttons
  Widget _buildChatActionButton(String label, Color color) {
    return ElevatedButton(
      onPressed: () {
        _sendMessage(label); // Auto send the label to the chatroom
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: Text(label, style: const TextStyle(fontSize: 15)),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 200,
          color: Theme.of(context).canvasColor, // Use theme-aware color
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomSheetButton(
                    icon: Icons.save,
                    label: 'Save Game',
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      _showSaveGameDialog(context); // Show save dialog
                    },
                  ),
                  _buildBottomSheetButton(
                    icon: Icons.upload_file,
                    label: 'Load Game',
                    onPressed: () {
                      Navigator.pop(context); // Close bottom sheet
                      _showLoadGameDialog(context); // Show load dialog
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close the Bottom Sheet
                },
                child: const Text('Resume'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper function to build the buttons for the bottom sheet
  Widget _buildBottomSheetButton(
      {required IconData icon,
      required String label,
      required VoidCallback onPressed}) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon, size: 40),
          onPressed: onPressed,
          color:
              Theme.of(context).iconTheme.color, // Ensure it matches the theme
        ),
        Text(label,
            style:
                TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)),
      ],
    );
  }
}
