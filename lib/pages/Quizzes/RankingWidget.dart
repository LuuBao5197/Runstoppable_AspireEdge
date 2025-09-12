// lib/RankingWidget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'QuizState.dart'; // Import QuizState

class RankingWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  const RankingWidget({super.key, required this.question});

  @override
  State<RankingWidget> createState() => _RankingWidgetState();
}

class _RankingWidgetState extends State<RankingWidget> {
  late List<dynamic> _options;

  @override
  void initState() {
    super.initState();
    _options = List.from(widget.question['options']);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ReorderableListView.builder(
            itemCount: _options.length,
            itemBuilder: (context, index) {
              final option = _options[index];
              return Card(
                key: ValueKey(option['optionId']),
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(option['optionText']),
                  trailing: Icon(Icons.drag_handle),
                ),
              );
            },
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final item = _options.removeAt(oldIndex);
                _options.insert(newIndex, item);
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
            ),
            onPressed: () {
              // === THAY ĐỔI Ở ĐÂY ===
              // Gửi `_options` (đã được sắp xếp) về cho QuizState
              context.read<QuizState>().answerRanking(_options);
            },
            child: Text("Submit Answer"),
          ),
        ),
      ],
    );
  }
}