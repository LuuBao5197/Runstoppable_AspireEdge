import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

// Các model đơn giản để quản lý state của form, có thêm hàm dispose để dọn dẹp
class AnswerModel {
  TextEditingController textController = TextEditingController();
  Map<String, TextEditingController> scoreControllers = {
    'realistic': TextEditingController(text: '0'),
    'investigative': TextEditingController(text: '0'),
    'artistic': TextEditingController(text: '0'),
    'social': TextEditingController(text: '0'),
    'enterprising': TextEditingController(text: '0'),
    'conventional': TextEditingController(text: '0'),
  };

  void dispose() {
    textController.dispose();
    scoreControllers.forEach((_, controller) => controller.dispose());
  }
}

class OptionModel {
  TextEditingController textController = TextEditingController();
  String category = 'realistic';

  void dispose() {
    textController.dispose();
  }
}

// Màn hình chính
class QuestionEditScreen extends StatefulWidget {
  final String? questionId;
  const QuestionEditScreen({super.key, this.questionId});

  bool get isEditing => questionId != null;

  @override
  State<QuestionEditScreen> createState() => _QuestionEditScreenState();
}

class _QuestionEditScreenState extends State<QuestionEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true; // Bắt đầu bằng true để tải dữ liệu
  bool _isSaving = false;

  final _questionTextController = TextEditingController();
  String _questionType = 'multiple-choice';

  List<AnswerModel> _answers = [];
  List<OptionModel> _options = [];

  final List<String> _categories = ['realistic', 'investigative', 'artistic', 'social', 'enterprising', 'conventional'];

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadQuestionData();
    } else {
      // Chế độ "Thêm mới", khởi tạo với 1 lựa chọn rỗng
      setState(() {
        _answers = [AnswerModel()];
        _options = [OptionModel()];
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // Dọn dẹp controllers để tránh rò rỉ bộ nhớ
    _questionTextController.dispose();
    for (var answer in _answers) {
      answer.dispose();
    }
    for (var option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuestionData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('questions').doc(widget.questionId).get();
      if (doc.exists) {
        final data = doc.data()!;
        _questionTextController.text = data['questionText'];
        _questionType = data['questionType'];

        if (_questionType == 'multiple-choice') {
          final List<dynamic> answerData = data['answers'] ?? [];
          _answers = answerData.map((a) {
            final model = AnswerModel();
            model.textController.text = a['answerText'];
            (a['scores'] as Map<String, dynamic>).forEach((key, value) {
              model.scoreControllers[key]?.text = value.toString();
            });
            return model;
          }).toList();
        } else { // ranking
          final List<dynamic> optionData = data['options'] ?? [];
          _options = optionData.map((o) {
            final model = OptionModel();
            model.textController.text = o['optionText'];
            model.category = o['category'];
            return model;
          }).toList();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error loading data: $e"), backgroundColor: Colors.red));
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  // Thay thế hàm _saveQuestion hiện tại của bạn bằng hàm này

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      print("Form is not valid");
      return;
    }

    setState(() { _isSaving = true; });

    // Khai báo biến dataToSave ở đây
    Map<String, dynamic> dataToSave;

    // Xây dựng đối tượng dataToSave dựa trên questionType
    if (_questionType == 'multiple-choice') {
      dataToSave = {
        'questionType': _questionType,
        'questionText': _questionTextController.text,
        'answers': _answers.map((answer) => {
          'answerText': answer.textController.text,
          'scores': answer.scoreControllers.map((key, ctrl) => MapEntry(key, int.tryParse(ctrl.text) ?? 0)),
        }).toList(),
        // Đảm bảo không gửi trường 'options' rỗng hoặc không liên quan
      };
    } else { // ranking
      dataToSave = {
        'questionType': _questionType,
        'questionText': _questionTextController.text,
        'options': _options.map((option) => {
          'optionId': 'rank_${option.textController.text.toLowerCase().replaceAll(' ', '_')}',
          'optionText': option.textController.text,
          'category': option.category,
        }).toList(),
        // Đảm bảo không gửi trường 'answers' rỗng hoặc không liên quan
      };
    }

    try {
      final functions = FirebaseFunctions.instance;
      final functionName = widget.isEditing ? 'updateQuestion' : 'addNewQuestion';
      final callable = functions.httpsCallable(functionName);

      // Thêm questionId nếu là chế độ Sửa
      if (widget.isEditing) {
        dataToSave['questionId'] = widget.questionId;
      }

      print("Data being sent to Cloud Function '$functionName': $dataToSave"); // Dòng debug quan trọng

      final result = await callable.call(dataToSave);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.data['message'] ?? 'Successfully saved!'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop();
      }

    } on FirebaseFunctionsException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error from function: ${e.message}'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected client error occurred: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() { _isSaving = false; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Question' : 'Add Question'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _isSaving ? null : _saveQuestion,
            tooltip: 'Save Question',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonFormField<String>(
                value: _questionType,
                decoration: const InputDecoration(labelText: 'Question Type', border: OutlineInputBorder()),
                items: ['multiple-choice', 'ranking'].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => setState(() => _questionType = value!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _questionTextController,
                decoration: const InputDecoration(labelText: 'Question Text', border: OutlineInputBorder()),
                validator: (value) => (value == null || value.isEmpty) ? 'Required field' : null,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              if (_questionType == 'multiple-choice')
                _buildMultipleChoiceFields()
              else
                _buildRankingFields(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Answers', style: Theme.of(context).textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _answers.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _answers[index].textController,
                      decoration: InputDecoration(labelText: 'Answer Text ${index + 1}'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 8),
                    const Text('Scores:'),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _categories.map((cat) {
                        return SizedBox(
                          width: 100,
                          child: TextFormField(
                            controller: _answers[index].scoreControllers[cat],
                            decoration: InputDecoration(labelText: cat),
                            keyboardType: TextInputType.number,
                          ),
                        );
                      }).toList(),
                    ),
                    if (_answers.length > 1)
                      Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => setState(() => _answers.removeAt(index)),
                        ),
                      )
                  ],
                ),
              ),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Answer'),
          onPressed: () => setState(() => _answers.add(AnswerModel())),
        ),
      ],
    );
  }

  Widget _buildRankingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Options to Rank', style: Theme.of(context).textTheme.titleLarge),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _options.length,
          itemBuilder: (context, index) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _options[index].textController,
                        decoration: InputDecoration(labelText: 'Option Text ${index + 1}'),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _options[index].category,
                      items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                      onChanged: (val) => setState(() => _options[index].category = val!),
                    ),
                    if (_options.length > 1)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => setState(() => _options.removeAt(index)),
                      )
                  ],
                ),
              ),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Add Option'),
          onPressed: () => setState(() => _options.add(OptionModel())),
        ),
      ],
    );
  }
}