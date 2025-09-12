import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../utils/showToast.dart';


class EbookDetailScreen extends StatefulWidget {
  final String ebookId;
  const EbookDetailScreen({super.key, required this.ebookId});

  @override
  State<EbookDetailScreen> createState() => _EbookDetailScreenState();
}

class _EbookDetailScreenState extends State<EbookDetailScreen> {
  final firestore = FirebaseFirestore.instance;
  String? pdfUrl;
  bool isLoading = true;
  String? error;
  bool isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchEbook();
  }

  Future<void> fetchEbook() async {
    try {
      final doc = await firestore.collection("ebooks").doc(widget.ebookId).get();
      if (!doc.exists) {
        setState(() {
          error = "❌ Ebook not found";
          isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final url = data["pdfUrl"];
      if (url == null) {
        setState(() {
          error = "❌ This ebook has no PDF file.";
          isLoading = false;
        });
        return;
      }

      setState(() {
        pdfUrl = url;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = "❌ Error loading ebook: $e";
        isLoading = false;
      });
    }
  }

  Future<void> downloadPdf() async {
    if (pdfUrl == null) return;

    try {
      setState(() => isDownloading = true);
      final response = await http.get(Uri.parse(pdfUrl!));

      if (response.statusCode != 200) {
        showToast("❌ Failed to download PDF", "error");
        setState(() => isDownloading = false);
        return;
      }

      // Lưu file vào thư mục Downloads hoặc Documents
      Directory dir;
      if (Platform.isAndroid) {
        dir = (await getExternalStorageDirectory())!;
      } else {
        dir = await getApplicationDocumentsDirectory();
      }

      final filePath = "${dir.path}/ebook_${DateTime.now().millisecondsSinceEpoch}.pdf";
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      showToast("✅ PDF downloaded to ${file.path}", "success");
      setState(() => isDownloading = false);
    } catch (e) {
      showToast("❌ Download failed: $e", "error");
      setState(() => isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Ebook Detail")),
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (!isDownloading && pdfUrl != null)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: downloadPdf,
              tooltip: "Download PDF",
            ),
          if (isDownloading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
            ),
        ],
      ),
      body: pdfUrl != null
          ? SfPdfViewer.network(
        pdfUrl!,
        onDocumentLoadFailed: (details) {
          setState(() {
            error = "❌ Failed to load PDF: ${details.description}";
          });
        },
      )
          : Center(child: Text(error ?? "❌ PDF not available")),
    );
  }
}
