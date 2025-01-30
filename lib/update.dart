import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class FileUpdatePage extends StatefulWidget {
  final String fileId;
  final String name;

  FileUpdatePage({required this.fileId, required this.name});

  @override
  State<FileUpdatePage> createState() => _FileUpdatePageState();
}

class _FileUpdatePageState extends State<FileUpdatePage> {
  File? _selectedFile;
  final picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();

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

  Future<void> _UpdateFile() async {
    if (_selectedFile == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a name and select a file first!')),
      );
      return;
    }

    const String apiUrl =
        "http://192.168.0.105/api_gambar/Update.php"; // Ganti dengan URL API PHP Anda
    final request = http.MultipartRequest("POST", Uri.parse(apiUrl));
    request.fields['id'] = widget.fileId;
    request.fields['new_name'] = _nameController.text; // Menambahkan input name
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
          const SnackBar(
            content: Text(
              'File Updateed successfully!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Kembali ke halaman daftar file
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to Update file. Error: ${response.statusCode}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to Update file. Error: ${e}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Documentation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
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
              onPressed: _UpdateFile,
              child: const Text('Update File'),
            ),
          ],
        ),
      ),
    );
  }
}
