import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  _ReportPageState createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String? selectedReportType;
  List<String> reportTypes = [
    'Game Result Report',
    'Story Creation Report',
    'World Creation Report',
    'Feedback Report'
  ];

  // Placeholder for the report data
  Widget reportContent = Container();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Generate Report'),
        actions: [
          if (selectedReportType != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () {
                _exportReportAsPDF(selectedReportType!);
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: selectedReportType,
              hint: const Text("Select Report Type"),
              items: reportTypes.map((String report) {
                return DropdownMenuItem<String>(
                  value: report,
                  child: Text(report),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedReportType = value;
                  generateReport(
                      value!); // Explicit reference to the method
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(child: reportContent),
          ],
        ),
      ),
    );
  }

  Future<void> _exportReportAsPDF(String reportType) async {
    switch (reportType) {
      case 'Game Result Report':
        await _exportGameResultAsPDF();
        break;
      case 'Story Creation Report':
        await _exportStoryCreationAsPDF();
        break;
      case 'World Creation Report':
        await _exportWorldCreationAsPDF();
        break;
      case 'Feedback Report':
        await _exportFeedbackAsPDF();
        break;
    }
  }

  Future<void> _exportGameResultAsPDF() async {
    final pdf = pw.Document();
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please log in to export your game results.')),
      );
      return;
    }

    // Fetch game saves and auto-save game data
    QuerySnapshot gameSavesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('game_saves')
        .get();

    QuerySnapshot autoSavesSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .collection('auto_save')
        .get();

    // Combine game saves and auto-saves
    List<QueryDocumentSnapshot> combinedGameSaves = [
      ...gameSavesSnapshot.docs,
      ...autoSavesSnapshot.docs,
    ];

    if (combinedGameSaves.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No game results available to export.')),
      );
      return;
    }

    // Add a title page
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Text(
              'Game Result Report',
              style: pw.TextStyle(fontSize: 32, fontWeight: pw.FontWeight.bold),
            ),
          );
        },
      ),
    );

    // Add the game results with vivid descriptions
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Generated on: ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Text('Game Results:',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...combinedGameSaves.map((doc) {
                var gameData = doc.data() as Map<String, dynamic>;

                String slotName = gameData['slotName'] ?? 'Unknown Slot';
                int currentState = gameData['current_state'] ?? 0;
                bool gameOver = gameData['game_over'] ?? false;
                bool trueEnding = gameData['true_ending'] ?? false;
                bool doorBroken = gameData['door_breaking'] ?? false;
                bool puzzleSolved = gameData['puzzle_solved'] ?? false;
                bool killedByCultists = gameData['killed_by_cultists'] ?? false;
                bool killedByBoss = gameData['killed_by_boss'] ?? false;
                bool getBook = gameData['get_book'] ?? false;
                bool getNecklace = gameData['get_necklace'] ?? false;
                Timestamp timestamp = gameData['timestamp'] ?? Timestamp.now();
                DateTime saveDate = timestamp.toDate();

                String resultDescription = gameOver
                    ? (killedByCultists
                        ? "In a harrowing encounter, you fell to the cultists' dark rituals. Their black magic overwhelmed you, and you could not escape their grasp."
                        : killedByBoss
                            ? "The final battle against the Dweller from the Depth was brutal. Despite your efforts, the creature's might proved too much, and you fell in battle."
                            : "You navigated through the dangers and managed to survive against all odds.")
                    : "Through cunning and strength, you survived and emerged victorious in this adventure.";

                String puzzleStatus = puzzleSolved
                    ? "Your wit was on display as you cracked a complex puzzle, unraveling the mysteries behind a secret passage."
                    : "The enigma of the puzzle remained unsolved, its secrets still waiting for another challenger.";

                String doorStatus = doorBroken
                    ? "With sheer force, you managed to break down a sturdy door, revealing hidden dangers and rewards."
                    : "You could not break the door, leaving certain areas of the world unexplored.";

                String endingStatus = trueEnding
                    ? "After much perseverance, you unlocked the true ending, discovering the deeper truths behind your adventure."
                    : "You reached the end of the story, but the true ending still eluded you.";

                String itemsAcquired = getBook || getNecklace
                    ? "During your journey, you acquired significant items: ${getBook ? 'an ancient book of forbidden knowledge' : ''}${getNecklace ? ' and a necklace of mystical power' : ''}, each contributing to your ability to progress through the world."
                    : "No significant items were obtained during your journey.";

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Save Slot: $slotName',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Date of Save: ${saveDate.toLocal()}'),
                      pw.SizedBox(height: 8),
                      pw.Text(resultDescription,
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey800)),
                      pw.SizedBox(height: 8),
                      pw.Text(puzzleStatus,
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey800)),
                      pw.SizedBox(height: 8),
                      pw.Text(doorStatus,
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey800)),
                      pw.SizedBox(height: 8),
                      pw.Text(endingStatus,
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey800)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                          itemsAcquired.isEmpty
                              ? "No significant items were acquired."
                              : itemsAcquired,
                          style: const pw.TextStyle(
                              fontSize: 14, color: PdfColors.grey800)),
                      pw.Divider(),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportStoryCreationAsPDF() async {
    final pdf = pw.Document();
    QuerySnapshot storySnapshot =
        await FirebaseFirestore.instance.collection('stories').get();

    if (storySnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No stories available to export.')),
      );
      return;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Story Creation Report',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text('Generated on: ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Text('Stories Created',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...storySnapshot.docs.map((doc) {
                var story = doc.data() as Map<String, dynamic>;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                          'Story Name: ${story['script_name'] ?? 'Unknown'}',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Location: ${story['location'] ?? 'Unknown'}',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text('Objective: ${story['objective'] ?? 'Unknown'}',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                          'Plot: ${story['plot_description'] ?? 'No description available'}',
                          style: pw.TextStyle(
                              fontSize: 14, fontStyle: pw.FontStyle.italic)),
                      pw.Divider(),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportWorldCreationAsPDF() async {
    final pdf = pw.Document();
    QuerySnapshot worldSnapshot =
        await FirebaseFirestore.instance.collection('worlds').get();

    if (worldSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No worlds available to export.')),
      );
      return;
    }

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('World Creation Report',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text('Generated on: ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Text('Worlds Created',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...worldSnapshot.docs.map((doc) {
                var world = doc.data() as Map<String, dynamic>;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('World Name: ${world['world_name'] ?? 'Unknown'}',
                          style: pw.TextStyle(
                              fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      pw.Text('Type: ${world['world_type'] ?? 'Unknown'}',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                          'Description: ${world['world_description'] ?? 'No description available'}',
                          style: pw.TextStyle(
                              fontSize: 14, fontStyle: pw.FontStyle.italic)),
                      pw.Divider(),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  Future<void> _exportFeedbackAsPDF() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to export your feedback.')),
      );
      return;
    }

    QuerySnapshot feedbackSnapshot = await FirebaseFirestore.instance
        .collection('feedbacks')
        .where('uid', isEqualTo: currentUser.uid)
        .get();

    if (feedbackSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No feedback available to export.')),
      );
      return;
    }

    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Feedback Report',
                  style: pw.TextStyle(
                      fontSize: 32, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 16),
              pw.Divider(),
              pw.SizedBox(height: 16),
              pw.Text('Generated on: ${DateTime.now().toString()}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey)),
              pw.SizedBox(height: 20),
              pw.Text('User Feedback',
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              ...feedbackSnapshot.docs.map((doc) {
                var feedback = doc.data() as Map<String, dynamic>;
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Rating: ${feedback['rating']} stars',
                          style: const pw.TextStyle(fontSize: 16)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                          'Improvements: ${feedback['improvements'] ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.SizedBox(height: 8),
                      pw.Text(
                          'Comments: ${feedback['feedback'] ?? 'No comments'}',
                          style: const pw.TextStyle(fontSize: 14)),
                      pw.Text(
                        'Date: ${feedback['timestamp'] != null ? (feedback['timestamp'] as Timestamp).toDate() : 'No date'}',
                        style:
                            const pw.TextStyle(color: PdfColors.grey, fontSize: 12),
                      ),
                      pw.Divider(),
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget buildGameResultReport() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return const Center(
          child: Text("Please log in to view your game results."));
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .collection(
              'game_saves') // Fetching game saves for the logged-in user
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No game results available."));
        }

        List<QueryDocumentSnapshot> gameSaves = snapshot.data!.docs;
        return ListView.builder(
          itemCount: gameSaves.length,
          itemBuilder: (context, index) {
            var gameData = gameSaves[index].data() as Map<String, dynamic>;

            String slotName = gameData['slotName'] ?? 'Unknown Slot';
            int currentState = gameData['current_state'] ?? 0;
            bool gameOver = gameData['game_over'] ?? false;
            bool trueEnding = gameData['true_ending'] ?? false;
            bool doorBroken = gameData['door_breaking'] ?? false;
            bool puzzleSolved = gameData['puzzle_solved'] ?? false;
            bool killedByCultists = gameData['killed_by_cultists'] ?? false;
            bool killedByBoss = gameData['killed_by_boss'] ?? false;
            bool getBook = gameData['get_book'] ?? false;
            bool getNecklace = gameData['get_necklace'] ?? false;
            Timestamp timestamp = gameData['timestamp'] ?? Timestamp.now();
            DateTime saveDate = timestamp.toDate();

            String resultDescription = gameOver
                ? (killedByCultists
                    ? "You fell victim to a ritual led by the dark cultists. Surrounded and overwhelmed, their dark magic was too much to bear."
                    : killedByBoss
                        ? "After a long struggle, you faced the Dweller of the Depth. Despite your best efforts, its overwhelming strength brought your journey to an abrupt end."
                        : "Though the journey was tough, you survived the perils that awaited.")
                : "You survived and emerged victorious in this treacherous adventure.";

            String puzzleStatus = puzzleSolved
                ? "Your sharp mind helped you crack a complex puzzle, revealing a hidden path ahead."
                : "The mysteries of the puzzle remained unsolved, leaving paths yet to be discovered.";

            String doorStatus = doorBroken
                ? "Using your strength and wit, you smashed through a heavy door blocking your way, revealing the unknown."
                : "The imposing door stood firm against your attempts, refusing to budge.";

            String endingStatus = trueEnding
                ? "With determination and insight, you unlocked the game's true ending, revealing the full scope of its mysteries."
                : "Though you completed your journey, the true ending eluded you this time.";

            String itemsAcquired = getBook || getNecklace
                ? "Along the way, you gathered precious items: ${getBook ? 'an ancient, forbidden book ' : ''}${getNecklace ? 'a powerful, mystical necklace' : ''}, each with its own potential for unlocking further secrets."
                : "You left the adventure without any major artifacts, the mysteries of the items still concealed.";

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Slot name in the first row
                    Row(
                      children: [
                        Text(
                          'Save Slot: $slotName',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Save date in the second row
                    Row(
                      children: [
                        Text('Date of Save: ${saveDate.toLocal()}'),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Game summary with vivid descriptions
                    Row(
                      children: [
                        const Icon(Icons.flag),
                        const SizedBox(width: 8),
                        Expanded(child: Text('Current State: $currentState')),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(gameOver ? Icons.close : Icons.check,
                            color: gameOver ? Colors.red : Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(resultDescription,
                                style: const TextStyle(fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(
                            puzzleSolved
                                ? FontAwesomeIcons.lockOpen
                                : FontAwesomeIcons.lock,
                            color: puzzleSolved ? Colors.green : Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(puzzleStatus)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(doorBroken
                            ? FontAwesomeIcons.doorOpen
                            : FontAwesomeIcons.doorClosed),
                        const SizedBox(width: 8),
                        Expanded(child: Text(doorStatus)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Icon(trueEnding ? Icons.stars : Icons.star_border),
                        const SizedBox(width: 8),
                        Expanded(child: Text(endingStatus)),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        const Icon(FontAwesomeIcons.gem),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(itemsAcquired.isEmpty
                                ? "No significant items were acquired during this adventure."
                                : itemsAcquired)),
                      ],
                    ),

                    const SizedBox(height: 8),
                    const Divider(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Story Creation Report
// Story Creation Report
  Widget buildStoryCreationReport() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('stories').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No stories available."));
        }

        List<QueryDocumentSnapshot> stories = snapshot.data!.docs;
        return ListView.builder(
          itemCount: stories.length,
          itemBuilder: (context, index) {
            var story = stories[index].data() as Map<String, dynamic>;

            // Extract necessary fields from Firestore
            String storyName = story['script_name'] ?? 'Unknown';
            String location = story['location'] ?? 'Unknown';
            String objective = story['objective'] ?? 'Unknown';
            String plotDescription =
                story['plot_description'] ?? 'No description available';
            String timePeriod = story['time_period'] ?? 'Unknown';
            int pacing = story['pacing'] ?? 1;
            int storyLength = story['story_length'] ?? 1;

            // Visual display for pacing (you can modify the icons/colors to your preference)
            List<Widget> pacingStars = List.generate(pacing, (index) {
              return Icon(Icons.star, color: Colors.yellow[700]);
            });

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display story name and its pacing
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            storyName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Row(children: pacingStars),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Story Location and Objective
                    Row(
                      children: [
                        const Icon(Icons.location_city,
                            color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Location: $location',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.flag, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Objective: $objective',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Plot description
                    Text(
                      plotDescription,
                      style: const TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 8),

                    // Story details
                    Text(
                      'Time Period: $timePeriod',
                      style: const TextStyle(fontSize: 14),
                    ),
                    Text(
                      'Story Length: $storyLength sections',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// World Creation Report
  Widget buildWorldCreationReport() {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('worlds').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("No worlds available."));
        }

        List<QueryDocumentSnapshot> worlds = snapshot.data!.docs;
        return ListView.builder(
          itemCount: worlds.length,
          itemBuilder: (context, index) {
            var world = worlds[index].data() as Map<String, dynamic>;

            // Extract necessary fields from Firestore
            String worldName = world['world_name'] ?? 'Unknown';
            String worldType = world['world_type'] ?? 'Unknown';
            String biomeDiversity = world['biome_diversity'] ?? 'Unknown';
            String magicOrTech = world['magic_or_tech'] ?? 'Unknown';
            int magicTechScale = world['magic_tech_scale'] ?? 1;
            String specialLocation = world['special_location'] ?? 'Unknown';
            int numberOfContinents = world['number_of_continents'] != null
                ? int.parse(world['number_of_continents'])
                : 0;
            String worldDescription =
                world['world_description'] ?? 'No description available';

            // Visual display for magic/tech scale (you can modify icons/colors to your preference)
            List<Widget> magicTechIcons =
                List.generate(magicTechScale, (index) {
              return Icon(
                magicOrTech == 'Magic' ? Icons.auto_awesome : Icons.settings,
                color:
                    magicOrTech == 'Magic' ? Colors.purple : Colors.blueAccent,
              );
            });

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display world name and type
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            worldName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '($worldType)',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Biome diversity and number of continents
                    Row(
                      children: [
                        const Icon(Icons.landscape, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'Biome: $biomeDiversity',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.public, color: Colors.brown),
                        const SizedBox(width: 8),
                        Text(
                          'Continents: $numberOfContinents',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Magic or Tech and special location
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          '$magicOrTech Level: ',
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(children: magicTechIcons),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent),
                        const SizedBox(width: 8),
                        Text(
                          'Special Location: $specialLocation',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // World description
                    Text(
                      worldDescription,
                      style: const TextStyle(
                          fontSize: 14, fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Feedback Report based on logged-in user
  Widget buildFeedbackReport() {
    User? currentUser =
        FirebaseAuth.instance.currentUser; // Get the current user

    if (currentUser == null) {
      return const Center(
        child: Text("Please log in to view your feedback."),
      );
    }

    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection(
              'feedbacks') // Ensure this matches the collection name in Firestore
          .where('uid', isEqualTo: currentUser.uid) // Filter by user ID
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.feedback, size: 60, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  "No feedback available.",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }

        List<QueryDocumentSnapshot> feedbacks = snapshot.data!.docs;

        return ListView.builder(
          itemCount: feedbacks.length,
          itemBuilder: (context, index) {
            var feedback = feedbacks[index].data() as Map<String, dynamic>;

            // Extract necessary fields
            String rating = feedback['rating'].toString();
            String improvements = feedback['improvements'] ?? 'N/A';
            String comments = feedback['feedback'] ?? 'No comments';
            Timestamp timestamp = feedback['timestamp'] ?? Timestamp.now();
            DateTime feedbackDate = timestamp.toDate();

            return Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Display the star rating
                    Row(
                      children: List.generate(5, (starIndex) {
                        return Icon(
                          starIndex < int.parse(rating)
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),

                    // Display improvements
                    Text(
                      'Improvements: $improvements',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Display feedback comments
                    Text(
                      'Comments: $comments',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 4),

                    // Display feedback date
                    Text(
                      'Feedback Date: ${feedbackDate.toLocal()}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> generateReport(String reportType) async {
    switch (reportType) {
      case 'Game Result Report':
        setState(() {
          reportContent = buildGameResultReport();
        });
        break;
      case 'Story Creation Report':
        setState(() {
          reportContent = buildStoryCreationReport();
        });
        break;
      case 'World Creation Report':
        setState(() {
          reportContent = buildWorldCreationReport();
        });
        break;
      case 'Feedback Report':
        setState(() {
          reportContent = buildFeedbackReport();
        });
        break;
      default:
        setState(() {
          reportContent = const Center(child: Text("Please select a report"));
        });
    }
  }
}
