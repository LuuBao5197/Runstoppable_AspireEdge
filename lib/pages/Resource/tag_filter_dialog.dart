import 'package:flutter/material.dart';

class TagFilterDialog extends StatefulWidget {
  final List<String> allTags;
  final Map<String, int> currentSelection;

  const TagFilterDialog({
    super.key,
    required this.allTags,
    required this.currentSelection,
  });

  @override
  State<TagFilterDialog> createState() => _TagFilterDialogState();
}

class _TagFilterDialogState extends State<TagFilterDialog> {
  late Map<String, int> selectedTags;

  @override
  void initState() {
    super.initState();
    // clone để không ảnh hưởng trực tiếp
    selectedTags = Map<String, int>.from(widget.currentSelection);
  }

  void toggleTag(String tag) {
    setState(() {
      if (selectedTags[tag] == 0) {
        selectedTags[tag] = 1; // include
      } else if (selectedTags[tag] == 1) {
        selectedTags[tag] = -1; // exclude
      } else {
        selectedTags[tag] = 0; // reset
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Filter Blogs"),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2, // chỉnh 2 hoặc 3 cột cho cân
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 3.5, // chỉnh chiều ngang/dọc chip
          children: widget.allTags.map((tag) {
            int state = selectedTags[tag] ?? 0;

            Color bg;
            Color textColor = Colors.black;
            if (state == 1) {
              bg = Colors.green.shade100;
              textColor = Colors.green.shade800;
            } else if (state == -1) {
              bg = Colors.red.shade100;
              textColor = Colors.red.shade800;
            } else {
              bg = Colors.grey.shade200;
              textColor = Colors.black87;
            }

            return ChoiceChip(
              label: Text(tag, style: TextStyle(color: textColor)),
              selected: state != 0,
              backgroundColor: Colors.grey.shade200,
              selectedColor: bg,
              onSelected: (_) => toggleTag(tag),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedTags),
          child: const Text("Apply"),
        ),
      ],
    );
  }
}
