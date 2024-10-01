import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class StoryCreationPage extends StatefulWidget {
  const StoryCreationPage({super.key});

  @override
  _StoryCreationPageState createState() => _StoryCreationPageState();
}

class _StoryCreationPageState extends State<StoryCreationPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _scriptNameController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final TextEditingController _otherTimePeriodController = TextEditingController();
  final TextEditingController _otherLocationController = TextEditingController();
  final TextEditingController _otherObjectiveController = TextEditingController();

  String _selectedTimePeriod = 'Medieval';
  String _selectedLocation = 'City';
  String _selectedObjective = 'Rescue';
  String _plotDescription = '';
  double _pacing = 3;
  double _storyLength = 3;
  late TabController _tabController;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser; // Get the current user
  }

  @override
  void dispose() {
    _scriptNameController.dispose();
    _remarksController.dispose();
    _otherTimePeriodController.dispose();
    _otherLocationController.dispose();
    _otherObjectiveController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Save Story Script Data to Firebase Firestore
  Future<void> _saveStoryToFirestore(String generatedDescription) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to save the story.')),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('stories').add({
        'uid': _currentUser!.uid,  // Save the user's UID
        'script_name': _scriptNameController.text,
        'time_period': _selectedTimePeriod == 'Other'
            ? _otherTimePeriodController.text
            : _selectedTimePeriod,
        'location': _selectedLocation == 'Other'
            ? _otherLocationController.text
            : _selectedLocation,
        'objective': _selectedObjective == 'Other'
            ? _otherObjectiveController.text
            : _selectedObjective,
        'plot_description': generatedDescription,  // Save generated description
        'pacing': _pacing.toInt(),
        'story_length': _storyLength.toInt(),
        'remarks': _remarksController.text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Story Created Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save story: $e')),
      );
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
    String apiKey = remoteConfig.getString('api_key_story');
    return apiKey;
  } catch (e) {
    print("Failed to fetch API key: $e");
    return ''; // Return empty string or handle the error appropriately
  }
}

  // Function to make a POST request to Flask API
Future<void> _generatePlotDescription() async {
      // Fetch the API key from Firebase Remote Config
    String apiKey = await fetchApiKey();

  final url = Uri.parse(apiKey); // Adjust your Flask API URL
  final Map<String, dynamic> storyData = {
    'time_period': _selectedTimePeriod == 'Other' ? _otherTimePeriodController.text : _selectedTimePeriod,
    'location': _selectedLocation == 'Other' ? _otherLocationController.text : _selectedLocation,
    'objective': _selectedObjective == 'Other' ? _otherObjectiveController.text : _selectedObjective,
    'pacing': _pacing.toInt(),
    'length': _storyLength.toInt(),
    'name': _scriptNameController.text,
    'description': _plotDescription.isNotEmpty ? _plotDescription : 'No description available'
  };

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(storyData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _plotDescription = data['generated_story_setting'] ?? 'No description available';  // Update plot description
      });
    } else {
      throw Exception('Failed to generate description');
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to generate plot description: $e')),
    );
  }
}


