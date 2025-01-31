import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:rxdart/rxdart.dart';

class FileUploadPage extends StatefulWidget {
  const FileUploadPage({super.key});

  @override
  State<FileUploadPage> createState() => _FileUploadPageState();
}

class _FileUploadPageState extends State<FileUploadPage> {
  File? _selectedFile;
  final picker = ImagePicker();
  final TextEditingController _nameController = TextEditingController();
  final BehaviorSubject<String> _nameStream =
      BehaviorSubject<String>.seeded(''); // Stream untuk nama
  final BehaviorSubject<String> _uploadStatus =
      BehaviorSubject<String>.seeded(''); // RxDart Stream untuk status upload

  @override
  void initState() {
    super.initState();

    // Menambahkan listener pada TextEditingController untuk mengupdate stream
    _nameController.addListener(() {
      _nameStream
          .add(_nameController.text); // Update stream setiap kali ada perubahan
    });
  }

  // Function to select a file (image)
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

  // Function to upload the file and input name to the server
  Future<void> _uploadFile() async {
    if (_selectedFile == null || _nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a name and select a file first!')),
      );
      return;
    }

    const String apiUrl =
        "http://192.168.199.96/api_gambar/upload.php"; // Update with your API URL

    final request = http.MultipartRequest("POST", Uri.parse(apiUrl));
    request.fields['name'] = _nameController.text; // Adding the name field
    request.files.add(
      await http.MultipartFile.fromPath(
        'image', // Match this with your API parameter name
        _selectedFile!.path,
      ),
    );

    try {
      // Update status using RxDart Stream
      _uploadStatus.add('Uploading...');

      final response = await request.send();

      // Handle response status code
      if (response.statusCode == 200) {
        _uploadStatus.add('File uploaded successfully!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'File uploaded successfully!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Optionally, navigate back after successful upload
        Navigator.pop(context);
      } else {
        _uploadStatus
            .add('Failed to upload file. Error: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to upload file. Error: ${response.statusCode}',
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
      _uploadStatus.add('Failed to upload file. Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to upload file. Error: $e',
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
  void dispose() {
    _nameStream.close(); // Close the name stream
    _uploadStatus.close(); // Close the upload status stream
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Documentation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // TextField untuk nama file
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Enter Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            // Menampilkan nama file yang sedang diketik
            StreamBuilder<String>(
              stream: _nameStream.stream,
              builder: (context, snapshot) {
                return Text(
                  snapshot.hasData ? 'File name: ${snapshot.data}' : '',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                );
              },
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
              onPressed: _uploadFile,
              child: const Text('Upload File'),
            ),
            const SizedBox(height: 20),
            StreamBuilder<String>(
              stream: _uploadStatus.stream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                return Text(
                  snapshot.data ?? '',
                  style: const TextStyle(fontSize: 16, color: Colors.blue),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
