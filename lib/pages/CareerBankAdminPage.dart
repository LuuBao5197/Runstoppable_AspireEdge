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

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.teal, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  void _showCareerDialog(BuildContext context, {CareerBank? career, String? docId}) {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(text: career?.title ?? "");
    final descriptionController = TextEditingController(text: career?.description ?? "");
    final skillsController = TextEditingController(text: career?.skills.join(", ") ?? "");
    final salaryController = TextEditingController(text: career?.salaryRange ?? "");

    final degreeController = TextEditingController(text: career?.educationPath?.degree ?? "");
    final coursesController = TextEditingController(text: career?.educationPath?.courses?.join(", ") ?? "");
    final certificatesController = TextEditingController(text: career?.educationPath?.certificates?.join(", ") ?? "");
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              career == null ? 'Create New Career' : 'Update Career',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // General Info
                    const Text("General Info", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: titleController,
                      decoration: _inputDecoration("Title"),
                      validator: (v) => v == null || v.isEmpty ? "Title is required" : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedIndustry,
                      decoration: _inputDecoration("Industry"),
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
                      validator: (value) => value == null || value.isEmpty ? 'Industry is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: descriptionController,
                      maxLines: 3,
                      decoration: _inputDecoration("Description"),
                      validator: (v) => v == null || v.isEmpty ? "Description is required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: skillsController,
                      decoration: _inputDecoration("Skills (comma separated)"),
                      validator: (v) => v == null || v.isEmpty ? "Skills are required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: salaryController,
                      decoration: _inputDecoration("Salary Range"),
                      validator: (v) => v == null || v.isEmpty ? "Salary is required" : null,
                    ),
                    const SizedBox(height: 16),

                    // Upload Image
                    Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
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
                        const SizedBox(width: 12),
                        if (uploadedImageUrl != null && uploadedImageUrl!.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              uploadedImageUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                      ],
                    ),
                    if (uploadedImageUrl == null || uploadedImageUrl!.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text("Image is required", style: TextStyle(color: Colors.red, fontSize: 12)),
                      ),
                    const Divider(height: 30),

                    // Education Path
                    const Text("Education Path", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: degreeController,
                      decoration: _inputDecoration("Degree"),
                      validator: (v) => v == null || v.isEmpty ? "Degree is required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: coursesController,
                      decoration: _inputDecoration("Courses (comma separated)"),
                      validator: (v) => v == null || v.isEmpty ? "Courses are required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: certificatesController,
                      decoration: _inputDecoration("Certificates (comma separated)"),
                      validator: (v) => v == null || v.isEmpty ? "Certificates are required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: durationController,
                      decoration: _inputDecoration("Duration"),
                      validator: (v) => v == null || v.isEmpty ? "Duration is required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: levelController,
                      decoration: _inputDecoration("Career Level"),
                      validator: (v) => v == null || v.isEmpty ? "Career Level is required" : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: costController,
                      decoration: _inputDecoration("Estimated Cost"),
                      validator: (v) => v == null || v.isEmpty ? "Estimated Cost is required" : null,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;
                  if (uploadedImageUrl == null || uploadedImageUrl!.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please upload an image')),
                    );
                    return;
                  }

                  try {
                    final newCareer = CareerBank(
                      careerId: docId ?? "",
                      title: titleController.text,
                      industry: selectedIndustry ?? "",
                      description: descriptionController.text,
                      skills: skillsController.text.split(',').map((s) => s.trim()).toList(),
                      salaryRange: salaryController.text,
                      imageUrl: uploadedImageUrl ?? "",
                      createdAt: career?.createdAt ?? DateTime.now(),
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
