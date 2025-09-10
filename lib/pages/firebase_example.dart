import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/firebase_models.dart';

class FirebaseExamplePage extends StatefulWidget {
  const FirebaseExamplePage({super.key});

  @override
  State<FirebaseExamplePage> createState() => _FirebaseExamplePageState();
}

class _FirebaseExamplePageState extends State<FirebaseExamplePage> {
  final TextEditingController _moodController = TextEditingController();
  final TextEditingController _diaryTitleController = TextEditingController();
  final TextEditingController _diaryContentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('Vui lòng đăng nhập để sử dụng Firebase'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Models Example'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ==================== MOOD ENTRY SECTION ====================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mood Entry',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _moodController,
                      decoration: const InputDecoration(
                        labelText: 'Mood Note (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _addMoodEntry(user.uid, 5, 'happy'),
                          child: const Text('Happy 😊'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addMoodEntry(user.uid, 3, 'neutral'),
                          child: const Text('Neutral 😐'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _addMoodEntry(user.uid, 1, 'sad'),
                          child: const Text('Sad 😢'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ==================== DIARY ENTRY SECTION ====================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Diary Entry',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diaryTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _diaryContentController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _addDiaryEntry,
                      child: const Text('Add Diary Entry'),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ==================== MOOD ENTRIES LIST ====================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Mood Entries',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseService.getMoodEntries(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No mood entries yet');
                        }
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final moodEntry = MoodEntry.fromFirestore(doc);
                            
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getMoodColor(moodEntry.moodType),
                                child: Text(_getMoodEmoji(moodEntry.moodType)),
                              ),
                              title: Text('Score: ${moodEntry.moodScore}'),
                              subtitle: Text(moodEntry.note ?? 'No note'),
                              trailing: Text(
                                '${moodEntry.createdAt.day}/${moodEntry.createdAt.month}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // ==================== DIARY ENTRIES LIST ====================
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Diary Entries',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseService.getDiaryEntries(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No diary entries yet');
                        }
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: snapshot.data!.docs.length,
                          itemBuilder: (context, index) {
                            final doc = snapshot.data!.docs[index];
                            final diaryEntry = DiaryEntry.fromFirestore(doc);
                            
                            return ListTile(
                              leading: const Icon(Icons.book),
                              title: Text(diaryEntry.title),
                              subtitle: Text(
                                diaryEntry.content.length > 50 
                                    ? '${diaryEntry.content.substring(0, 50)}...'
                                    : diaryEntry.content,
                              ),
                              trailing: Text(
                                '${diaryEntry.createdAt.day}/${diaryEntry.createdAt.month}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addMoodEntry(String userId, int score, String type) async {
    try {
      await FirebaseService.addMoodEntry(
        userId: userId,
        moodScore: score,
        moodType: type,
        note: _moodController.text.isNotEmpty ? _moodController.text : null,
        tags: ['daily', type],
      );
      
      _moodController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mood entry added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _addDiaryEntry() async {
    if (_diaryTitleController.text.isEmpty || _diaryContentController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and content')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser!;
      await FirebaseService.addDiaryEntry(
        userId: user.uid,
        title: _diaryTitleController.text,
        content: _diaryContentController.text,
        tags: ['personal'],
      );
      
      _diaryTitleController.clear();
      _diaryContentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Diary entry added successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _getMoodColor(String moodType) {
    switch (moodType) {
      case 'happy': return Colors.green;
      case 'neutral': return Colors.orange;
      case 'sad': return Colors.blue;
      default: return Colors.grey;
    }
  }

  String _getMoodEmoji(String moodType) {
    switch (moodType) {
      case 'happy': return '😊';
      case 'neutral': return '😐';
      case 'sad': return '😢';
      default: return '😶';
    }
  }
}
