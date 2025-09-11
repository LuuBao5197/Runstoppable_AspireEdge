import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as path; // Step 1: Add path package
import 'package:cloud_functions/cloud_functions.dart'; // Step 2: Add Firebase Cloud Functions

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;
  String? _publicId; // Step 3: Variable to store publicId
  bool _isLoading = false;

  // IMPORTANT NOTE: The string 'YOUR_UNSIGNED_UPLOAD_PRESET' is not correct.
  // You must go to Cloudinary Dashboard -> Settings -> Upload -> Upload presets
  // and get the actual preset name. Example: 'unsigned_uploads'
  final cloudinary = CloudinaryPublic('dbghucaix', 'ml_default');

  // Upload image to Cloudinary
  Future<String?> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      // User canceled image selection
      return null;
    }

    setState(() {
      _isLoading = true;
      _imageUrl = null;
      _publicId = null;
    });

    try {
      // Use original filename (without extension) as publicId
      final String publicId = path.basenameWithoutExtension(image.name);

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          publicId: publicId,
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      setState(() {
        _imageUrl = response.secureUrl;
        _publicId = response.publicId;
        _isLoading = false;
      });

      print('Upload successful! Public ID: ${response.publicId}');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload successful!')),
      );

      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Upload error: ${e.message}');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.message}')),
      );
      return null;
    }
  }

  // Call Firebase Cloud Function to delete the image
  Future<void> _deleteImage() async {
    if (_publicId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteCloudinaryImage');

      final result = await callable.call<Map<String, dynamic>>({
        'publicId': _publicId,
      });

      if (result.data['success'] == true) {
        print('File deleted successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully!')),
        );
        setState(() {
          _imageUrl = null;
          _publicId = null;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      print('Error calling Cloud Function: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message ?? "Failed to delete file"}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Cloudinary Upload')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_isLoading) const CircularProgressIndicator(),

            if (!_isLoading && _imageUrl != null)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.network(_imageUrl!, height: 200),
                  ),
                  ElevatedButton.icon(
                    onPressed: _deleteImage,
                    icon: const Icon(Icons.delete),
                    label: const Text('Delete Image'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  )
                ],
              ),

            if (!_isLoading && _imageUrl == null)
              ElevatedButton(
                onPressed: () async {
                  final String? uploadedUrl = await _uploadImage();

                  if (uploadedUrl != null) {
                    print("URL received from upload: $uploadedUrl");
                    // You can now save the URL to Firestore or use it elsewhere
                  } else {
                    print("Upload failed or canceled.");
                  }
                },
                child: const Text('Select and Upload Image'),
              ),
          ],
        ),
      ),
    );
  }
}