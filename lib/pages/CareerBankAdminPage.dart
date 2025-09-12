import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';

import '../services/career_firebase_service.dart';
import '../models/career_models.dart';

class CareerBankAdminPage extends StatelessWidget {
  const CareerBankAdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CareerBank - Admin"),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showCareerDialog(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Career'),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: CareerFirebaseService.getAllCareers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No careers found'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final career = CareerBank.fromFirestore(doc);

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: career.imageUrl != null && career.imageUrl!.isNotEmpty
                            ? Image.network(
                          career.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                            : const Icon(Icons.work, color: Colors.teal),
                        title: Text(career.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Industry: ${career.industry}"),
                            Text("Salary: ${career.salaryRange}"),
                            Text("Skills: ${career.skills.join(", ")}"),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.orange),
                              onPressed: () {
                                _showCareerDialog(context, career: career, docId: doc.id);
                              },
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

  /// Dùng chung cho CREATE và UPDATE
  void _showCareerDialog(BuildContext context, {CareerBank? career, String? docId}) {
    final titleController = TextEditingController(text: career?.title ?? "");
    final descriptionController = TextEditingController(text: career?.description ?? "");
    final skillsController = TextEditingController(text: career?.skills.join(", ") ?? "");
    final salaryController = TextEditingController(text: career?.salaryRange ?? "");

    final degreeController = TextEditingController(text: career?.educationPath?.degree ?? "");
    final coursesController = TextEditingController(text: career?.educationPath?.courses.join(", ") ?? "");
    final certificatesController = TextEditingController(text: career?.educationPath?.certificates.join(", ") ?? "");
    final durationController = TextEditingController(text: career?.educationPath?.duration ?? "");
    final levelController = TextEditingController(text: career?.educationPath?.careerLevel ?? "");
    final costController = TextEditingController(text: career?.educationPath?.estimatedCost ?? "");

    final cloudinary = CloudinaryPublic('dbghucaix', 'ml_default');
    final ImagePicker picker = ImagePicker();

    String? uploadedImageUrl = career?.imageUrl;
    final List<String> industries = [
      "Technology – Engineering",
      "Economics – Management",
      "Healthcare",
      "Education – Teaching",
      "Agriculture – Forestry – Fishery",
      "Culture – Arts – Tourism",
      "Law – Security – Defense",
      "General Labor – Services",
    ];
    String? selectedIndustry = career?.industry;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(career == null ? 'Create New Career' : 'Update Career'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<String>(
                    value: selectedIndustry,
                    decoration: const InputDecoration(labelText: "Industry"),
                    items: industries.map((industry) {
                      return DropdownMenuItem<String>(
                        value: industry,
                        child: Text(industry),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedIndustry = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8),

                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
                  TextField(controller: skillsController, decoration: const InputDecoration(labelText: 'Skills (comma separated)')),
                  TextField(controller: salaryController, decoration: const InputDecoration(labelText: 'Salary Range')),

                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cloud_upload),
                        label: const Text("Upload Image"),
                        onPressed: () async {
                          final img = await picker.pickImage(source: ImageSource.gallery);
                          if (img == null) return;

                          final res = await cloudinary.uploadFile(
                            CloudinaryFile.fromFile(img.path),
                          );

                          uploadedImageUrl = res.secureUrl;
                          setState(() {});
                        },
                      ),
                      const SizedBox(width: 10),
                      if (uploadedImageUrl != null)
                        const Icon(Icons.check_circle, color: Colors.green),
                    ],
                  ),

                  const Divider(),
                  const Text("Education Path", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(controller: degreeController, decoration: const InputDecoration(labelText: 'Degree')),
                  TextField(controller: coursesController, decoration: const InputDecoration(labelText: 'Courses (comma separated)')),
                  TextField(controller: certificatesController, decoration: const InputDecoration(labelText: 'Certificates (comma separated)')),
                  TextField(controller: durationController, decoration: const InputDecoration(labelText: 'Duration')),
                  TextField(controller: levelController, decoration: const InputDecoration(labelText: 'Career Level')),
                  TextField(controller: costController, decoration: const InputDecoration(labelText: 'Estimated Cost')),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final newCareer = CareerBank(
                      careerId: docId ?? "",
                      title: titleController.text,
                      industry: selectedIndustry ?? "",
                      description: descriptionController.text,
                      skills: skillsController.text.split(',').map((s) => s.trim()).toList(),
                      salaryRange: salaryController.text,
                      imageUrl: uploadedImageUrl ?? "",
                      createdAt: career?.createdAt ?? DateTime.now(), // giữ createdAt cũ nếu update
                      updatedAt: DateTime.now(),
                      educationPath: EducationPath(
                        degree: degreeController.text,
                        courses: coursesController.text.split(',').map((s) => s.trim()).toList(),
                        certificates: certificatesController.text.split(',').map((s) => s.trim()).toList(),
                        duration: durationController.text,
                        careerLevel: levelController.text,
                        estimatedCost: costController.text,
                      ),
                    );

                    if (career == null) {
                      await CareerFirebaseService.createCareer(
                        title: newCareer.title,
                        industry: newCareer.industry,
                        description: newCareer.description,
                        skills: newCareer.skills,
                        salaryRange: newCareer.salaryRange,
                        imageUrl: newCareer.imageUrl ?? "",
                        educationPath: newCareer.educationPath,
                      );
                    } else {
                      await CareerFirebaseService.updateCareer(docId!, newCareer);
                    }

                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(career == null ? 'Career created!' : 'Career updated!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: Text(career == null ? 'Create' : 'Update'),
              ),
            ],
          );
        },
      ),
    );
  }
}