// On pressing the Create Story button
void _onCreateStory() async {
  if (_scriptNameController.text.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Script name cannot be empty!')),
    );
    return;
  }

  // Generate the plot description from the Flask API
  await _generatePlotDescription();  // Wait for the plot description to be generated

  // Save the story along with the generated description to Firestore
  _saveStoryToFirestore(_plotDescription);  // Pass the updated plot description
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Story Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Story'),
            Tab(text: 'Manage Stories'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateStoryTab(),
          _buildManageStoriesTab(),
        ],
      ),
    );
  }

  Widget _buildCreateStoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _scriptNameController,
            decoration: const InputDecoration(
              labelText: 'Script Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Time Period'),
          _buildRadioButtonWithIcon('Medieval', _selectedTimePeriod, (value) {
            setState(() {
              _selectedTimePeriod = value!;
            });
          }, FontAwesomeIcons.chessKnight),
          _buildRadioButtonWithIcon('Modern', _selectedTimePeriod, (value) {
            setState(() {
              _selectedTimePeriod = value!;
            });
          }, FontAwesomeIcons.city),
          _buildRadioButtonWithIcon('Futuristic', _selectedTimePeriod, (value) {
            setState(() {
              _selectedTimePeriod = value!;
            });
          }, FontAwesomeIcons.robot),
          _buildRadioButtonWithIcon('Other', _selectedTimePeriod, (value) {
            setState(() {
              _selectedTimePeriod = value!;
            });
          }, FontAwesomeIcons.globe),
          if (_selectedTimePeriod == 'Other')
            TextField(
              controller: _otherTimePeriodController,
              decoration: const InputDecoration(
                labelText: 'Specify Time Period',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Location'),
          _buildRadioButtonWithIcon('City', _selectedLocation, (value) {
            setState(() {
              _selectedLocation = value!;
            });
          }, FontAwesomeIcons.building),
          _buildRadioButtonWithIcon('Forest', _selectedLocation, (value) {
            setState(() {
              _selectedLocation = value!;
            });
          }, FontAwesomeIcons.tree),
          _buildRadioButtonWithIcon('Space Station', _selectedLocation, (value) {
            setState(() {
              _selectedLocation = value!;
            });
          }, FontAwesomeIcons.spaceShuttle),
          _buildRadioButtonWithIcon('Other', _selectedLocation, (value) {
            setState(() {
              _selectedLocation = value!;
            });
          }, FontAwesomeIcons.globe),
          if (_selectedLocation == 'Other')
            TextField(
              controller: _otherLocationController,
              decoration: const InputDecoration(
                labelText: 'Specify Location',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Core Objective'),
          _buildRadioButtonWithIcon('Rescue', _selectedObjective, (value) {
            setState(() {
              _selectedObjective = value!;
            });
          }, FontAwesomeIcons.handsHelping),
          _buildRadioButtonWithIcon('Recovery', _selectedObjective, (value) {
            setState(() {
              _selectedObjective = value!;
            });
          }, FontAwesomeIcons.firstAid),
          _buildRadioButtonWithIcon('Escape', _selectedObjective, (value) {
            setState(() {
              _selectedObjective = value!;
            });
          }, FontAwesomeIcons.running),
          _buildRadioButtonWithIcon('Survival', _selectedObjective, (value) {
            setState(() {
              _selectedObjective = value!;
            });
          }, FontAwesomeIcons.lifeRing),
          _buildRadioButtonWithIcon('Other', _selectedObjective, (value) {
            setState(() {
              _selectedObjective = value!;
            });
          }, FontAwesomeIcons.globe),
          if (_selectedObjective == 'Other')
            TextField(
              controller: _otherObjectiveController,
              decoration: const InputDecoration(
                labelText: 'Specify Objective',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Plot Description'),
          TextField(
            controller: TextEditingController(text: _plotDescription),  // Display the generated description
            onChanged: (value) {
              setState(() {
                _plotDescription = value;
              });
            },
            decoration: const InputDecoration(
              hintText: 'Briefly describe your plot',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Pacing'),
          _buildSlider('Pacing', _pacing, (value) {
            setState(() {
              _pacing = value;
            });
          }),
          const SizedBox(height: 20),
          const Text('Story Length'),
          _buildSlider('Story Length', _storyLength, (value) {
            setState(() {
              _storyLength = value;
            });
          }),
          const SizedBox(height: 20),
          TextFormField(
            controller: _remarksController,
            decoration: const InputDecoration(
              labelText: 'Remarks',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: _onCreateStory,
              child: const Text('Create Story'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageStoriesTab() {
  if (_currentUser == null) {
    return const Center(
      child: Text('Please log in to manage your stories.'),
    );
  }

  final CollectionReference storyCollection =
      FirebaseFirestore.instance.collection('stories');

  return StreamBuilder(
    // Filter stories by the current user's UID
    stream: storyCollection
        .where('uid', isEqualTo: _currentUser!.uid)
        .orderBy('timestamp', descending: true)
        .snapshots(),
    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      if (snapshot.data!.docs.isEmpty) {
        return const Center(child: Text('No stories found.'));
      }

      return ListView.builder(
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          DocumentSnapshot doc = snapshot.data!.docs[index];

          // Retrieve the plot description from Firestore
          String plotDescription = doc['plot_description'] ?? 'No description available';

          return ExpansionTile(
            title: Text(doc['script_name']),
            subtitle: Text('Objective: ${doc['objective']} | Location: ${doc['location']}'),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Story Description',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: TextEditingController(text: plotDescription), // Display the plot description
                      maxLines: null,
                      readOnly: true, // Make the text field read-only
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Plot Description',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Pacing: ${doc['pacing']}'),
                    Text('Story Length: ${doc['story_length']}'),
                    Text('Remarks: ${doc['remarks']}'),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editStory(context, doc);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await storyCollection.doc(doc.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Story deleted successfully!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      );
    },
  );
}


  Widget _buildSlider(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label: ${value.toInt()}'),
        Slider(
          value: value,
          min: 1,
          max: 5,
          divisions: 4,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildRadioButtonWithIcon(String label, String groupValue, ValueChanged<String?> onChanged, IconData icon) {
    return RadioListTile<String>(
      title: Row(
        children: [
          FaIcon(icon, size: 20, color: Colors.orange),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
      value: label,
      groupValue: groupValue,
      onChanged: onChanged,
    );
  }

  void _editStory(BuildContext context, DocumentSnapshot doc) {
    TextEditingController scriptNameController =
        TextEditingController(text: doc['script_name']);
    String selectedTimePeriod = doc['time_period'];
    String selectedLocation = doc['location'];
    String selectedObjective = doc['objective'];
    String plotDescription = doc['plot_description'];
    double pacing = doc['pacing'].toDouble();
    double storyLength = doc['story_length'].toDouble();
    TextEditingController remarksController =
        TextEditingController(text: doc['remarks']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
                return SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: scriptNameController,
                        decoration: const InputDecoration(
                          labelText: 'Script Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Time Period'),
                      _buildRadioButtonWithIcon('Medieval', selectedTimePeriod, (value) {
                        setModalState(() {
                          selectedTimePeriod = value!;
                        });
                      }, FontAwesomeIcons.chessKnight),
                      _buildRadioButtonWithIcon('Modern', selectedTimePeriod, (value) {
                        setModalState(() {
                          selectedTimePeriod = value!;
                        });
                      }, FontAwesomeIcons.city),
                      _buildRadioButtonWithIcon('Futuristic', selectedTimePeriod, (value) {
                        setModalState(() {
                          selectedTimePeriod = value!;
                        });
                      }, FontAwesomeIcons.robot),
                      _buildRadioButtonWithIcon('Other', selectedTimePeriod, (value) {
                        setModalState(() {
                          selectedTimePeriod = value!;
                        });
                      }, FontAwesomeIcons.globe),
                      if (selectedTimePeriod == 'Other')
                        TextField(
                          controller: _otherTimePeriodController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Time Period',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Location'),
                      _buildRadioButtonWithIcon('City', selectedLocation, (value) {
                        setModalState(() {
                          selectedLocation = value!;
                        });
                      }, FontAwesomeIcons.building),
                      _buildRadioButtonWithIcon('Forest', selectedLocation, (value) {
                        setModalState(() {
                          selectedLocation = value!;
                        });
                      }, FontAwesomeIcons.tree),
                      _buildRadioButtonWithIcon('Space Station', selectedLocation, (value) {
                        setModalState(() {
                          selectedLocation = value!;
                        });
                      }, FontAwesomeIcons.spaceShuttle),
                      _buildRadioButtonWithIcon('Other', selectedLocation, (value) {
                        setModalState(() {
                          selectedLocation = value!;
                        });
                      }, FontAwesomeIcons.globe),
                      if (selectedLocation == 'Other')
                        TextField(
                          controller: _otherLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Core Objective'),
                      _buildRadioButtonWithIcon('Rescue', selectedObjective, (value) {
                        setModalState(() {
                          selectedObjective = value!;
                        });
                      }, FontAwesomeIcons.handsHelping),
                      _buildRadioButtonWithIcon('Recovery', selectedObjective, (value) {
                        setModalState(() {
                          selectedObjective = value!;
                        });
                      }, FontAwesomeIcons.firstAid),
                      _buildRadioButtonWithIcon('Escape', selectedObjective, (value) {
                        setModalState(() {
                          selectedObjective = value!;
                        });
                      }, FontAwesomeIcons.running),
                      _buildRadioButtonWithIcon('Survival', selectedObjective, (value) {
                        setModalState(() {
                          selectedObjective = value!;
                        });
                      }, FontAwesomeIcons.lifeRing),
                      _buildRadioButtonWithIcon('Other', selectedObjective, (value) {
                        setModalState(() {
                          selectedObjective = value!;
                        });
                      }, FontAwesomeIcons.globe),
                      if (selectedObjective == 'Other')
                        TextField(
                          controller: _otherObjectiveController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Objective',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Plot Description'),
                      TextField(
                        onChanged: (value) {
                          setModalState(() {
                            plotDescription = value;
                          });
                        },
                        decoration: const InputDecoration(
                          hintText: 'Briefly describe your plot',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Pacing'),
                      _buildSlider('Pacing', pacing, (value) {
                        setModalState(() {
                          pacing = value;
                        });
                      }),
                      const SizedBox(height: 20),
                      const Text('Story Length'),
                      _buildSlider('Story Length', storyLength, (value) {
                        setModalState(() {
                          storyLength = value;
                        });
                      }),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: remarksController,
                        decoration: const InputDecoration(
                          labelText: 'Remarks',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('stories')
                              .doc(doc.id)
                              .update({
                            'script_name': scriptNameController.text,
                            'time_period': selectedTimePeriod == 'Other'
                                ? _otherTimePeriodController.text
                                : selectedTimePeriod,
                            'location': selectedLocation == 'Other'
                                ? _otherLocationController.text
                                : selectedLocation,
                            'objective': selectedObjective == 'Other'
                                ? _otherObjectiveController.text
                                : selectedObjective,
                            'plot_description': plotDescription,
                            'pacing': pacing.toInt(),
                            'story_length': storyLength.toInt(),
                            'remarks': remarksController.text,
                          });
                          Navigator.pop(context);
                        },
                        child: const Text('Save Changes'),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
