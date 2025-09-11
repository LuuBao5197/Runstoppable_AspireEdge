import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:path/path.dart' as path; // <-- BƯỚC 1: Thêm thư viện path
import 'package:cloud_functions/cloud_functions.dart'; // <-- BƯỚC 2: Thêm thư viện Cloud Functions

class ImageUploader extends StatefulWidget {
  const ImageUploader({super.key});

  @override
  State<ImageUploader> createState() => _ImageUploaderState();
}

class _ImageUploaderState extends State<ImageUploader> {
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;
  String? _publicId; // <-- BƯỚC 3: Thêm biến để lưu publicId
  bool _isLoading = false;

  // LƯU Ý QUAN TRỌNG: Tên 'EBowNNIllO_ANLZNu_VFLkblUOk' này có vẻ không phải là
  // Upload Preset Name. Bạn hãy vào Cloudinary Dashboard -> Settings -> Upload
  // -> Upload presets để lấy tên đúng nhé. Ví dụ: 'unsigned_uploads'
  final cloudinary = CloudinaryPublic('dbghucaix', 'YOUR_UNSIGNED_UPLOAD_PRESET');

  // THAY ĐỔI 1: Sửa kiểu trả về của hàm thành Future<String?>
  Future<String?> _uploadImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) {
      // Người dùng không chọn ảnh, trả về null
      return null;
    }

    setState(() {
      _isLoading = true;
      _imageUrl = null;
      _publicId = null;
    });

    try {
      // THAY ĐỔI 1: Lấy publicId từ tên file gốc trước khi upload
      final String publicId = path.basenameWithoutExtension(image.name);

      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          image.path,
          publicId: publicId, // Đặt tên cho file trên Cloudinary
          resourceType: CloudinaryResourceType.Image,
        ),
      );

      // THAY ĐỔI 2: Lưu lại cả imageUrl và publicId sau khi upload thành công
      setState(() {
        _imageUrl = response.secureUrl;
        _publicId = response.publicId; // Lưu lại publicId
        _isLoading = false;
      });

      print('Upload thành công! Public ID: ${response.publicId}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload thành công!')),
      );

      // THAY ĐỔI 2: Trả về chuỗi URL sau khi thành công
      return response.secureUrl;
    } on CloudinaryException catch (e) {
      print('Lỗi upload: ${e.message}');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload thất bại: ${e.message}')),
      );
      // Trả về null khi có lỗi
      return null;
    }
  }

  // HÀM MỚI: Dùng để gọi Cloud Function và xóa ảnh
  Future<void> _deleteImage() async {
    if (_publicId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Gọi đến Cloud Function tên là 'deleteCloudinaryImage'
      HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteCloudinaryImage');

      // Gửi publicId lên cho function xử lý
      final result = await callable.call<Map<String, dynamic>>({
        'publicId': _publicId,
      });

      // Xử lý kết quả trả về từ function
      if (result.data['success'] == true) {
        print('Xóa file thành công!');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa file thành công!')),
        );
        // Xóa ảnh khỏi giao diện
        setState(() {
          _imageUrl = null;
          _publicId = null;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      print('Lỗi khi gọi Cloud Function: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.message ?? "Không thể xóa file"}')),
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
      appBar: AppBar(title: Text('Flutter Cloudinary Upload')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // Hiển thị vòng xoay loading khi đang upload hoặc xóa
            if (_isLoading) CircularProgressIndicator(),

            // Khi có ảnh, hiển thị ảnh và nút Xóa
            if (!_isLoading && _imageUrl != null)
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Image.network(_imageUrl!, height: 200),
                  ),
                  ElevatedButton.icon(
                    onPressed: _deleteImage,
                    icon: Icon(Icons.delete),
                    label: Text('Xóa ảnh'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  )
                ],
              ),

            // Khi chưa có ảnh, hiển thị nút Tải lên
            if (!_isLoading && _imageUrl == null)
              ElevatedButton(
                // THAY ĐỔI 3: Cập nhật lại cách gọi hàm để nhận giá trị trả về
                onPressed: () async {
                  final String? uploadedUrl = await _uploadImage();

                  if (uploadedUrl != null) {
                    print("URL nhận được từ hàm: $uploadedUrl");
                    // Tại đây, bạn có thể làm gì đó với URL,
                    // ví dụ như lưu nó vào Firestore.
                  } else {
                    print("Upload không thành công hoặc đã bị hủy.");
                  }
                },
                child: Text('Chọn và Tải ảnh lên'),
              ),
          ],
        ),
      ),
    );
  }
}

