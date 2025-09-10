import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareerBankPage extends StatefulWidget {
  const CareerBankPage({super.key});

  @override
  State<CareerBankPage> createState() => _CareerBankPageState();
}

class _CareerBankPageState extends State<CareerBankPage> {
  String selectedIndustry = "Tất cả";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ngân hàng nghề nghiệp"),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Dropdown lọc ngành
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: selectedIndustry,
              isExpanded: true,
              items: ["Tất cả", "CNTT", "Y tế", "Thiết kế", "Nông nghiệp"]
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

          // StreamBuilder để lấy dữ liệu Firestore
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("CareerBank")
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có nghề nghiệp nào"));
                }

                // Lọc dữ liệu theo ngành
                final careers = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return selectedIndustry == "Tất cả" ||
                      data["industry"] == selectedIndustry;
                }).toList();

                return ListView.builder(
                  itemCount: careers.length,
                  itemBuilder: (context, index) {
                    final data =
                    careers[index].data() as Map<String, dynamic>;

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
                            Text(
                                "💡 Kỹ năng: ${(data["skills"] as List<dynamic>).join(", ")}"),
                            const SizedBox(height: 4),
                            Text("💰 Lương: ${data["salaryRange"] ?? ""}"),
                            const SizedBox(height: 4),
                            const Text("🎓 Con đường giáo dục:"),
                            for (var edu in data["educationPath"] ?? [])
                              Text("   - $edu"),
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
