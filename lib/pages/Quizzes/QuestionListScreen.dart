import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'QuestionEditScreen.dart';

class QuestionListScreen extends StatefulWidget {
  const QuestionListScreen({super.key});

  @override
  State<QuestionListScreen> createState() => _QuestionListScreenState();
}

class _QuestionListScreenState extends State<QuestionListScreen> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot> _allQuestions = []; // Lưu trữ toàn bộ câu hỏi
  List<QueryDocumentSnapshot> _filteredQuestions = []; // Lưu trữ danh sách đã được lọc/tìm kiếm

  final _searchController = TextEditingController();
  String? _selectedCategory;
  final List<String> _categories = ['realistic', 'investigative', 'artistic', 'social', 'enterprising', 'conventional'];

  int _currentPage = 0;
  final int _itemsPerPage = 10; // Hiển thị 10 câu hỏi mỗi trang

  @override
  void initState() {
    super.initState();
    _fetchAndPrepareData();
    _searchController.addListener(() {
      _applyFiltersAndSearch();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchAndPrepareData() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('questions').get();
      setState(() {
        _allQuestions = snapshot.docs;
        _applyFiltersAndSearch(); // Áp dụng bộ lọc ban đầu
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _isLoading = false; });
      print("Error fetching data: $e");
    }
  }

  void _applyFiltersAndSearch() {
    List<QueryDocumentSnapshot> tempQuestions = List.from(_allQuestions);

    if (_selectedCategory != null) {
      tempQuestions = tempQuestions.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Logic lọc đơn giản: Kiểm tra xem category có tồn tại trong câu hỏi không
        // (Áp dụng cho cả multiple-choice và ranking)
        if (data['questionType'] == 'ranking') {
          return (data['options'] as List).any((opt) => opt['category'] == _selectedCategory);
        } else {
          return (data['answers'] as List).any((ans) => (ans['scores'] as Map).containsKey(_selectedCategory));
        }
      }).toList();
    }

    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      tempQuestions = tempQuestions.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['questionText'].toString().toLowerCase().contains(searchText);
      }).toList();
    }

    setState(() {
      _filteredQuestions = tempQuestions;
      _currentPage = 0;
    });
  }

  void _changePage(int newPage) {
    setState(() {
      _currentPage = newPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text("Manage Questions")), body: const Center(child: CircularProgressIndicator()));
    }
    final totalItems = _filteredQuestions.length;
    final totalPages = (totalItems / _itemsPerPage).ceil();
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage > totalItems) ? totalItems : startIndex + _itemsPerPage;
    final pageItems = totalItems > 0 ? _filteredQuestions.sublist(startIndex, endIndex) : [];

    return Scaffold(
      appBar: AppBar(title: const Text("Manage Questions")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search by question text...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: _categories.map((cat) {
                    return FilterChip(
                      label: Text(cat),
                      selected: _selectedCategory == cat,
                      onSelected: (isSelected) {
                        setState(() {
                          _selectedCategory = isSelected ? cat : null;
                          _applyFiltersAndSearch();
                        });
                      },
                    );
                  }).toList(),
                )
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: pageItems.length,
              itemBuilder: (context, index) {
                final question = pageItems[index].data() as Map<String, dynamic>;
                final questionId = pageItems[index].id;

                return ListTile(
                  title: Text(question['questionText'], maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('ID: $questionId | Type: ${question['questionType']}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => QuestionEditScreen(questionId: questionId)));
                    },
                  ),
                );
              },
            ),
          ),

          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage == 0 ? null : () => _changePage(_currentPage - 1),
                  ),
                  Text('Page ${_currentPage + 1} of $totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage + 1 >= totalPages ? null : () => _changePage(_currentPage + 1),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const QuestionEditScreen(questionId: null)));
        },
        child: const Icon(Icons.add),
        tooltip: 'Add new question',
      ),
    );
  }
}