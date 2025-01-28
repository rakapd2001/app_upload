import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  File? _selectedFile;
  final picker = ImagePicker();

  Future<void> _selectFile() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile.path);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected')),
      );
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a file first!')),
      );
      return;
    }

    const String apiUrl =
        "http://192.168.0.104/api_gambar/upload.php"; // Ganti dengan URL API PHP Anda
    final request = http.MultipartRequest("POST", Uri.parse(apiUrl));

    // Menambahkan file yang dipilih ke dalam permintaan
    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // Sesuaikan dengan parameter API Anda
        _selectedFile!.path,
      ),
    );

    try {
      final response = await request.send();
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully!')),
        );

        // Kembali ke halaman daftar file
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to upload file. Error: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload File'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_selectedFile != null)
              Text(
                "Selected: ${_selectedFile!.path.split('/').last}",
                style: const TextStyle(fontSize: 16),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _selectFile,
              child: const Text('Select File'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _uploadFile,
              child: const Text('Upload File'),
            ),
          ],
        ),
      ),
    );
  }
}
