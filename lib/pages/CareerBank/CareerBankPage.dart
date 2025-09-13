import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'career_detail_page.dart';

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
        backgroundColor: Colors.white,
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
                  ? FirebaseFirestore.instance.collection("careers").snapshots()
                  : FirebaseFirestore.instance
                  .collection("careers")
                  .where("industry", isEqualTo: selectedIndustry)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No careers available"));
                }

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
                  return const Center(
                      child: Text("No careers match your search"));
                }

                return ListView.builder(
                  itemCount: careers.length,
                  itemBuilder: (context, index) {
                    final data = careers[index].data() as Map<String, dynamic>;

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CareerDetailPage(data: data),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.all(10),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image
                            if (data["imageUrl"] != null &&
                                data["imageUrl"].toString().isNotEmpty)
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(12)),
                                child: Image.network(
                                  data["imageUrl"],
                                  width: double.infinity,
                                  height: 180,
                                  fit: BoxFit.cover,
                                ),
                              )
                            else
                              const SizedBox(
                                height: 180,
                                child: Center(
                                  child: Icon(Icons.work,
                                      size: 80, color: Colors.blueAccent),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data["title"] ?? "",
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    data["description"] ?? "",
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
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
