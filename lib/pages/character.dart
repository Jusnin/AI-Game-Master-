import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateCharacter extends StatefulWidget {
  const CreateCharacter({super.key});

  @override
  _CreateCharacterState createState() => _CreateCharacterState();
}

class _CreateCharacterState extends State<CreateCharacter>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  String _characterRace = 'Human';
  String _characterClass = 'Warrior';
  String _randomName = '';
  String _selectedSkill = 'Swordsmanship';
  double _strength = 3.0;
  double _dexterity = 3.0;
  double _intelligence = 3.0;
  late TabController _tabController;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _randomName = _generateRandomName();
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _storyController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  // Generate random character name
  String _generateRandomName() {
    List<String> names = [
      "Aragon",
      "Frodo",
      "Gandalf",
      "Legolas",
      "Arwen",
      "Gimli"
    ];
    return names[Random().nextInt(names.length)];
  }

  // Save Character Data to Firebase Firestore
  Future<void> _saveCharacterToFirestore() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No user logged in. Please log in first.')),
      );
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? avatarData = prefs.getString('fluttermoji'); 

      await FirebaseFirestore.instance.collection('characters').add({
        'uid': _currentUser!.uid, 
        'name': _nameController.text,
        'race': _characterRace,
        'class': _characterClass,
        'story': _storyController.text,
        'skill': _selectedSkill,
        'strength': _strength.toInt(),
        'dexterity': _dexterity.toInt(),
        'intelligence': _intelligence.toInt(),
        'avatar': avatarData ?? '', 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Character Created Successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save character: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Character Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create Character'),
            Tab(text: 'Manage Characters'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCreateCharacterTab(),
          _buildManageCharactersTab(),
        ],
      ),
    );
  }

  Widget _buildCreateCharacterTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: FluttermojiCircleAvatar(
              backgroundColor: Colors.grey[200],
              radius: 100,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: () {
                _showCustomizerModal(context);
              },
              child: const Text('Customize Avatar'),
            ),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Character Name',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _nameController.text = _generateRandomName();
                  });
                },
                child: const Text('Generate Random Name'),
              ),
              const SizedBox(width: 10),
              Text('Suggestion: $_randomName'),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _characterRace,
            decoration: const InputDecoration(
              labelText: 'Character Race',
              border: OutlineInputBorder(),
            ),
            items: ['Human', 'Elf', 'Dwarf', 'Orc'].map((String race) {
              return DropdownMenuItem<String>(
                value: race,
                child: Text(race),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _characterRace = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _characterClass,
            decoration: const InputDecoration(
              labelText: 'Character Class',
              border: OutlineInputBorder(),
            ),
            items:
                ['Warrior', 'Mage', 'Rogue', 'Cleric'].map((String charClass) {
              return DropdownMenuItem<String>(
                value: charClass,
                child: Text(charClass),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _characterClass = value!;
              });
            },
          ),
          const SizedBox(height: 20),
          const Text('Choose Your Skill:'),
          RadioListTile<String>(
            value: 'Swordsmanship',
            groupValue: _selectedSkill,
            onChanged: (value) {
              setState(() {
                _selectedSkill = value!;
              });
            },
            title: const Text('Swordsmanship'),
            secondary: const FaIcon(FontAwesomeIcons.fistRaised),
          ),
          RadioListTile<String>(
            value: 'Archery',
            groupValue: _selectedSkill,
            onChanged: (value) {
              setState(() {
                _selectedSkill = value!;
              });
            },
            title: const Text('Archery'),
            secondary: const FaIcon(FontAwesomeIcons.bullseye),
          ),
          RadioListTile<String>(
            value: 'Magic',
            groupValue: _selectedSkill,
            onChanged: (value) {
              setState(() {
                _selectedSkill = value!;
              });
            },
            title: const Text('Magic'),
            secondary: const FaIcon(FontAwesomeIcons.magic),
          ),
          const SizedBox(height: 20),
          const Text('Allocate Your Stats (1-5):'),
          _buildStatSlider('Strength', _strength, (value) {
            setState(() {
              _strength = value;
            });
          }),
          _buildStatSlider('Dexterity', _dexterity, (value) {
            setState(() {
              _dexterity = value;
            });
          }),
          _buildStatSlider('Intelligence', _intelligence, (value) {
            setState(() {
              _intelligence = value;
            });
          }),
          const SizedBox(height: 30),
          Center(
            child: ElevatedButton(
              onPressed: () {
                if (_nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Name cannot be empty!')),
                  );
                  return;
                }
                _saveCharacterToFirestore();
              },
              child: const Text('Create Character'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageCharactersTab() {
    if (_currentUser == null) {
      return const Center(
        child: Text('No user logged in. Please log in first.'),
      );
    }

    final CollectionReference characterCollection =
        FirebaseFirestore.instance.collection('characters');

    return StreamBuilder(
      // Filter characters by the current user's UID
      stream: characterCollection
          .where('uid', isEqualTo: _currentUser!.uid)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No characters found.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot doc = snapshot.data!.docs[index];
            return ListTile(
              leading: _buildAvatar(doc['avatar']),
              title: Text(doc['name']),
              subtitle: Text('Class: ${doc['class']} | Race: ${doc['race']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      _editCharacter(context, doc);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () async {
                      await characterCollection.doc(doc.id).delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Character deleted successfully!')),
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

  Widget _buildAvatar(String avatarData) {
    return avatarData.isNotEmpty
        ? SvgPicture.string(
            avatarData,
            height: 60,
            width: 60,
          )
        : const Icon(Icons.person, size: 60);
  }

  Widget _buildStatSlider(
      String label, double value, ValueChanged<double> onChanged) {
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

  void _showCustomizerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.8,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.all(16.0),
              child: FluttermojiCustomizer(
                theme: FluttermojiThemeData(
                  iconColor: Colors.white,
                  selectedIconColor: const Color.fromARGB(255, 182, 182, 181),
                  selectedTileDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color.fromARGB(255, 183, 183, 183),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editCharacter(BuildContext context, DocumentSnapshot doc) {
    TextEditingController nameController =
        TextEditingController(text: doc['name']);
    String characterRace = doc['race'];
    String characterClass = doc['class'];
    String selectedSkill = doc['skill'];
    double strength = doc['strength'].toDouble();
    double dexterity = doc['dexterity'].toDouble();
    double intelligence = doc['intelligence'].toDouble();
    String? avatarData = doc['avatar']; // Load the initial avatar data

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
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        avatarData != null
                            ? SvgPicture.string(avatarData!,
                                height: 100, width: 100)
                            : const Icon(Icons.person,
                                size:
                                    100), 
                        ElevatedButton(
                          onPressed: () async {
                            // Open the avatar customizer modal
                            _showCustomizerModal(context);

                            // Fetch updated avatar data from SharedPreferences after customizer is closed
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            String? updatedAvatarData =
                                prefs.getString('fluttermoji');

                            // Update avatar in the modal's UI
                            setModalState(() {
                              avatarData = updatedAvatarData;
                            });
                          },
                          child: const Text('Edit Avatar'),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                              labelText: 'Character Name'),
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: characterRace,
                          decoration: const InputDecoration(
                            labelText: 'Character Race',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Human', 'Elf', 'Dwarf', 'Orc']
                              .map((String race) {
                            return DropdownMenuItem<String>(
                              value: race,
                              child: Text(race),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              characterRace = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        DropdownButtonFormField<String>(
                          value: characterClass,
                          decoration: const InputDecoration(
                            labelText: 'Character Class',
                            border: OutlineInputBorder(),
                          ),
                          items: ['Warrior', 'Mage', 'Rogue', 'Cleric']
                              .map((String charClass) {
                            return DropdownMenuItem<String>(
                              value: charClass,
                              child: Text(charClass),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setModalState(() {
                              characterClass = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text('Choose Your Skill:'),
                        RadioListTile<String>(
                          value: 'Swordsmanship',
                          groupValue: selectedSkill,
                          onChanged: (value) {
                            setModalState(() {
                              selectedSkill = value!;
                            });
                          },
                          title: const Text('Swordsmanship'),
                          secondary: const FaIcon(FontAwesomeIcons.fistRaised),
                        ),
                        RadioListTile<String>(
                          value: 'Archery',
                          groupValue: selectedSkill,
                          onChanged: (value) {
                            setModalState(() {
                              selectedSkill = value!;
                            });
                          },
                          title: const Text('Archery'),
                          secondary: const FaIcon(FontAwesomeIcons.bullseye),
                        ),
                        RadioListTile<String>(
                          value: 'Magic',
                          groupValue: selectedSkill,
                          onChanged: (value) {
                            setModalState(() {
                              selectedSkill = value!;
                            });
                          },
                          title: const Text('Magic'),
                          secondary: const FaIcon(FontAwesomeIcons.magic),
                        ),
                        const SizedBox(height: 20),
                        const Text('Allocate Your Stats (1-5):'),
                        _buildStatSlider('Strength', strength, (value) {
                          setModalState(() {
                            strength = value;
                          });
                        }),
                        _buildStatSlider('Dexterity', dexterity, (value) {
                          setModalState(() {
                            dexterity = value;
                          });
                        }),
                        _buildStatSlider('Intelligence', intelligence, (value) {
                          setModalState(() {
                            intelligence = value;
                          });
                        }),
                        const SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseFirestore.instance
                                .collection('characters')
                                .doc(doc.id)
                                .update({
                              'name': nameController.text,
                              'race': characterRace,
                              'class': characterClass,
                              'skill': selectedSkill,
                              'strength': strength.toInt(),
                              'dexterity': dexterity.toInt(),
                              'intelligence': intelligence.toInt(),
                              'avatar': avatarData ??
                                  doc['avatar'], 
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
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
