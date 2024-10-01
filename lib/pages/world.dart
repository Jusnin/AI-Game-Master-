import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';


class CreateWorld extends StatefulWidget {
  const CreateWorld({super.key});

  @override
  _CreateWorldState createState() => _CreateWorldState();
}

class _CreateWorldState extends State<CreateWorld>
    with SingleTickerProviderStateMixin {
  final TextEditingController _worldNameController = TextEditingController();
  final TextEditingController _worldDescriptionController = TextEditingController();
  final TextEditingController _numberOfContinentsController = TextEditingController();
  final TextEditingController _otherWorldTypeController = TextEditingController();
  final TextEditingController _otherSpecialLocationController = TextEditingController();

  String _selectedWorldType = 'Fantasy';
  String _selectedBiomeDiversity = 'Desert';
  String _selectedSpecialLocation = 'Magical Ruins';
  String _selectedMagicOrTech = 'Magic';
  double _magicTechScale = 3;
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
    _worldNameController.dispose();
    _worldDescriptionController.dispose();
    _numberOfContinentsController.dispose();
    _otherWorldTypeController.dispose();
    _otherSpecialLocationController.dispose();
    _tabController.dispose();
    super.dispose();
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
    String apiKey = remoteConfig.getString('api_key_world');
    return apiKey;
  } catch (e) {
    print("Failed to fetch API key: $e");
    return ''; // Return empty string or handle the error appropriately
  }
}
  
