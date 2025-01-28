import 'package:flutter/material.dart';
import 'package:app_upload/upload.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_downloader_v2/image_downloader_v2.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const FileListPage(),
    );
  }
}

class FileListPage extends StatefulWidget {
  const FileListPage({super.key});

  @override
  State<FileListPage> createState() => _FileListPageState();
}

class _FileListPageState extends State<FileListPage> {
  late Future<List<FileItem>> _fileListFuture;

  @override
  void initState() {
    super.initState();
    _fileListFuture = fetchFiles();
  }

  Future<List<FileItem>> fetchFiles() async {
    const String apiUrl =
        "http://192.168.0.104/api_gambar/index.php"; // Ganti dengan URL API Anda
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        if (jsonResponse['success'] == true) {
          final List files = jsonResponse['files'];
          return files.map((file) => FileItem.fromJson(file)).toList();
        } else {
          throw Exception(jsonResponse['message']);
        }
      } else {
        throw Exception(
            'Failed to load files. Status code: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }

  Future<void> downloadFile(String fileId, String name) async {
    const String baseUrl =
        "http://192.168.0.104/api_gambar/download.php"; // Ganti dengan URL API download Anda
    String message = ''; // Pesan untuk ditampilkan pada SnackBar

    try {
      // Download image
      final response = await http.get(Uri.parse('$baseUrl?name=$name'));

      if (response.statusCode == 200) {
        // Get the downloads directory
        final dir = await getDownloadsDirectory();

        if (dir != null) {
          // Generate unique file name
          final filePath = await _getUniqueFileName(dir.path, name);

          // Save file to the filesystem
          final file = File(filePath);
          await file.writeAsBytes(response.bodyBytes);

          // Show save dialog to the user
          final params = SaveFileDialogParams(sourceFilePath: file.path);
          final finalPath = await FlutterFileDialog.saveFile(params: params);

          if (finalPath != null) {
            message = 'Image successfully saved to $finalPath';
          } else {
            message = 'Image saving was canceled by the user.';
          }
        } else {
          message = 'Failed to find downloads directory.';
        }
      } else {
        message =
            'Failed to download the image. Status code: ${response.statusCode}';
      }
    } catch (e) {
      message = 'An error occurred: $e';
      print(message);
    }

    // Display the message using SnackBar
    if (message.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFFe91e63),
      ));
    }
  }

// Function to generate a unique file name by appending numbers
  Future<String> _getUniqueFileName(String dirPath, String fileName) async {
    String baseName = fileName;
    String extension = '';

    // Split file name into base name and extension
    final index = fileName.lastIndexOf('.');
    if (index != -1) {
      baseName = fileName.substring(0, index);
      extension = fileName.substring(index);
    }

    String uniqueName = '$dirPath/$baseName$extension';
    int counter = 1;

    // Check for file existence and generate unique name
    while (await File(uniqueName).exists()) {
      uniqueName = '$dirPath/$baseName ($counter)$extension';
      counter++;
    }

    return uniqueName;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uploaded Files'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to upload form
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FileUploadPage()),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<FileItem>>(
        future: _fileListFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final file = snapshot.data![index];
                return ListTile(
                  title: Text(file.fileName),
                  subtitle: Text(file.filePath),
                  leading: const Icon(Icons.insert_drive_file),
                  onTap: () {
                    downloadFile(file.id, file.fileName);
                  },
                );
              },
            );
          } else {
            return const Center(child: Text('No files uploaded.'));
          }
        },
      ),
    );
  }
}

class FileItem {
  final String id;
  final String fileName;
  final String filePath;

  FileItem({
    required this.id,
    required this.fileName,
    required this.filePath,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      fileName: json['file_name'],
      filePath: json['file_path'],
    );
  }
}
