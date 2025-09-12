import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareerBankPage extends StatefulWidget {
  const CareerBankPage({super.key});

  @override
  State<CareerBankPage> createState() => _CareerBankPageState();
}

class _CareerBankPageState extends State<CareerBankPage> {
  String selectedIndustry = "All";
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Career Bank"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Dropdown filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedIndustry,
              isExpanded: true,
              items: [
                "All",
                "Technology – Engineering",
                "Economics – Management",
                "Healthcare",
                "Education – Teaching",
                "Agriculture – Forestry – Fishery",
                "Culture – Arts – Tourism",
                "Law – Security – Defense",
                "General Labor – Services",
              ]
                  .map((industry) => DropdownMenuItem(
                value: industry,
                child: Text(industry),
              ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedIndustry = value!;
                });
              },
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search career...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      searchQuery = "";
                    });
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Career list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedIndustry == "All"
                  ? FirebaseFirestore.instance
                  .collectionGroup("careers") // ✅ all subcollections
                  .snapshots()
                  : FirebaseFirestore.instance
                  .collection("CareerBank")
                  .doc(selectedIndustry)
                  .collection("careers")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No careers available"));
                }

                // Filter search
                final careers = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final title = (data["title"] ?? "").toString().toLowerCase();
                  final description =
                  (data["description"] ?? "").toString().toLowerCase();
                  return searchQuery.isEmpty ||
                      title.contains(searchQuery) ||
                      description.contains(searchQuery);
                }).toList();

                if (careers.isEmpty) {
                  return const Center(child: Text("No careers match your search"));
                }

                return ListView.builder(
                  itemCount: careers.length,
                  itemBuilder: (context, index) {
                    final data = careers[index].data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.all(8),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data["title"] ?? "",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueAccent,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(data["description"] ?? ""),
                            const SizedBox(height: 8),
                            if (data["skills"] != null)
                              Text("💡 Skills: ${(data["skills"] as List<dynamic>).join(", ")}"),
                            const SizedBox(height: 4),
                            Text("💰 Salary: ${data["salary"] ?? ""}"),
                            const SizedBox(height: 4),
                            const Text("🎓 Education Path:"),
                            if (data["education_path"] != null) ...[
                              Text("   - Degree: ${data["education_path"]["degree"] ?? ""}"),
                              Text("   - Courses: ${(data["education_path"]["courses"] as List<dynamic>?)?.join(', ') ?? ""}"),
                              Text("   - Certificates: ${(data["education_path"]["certificates"] as List<dynamic>?)?.join(', ') ?? ""}"),
                              Text("   - Duration: ${data["education_path"]["duration"] ?? ""}"),
                              Text("   - Level: ${data["education_path"]["career_level"] ?? ""}"),
                              Text("   - Cost: ${data["education_path"]["estimated_cost"] ?? ""}"),
                            ]
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
