import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs: feedback form and previous feedback
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Give Feedback'),
            Tab(text: 'Previous Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FeedbackForm(),  // Tab 1: Feedback Form
          PreviousFeedback(),  // Tab 2: Previous Feedback List
        ],
      ),
    );
  }
}

// Feedback Form Widget
class FeedbackForm extends StatefulWidget {
  const FeedbackForm({super.key});

  @override
  _FeedbackFormState createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedStarRating = 0;
  final List<String> _improvementOptions = [
    'Overall Service',
    'Customer Support',
    'Speed and Efficiency',
    'Repair Quality',
    'Pickup and Delivery Service',
    'Transparency'
  ];
  final List<String> _selectedImprovements = [];
  final CollectionReference feedbackCollection = FirebaseFirestore.instance.collection('feedbacks');
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Get the current user
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    final feedbackText = _feedbackController.text;
    final selectedImprovements = _selectedImprovements.join(', ');

    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit feedback.')),
      );
      return;
    }

    if (feedbackText.isNotEmpty && _selectedStarRating > 0) {
      await feedbackCollection.add({
        'uid': _currentUser!.uid, // Save the user's UID
        'rating': _selectedStarRating,
        'improvements': selectedImprovements,
        'feedback': feedbackText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );

      _feedbackController.clear();
      setState(() {
        _selectedStarRating = 0;
        _selectedImprovements.clear();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields before submitting!')),
      );
    }
  }

  void _toggleImprovement(String improvement) {
    setState(() {
      if (_selectedImprovements.contains(improvement)) {
        _selectedImprovements.remove(improvement);
      } else {
        _selectedImprovements.add(improvement);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text(
            'Rate Your Experience',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _selectedStarRating = index + 1;
                  });
                },
                icon: Icon(
                  index < _selectedStarRating ? Icons.star : Icons.star_border,
                  size: 40,
                ),
              );
            }),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tell us what can be improved:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: _improvementOptions.map((improvement) {
              final bool isSelected = _selectedImprovements.contains(improvement);
              return ChoiceChip(
                label: Text(improvement),
                selected: isSelected,
                onSelected: (selected) {
                  _toggleImprovement(improvement);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _feedbackController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Tell us how we can improve...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _submitFeedback,
            child: const Text('Submit Feedback'),
          ),
        ],
      ),
    );
  }
}

// Previous Feedback List Widget
class PreviousFeedback extends StatefulWidget {
  const PreviousFeedback({super.key});

  @override
  _PreviousFeedbackState createState() => _PreviousFeedbackState();
}

class _PreviousFeedbackState extends State<PreviousFeedback> {
  final CollectionReference feedbackCollection = FirebaseFirestore.instance.collection('feedbacks');
  User? _currentUser;
  String? _editingDocId;  // To track which document is being edited

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser; // Get the current user
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Center(
        child: Text('Please log in to view your feedback.'),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder(
        stream: feedbackCollection
            .where('uid', isEqualTo: _currentUser!.uid) // Filter by the logged-in user's UID
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No feedbacks found.'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              DocumentSnapshot doc = snapshot.data!.docs[index];
              bool isEditing = _editingDocId == doc.id;

              return Column(
                children: [
                  ListTile(
                    title: Text('Rating: ${doc['rating']} stars'),
                    subtitle: Text('Feedback: ${doc['feedback']}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            setState(() {
                              _editingDocId = _editingDocId == doc.id ? null : doc.id;
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () async {
                            await feedbackCollection.doc(doc.id).delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Feedback deleted successfully!')),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  if (isEditing)
                    _EditFeedbackWidget(
                      doc: doc,
                      onClose: () {
                        setState(() {
                          _editingDocId = null;
                        });
                      },
                    ),
                  const Divider(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

// Edit Feedback Widget
class _EditFeedbackWidget extends StatefulWidget {
  final DocumentSnapshot doc;
  final VoidCallback onClose;

  const _EditFeedbackWidget({required this.doc, required this.onClose});

  @override
  __EditFeedbackWidgetState createState() => __EditFeedbackWidgetState();
}

class __EditFeedbackWidgetState extends State<_EditFeedbackWidget> {
  final TextEditingController _feedbackController = TextEditingController();
  int _selectedStarRating = 0;
  List<String> _selectedImprovements = [];

  @override
  void initState() {
    super.initState();
    _feedbackController.text = widget.doc['feedback'];
    _selectedStarRating = widget.doc['rating'];
    _selectedImprovements = widget.doc['improvements'].split(', ');
  }

  Future<void> _updateFeedback() async {
    final updatedFeedbackText = _feedbackController.text;
    final updatedImprovements = _selectedImprovements.join(', ');

    if (updatedFeedbackText.isNotEmpty && _selectedStarRating > 0) {
      await FirebaseFirestore.instance.collection('feedbacks').doc(widget.doc.id).update({
        'rating': _selectedStarRating,
        'improvements': updatedImprovements,
        'feedback': updatedFeedbackText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback updated successfully!')),
      );

      widget.onClose();  // Trigger collapse of the widget after saving
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields before submitting!')),
      );
    }
  }

  void _toggleImprovement(String improvement) {
    setState(() {
      if (_selectedImprovements.contains(improvement)) {
        _selectedImprovements.remove(improvement);
      } else {
        _selectedImprovements.add(improvement);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<String> improvementOptions = [
      'Overall Service',
      'Customer Support',
      'Speed and Efficiency',
      'Repair Quality',
      'Pickup and Delivery Service',
      'Transparency'
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          const Text(
            'Edit Your Feedback',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                onPressed: () {
                  setState(() {
                    _selectedStarRating = index + 1;
                  });
                },
                icon: Icon(
                  index < _selectedStarRating ? Icons.star : Icons.star_border,
                  size: 30,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: improvementOptions.map((improvement) {
              final bool isSelected = _selectedImprovements.contains(improvement);
              return ChoiceChip(
                label: Text(improvement),
                selected: isSelected,
                onSelected: (selected) {
                  _toggleImprovement(improvement);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _feedbackController,
            maxLines: 4,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Update your feedback...',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _updateFeedback,
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}