Future<void> _saveWorldToFirestore() async {
  if (_currentUser == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in to save the world.')),
    );
    return;
  }

  // Collect the world data
  final worldData = {
    'World Name': _worldNameController.text,
    'World Type': _selectedWorldType == 'Other'
        ? _otherWorldTypeController.text
        : _selectedWorldType,
    'Number of Major Continents': _numberOfContinentsController.text,
    'Biome Diversity': _selectedBiomeDiversity,
    'Special Locations': _selectedSpecialLocation == 'Other'
        ? _otherSpecialLocationController.text
        : _selectedSpecialLocation,
    'Magic or Technology': _selectedMagicOrTech,
    'Scale': _magicTechScale.toInt(),
  };

    // Fetch the API key from Firebase Remote Config
    String apiKey = await fetchApiKey();

  try {
    // Send POST request
    final response = await http.post(
      Uri.parse(apiKey), // or your network IP
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(worldData),
    );

    if (response.statusCode == 200) {
      // Parse response and get generated description
      final generatedData = jsonDecode(response.body);
      final generatedDescription = generatedData['description'];

      // Save to Firestore
      await FirebaseFirestore.instance.collection('worlds').add({
        'uid': _currentUser!.uid,
        'world_name': _worldNameController.text,
        'world_type': _selectedWorldType == 'Other'
            ? _otherWorldTypeController.text
            : _selectedWorldType,
        'number_of_continents': _numberOfContinentsController.text,
        'biome_diversity': _selectedBiomeDiversity,
        'special_location': _selectedSpecialLocation == 'Other'
            ? _otherSpecialLocationController.text
            : _selectedSpecialLocation,
        'magic_or_tech': _selectedMagicOrTech,
        'magic_tech_scale': _magicTechScale.toInt(),
        'world_description': generatedDescription,  // Store generated description
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('World Created Successfully!')),
      );
    } else {
      // Error handling
      print('Failed to generate world description: ${response.body}');
      throw Exception('Failed to generate world description');
    }
  } catch (e) {
    print('Error: $e');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save world: $e')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('World Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create World'),
            Tab(text: 'Manage Worlds'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateWorldTab(),
          _buildManageWorldsTab(),
        ],
      ),
    );
  }

  Widget _buildCreateWorldTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _worldNameController,
            decoration: const InputDecoration(
              labelText: 'World Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('World Type'),
          _buildRadioButtonWithIcon('Fantasy', _selectedWorldType, (value) {
            setState(() {
              _selectedWorldType = value!;
            });
          }, FontAwesomeIcons.book),
          _buildRadioButtonWithIcon('Sci-Fi', _selectedWorldType, (value) {
            setState(() {
              _selectedWorldType = value!;
            });
          }, FontAwesomeIcons.robot),
          _buildRadioButtonWithIcon('Post-Apocalyptic', _selectedWorldType, (value) {
            setState(() {
              _selectedWorldType = value!;
            });
          }, FontAwesomeIcons.skullCrossbones),
          _buildRadioButtonWithIcon('Steampunk', _selectedWorldType, (value) {
            setState(() {
              _selectedWorldType = value!;
            });
          }, FontAwesomeIcons.cog),
          _buildRadioButtonWithIcon('Other', _selectedWorldType, (value) {
            setState(() {
              _selectedWorldType = value!;
            });
          }, FontAwesomeIcons.globe),
          if (_selectedWorldType == 'Other')
            TextField(
              controller: _otherWorldTypeController,
              decoration: const InputDecoration(
                labelText: 'Specify World Type',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Number of Major Continents'),
          TextField(
            controller: _numberOfContinentsController,
            decoration: const InputDecoration(
              labelText: 'Number of Major Continents',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Biome Diversity'),
          _buildRadioButtonWithIcon('Desert', _selectedBiomeDiversity, (value) {
            setState(() {
              _selectedBiomeDiversity = value!;
            });
          }, FontAwesomeIcons.sun),
          _buildRadioButtonWithIcon('Forest', _selectedBiomeDiversity, (value) {
            setState(() {
              _selectedBiomeDiversity = value!;
            });
          }, FontAwesomeIcons.tree),
          _buildRadioButtonWithIcon('Mountain', _selectedBiomeDiversity, (value) {
            setState(() {
              _selectedBiomeDiversity = value!;
            });
          }, FontAwesomeIcons.mountain),
          _buildRadioButtonWithIcon('Ocean', _selectedBiomeDiversity, (value) {
            setState(() {
              _selectedBiomeDiversity = value!;
            });
          }, FontAwesomeIcons.water),
          _buildRadioButtonWithIcon('Mixed', _selectedBiomeDiversity, (value) {
            setState(() {
              _selectedBiomeDiversity = value!;
            });
          }, FontAwesomeIcons.globe),
          const SizedBox(height: 20),
          const Text('Special Locations'),
          _buildRadioButtonWithIcon('Magical Ruins', _selectedSpecialLocation, (value) {
            setState(() {
              _selectedSpecialLocation = value!;
            });
          }, FontAwesomeIcons.archway),
          _buildRadioButtonWithIcon('Space Stations', _selectedSpecialLocation, (value) {
            setState(() {
              _selectedSpecialLocation = value!;
            });
          }, FontAwesomeIcons.spaceShuttle),
          _buildRadioButtonWithIcon('Ancient Cities', _selectedSpecialLocation, (value) {
            setState(() {
              _selectedSpecialLocation = value!;
            });
          }, FontAwesomeIcons.city),
          _buildRadioButtonWithIcon('Other', _selectedSpecialLocation, (value) {
            setState(() {
              _selectedSpecialLocation = value!;
            });
          }, FontAwesomeIcons.globe),
          if (_selectedSpecialLocation == 'Other')
            TextField(
              controller: _otherSpecialLocationController,
              decoration: const InputDecoration(
                labelText: 'Specify Special Location',
                border: OutlineInputBorder(),
              ),
            ),
          const SizedBox(height: 20),
          const Text('Magic/Technology'),
          _buildRadioButtonWithIcon('Magic', _selectedMagicOrTech, (value) {
            setState(() {
              _selectedMagicOrTech = value!;
            });
          }, FontAwesomeIcons.hatWizard),
          _buildRadioButtonWithIcon('Technology', _selectedMagicOrTech, (value) {
            setState(() {
              _selectedMagicOrTech = value!;
            });
          }, FontAwesomeIcons.microchip),
          const SizedBox(height: 20),
          const Text('Magic or Tech Scale'),
          _buildSlider('Magic/Technology Level', _magicTechScale, (value) {
            setState(() {
              _magicTechScale = value;
            });
          }),
          const SizedBox(height: 20),
          TextFormField(
            controller: _worldDescriptionController,
            decoration: const InputDecoration(
              labelText: 'World Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_worldNameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('World name cannot be empty!')),
                  );
                  return;
                }
                _saveWorldToFirestore();
              },
              child: const Text('Create World'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageWorldsTab() {
    if (_currentUser == null) {
      return const Center(
        child: Text('Please log in to manage your worlds.'),
      );
    }

    final CollectionReference worldCollection =
        FirebaseFirestore.instance.collection('worlds');

    return StreamBuilder(
      stream: worldCollection
          .where('uid', isEqualTo: _currentUser!.uid) // Filter worlds by the current user's UID
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No worlds found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            return ListTile(
              title: Text(doc['world_name']),
              subtitle: Text('World Type: ${doc['world_type']} | Special Location: ${doc['special_location']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _editWorld(context, doc);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await worldCollection.doc(doc.id).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('World deleted successfully!')),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
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

  void _editWorld(BuildContext context, DocumentSnapshot doc) {
    TextEditingController worldNameController =
        TextEditingController(text: doc['world_name']);
    String selectedWorldType = doc['world_type'];
    String selectedBiomeDiversity = doc['biome_diversity'];
    String selectedSpecialLocation = doc['special_location'];
    String selectedMagicOrTech = doc['magic_or_tech'];
    double magicTechScale = doc['magic_tech_scale'].toDouble();
    TextEditingController worldDescriptionController =
        TextEditingController(text: doc['world_description']);
    TextEditingController numberOfContinentsController =
        TextEditingController(text: doc['number_of_continents']);

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
                        controller: worldNameController,
                        decoration: const InputDecoration(
                          labelText: 'World Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('World Type'),
                      _buildRadioButtonWithIcon('Fantasy', selectedWorldType, (value) {
                        setModalState(() {
                          selectedWorldType = value!;
                        });
                      }, FontAwesomeIcons.book),
                      _buildRadioButtonWithIcon('Sci-Fi', selectedWorldType, (value) {
                        setModalState(() {
                          selectedWorldType = value!;
                        });
                      }, FontAwesomeIcons.robot),
                      _buildRadioButtonWithIcon('Post-Apocalyptic', selectedWorldType, (value) {
                        setModalState(() {
                          selectedWorldType = value!;
                        });
                      }, FontAwesomeIcons.skullCrossbones),
                      _buildRadioButtonWithIcon('Steampunk', selectedWorldType, (value) {
                        setModalState(() {
                          selectedWorldType = value!;
                        });
                      }, FontAwesomeIcons.cog),
                      _buildRadioButtonWithIcon('Other', selectedWorldType, (value) {
                        setModalState(() {
                          selectedWorldType = value!;
                        });
                      }, FontAwesomeIcons.globe),
                      if (selectedWorldType == 'Other')
                        TextField(
                          controller: _otherWorldTypeController,
                          decoration: const InputDecoration(
                            labelText: 'Specify World Type',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Number of Major Continents'),
                      TextField(
                        controller: numberOfContinentsController,
                        decoration: const InputDecoration(
                          labelText: 'Number of Major Continents',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text('Biome Diversity'),
                      _buildRadioButtonWithIcon('Desert', selectedBiomeDiversity, (value) {
                        setModalState(() {
                          selectedBiomeDiversity = value!;
                        });
                      }, FontAwesomeIcons.sun),
                      _buildRadioButtonWithIcon('Forest', selectedBiomeDiversity, (value) {
                        setModalState(() {
                          selectedBiomeDiversity = value!;
                        });
                      }, FontAwesomeIcons.tree),
                      _buildRadioButtonWithIcon('Mountain', selectedBiomeDiversity, (value) {
                        setModalState(() {
                          selectedBiomeDiversity = value!;
                        });
                      }, FontAwesomeIcons.mountain),
                      _buildRadioButtonWithIcon('Ocean', selectedBiomeDiversity, (value) {
                        setModalState(() {
                          selectedBiomeDiversity = value!;
                        });
                      }, FontAwesomeIcons.water),
                      _buildRadioButtonWithIcon('Mixed', selectedBiomeDiversity, (value) {
                        setModalState(() {
                          selectedBiomeDiversity = value!;
                        });
                      }, FontAwesomeIcons.globe),
                      const SizedBox(height: 20),
                      const Text('Special Locations'),
                      _buildRadioButtonWithIcon('Magical Ruins', selectedSpecialLocation, (value) {
                        setModalState(() {
                          selectedSpecialLocation = value!;
                        });
                      }, FontAwesomeIcons.archway),
                      _buildRadioButtonWithIcon('Space Stations', selectedSpecialLocation, (value) {
                        setModalState(() {
                          selectedSpecialLocation = value!;
                        });
                      }, FontAwesomeIcons.spaceShuttle),
                      _buildRadioButtonWithIcon('Ancient Cities', selectedSpecialLocation, (value) {
                        setModalState(() {
                          selectedSpecialLocation = value!;
                        });
                      }, FontAwesomeIcons.city),
                      _buildRadioButtonWithIcon('Other', selectedSpecialLocation, (value) {
                        setModalState(() {
                          selectedSpecialLocation = value!;
                        });
                      }, FontAwesomeIcons.globe),
                      if (selectedSpecialLocation == 'Other')
                        TextField(
                          controller: _otherSpecialLocationController,
                          decoration: const InputDecoration(
                            labelText: 'Specify Special Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text('Magic/Technology'),
                      _buildRadioButtonWithIcon('Magic', selectedMagicOrTech, (value) {
                        setModalState(() {
                          selectedMagicOrTech = value!;
                        });
                      }, FontAwesomeIcons.hatWizard),
                      _buildRadioButtonWithIcon('Technology', selectedMagicOrTech, (value) {
                        setModalState(() {
                          selectedMagicOrTech = value!;
                        });
                      }, FontAwesomeIcons.microchip),
                      const SizedBox(height: 20),
                      const Text('Magic or Tech Scale'),
                      _buildSlider('Magic/Technology Level', magicTechScale, (value) {
                        setModalState(() {
                          magicTechScale = value;
                        });
                      }),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: worldDescriptionController,
                        decoration: const InputDecoration(
                          labelText: 'World Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('worlds')
                              .doc(doc.id)
                              .update({
                            'world_name': worldNameController.text,
                            'world_type': selectedWorldType == 'Other'
                                ? _otherWorldTypeController.text
                                : selectedWorldType,
                            'number_of_continents': numberOfContinentsController.text,
                            'biome_diversity': selectedBiomeDiversity,
                            'special_location': selectedSpecialLocation == 'Other'
                                ? _otherSpecialLocationController.text
                                : selectedSpecialLocation,
                            'magic_or_tech': selectedMagicOrTech,
                            'magic_tech_scale': magicTechScale.toInt(),
                            'world_description': worldDescriptionController.text,
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
