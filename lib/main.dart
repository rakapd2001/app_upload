import 'package:app_upload/update.dart';
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

  Future<void> _refreshFileList() async {
    setState(() {
      _fileListFuture = fetchFiles();
    });
  }

  Future<List<FileItem>> fetchFiles() async {
    const String apiUrl =
        "http://192.168.0.105/api_gambar/index.php"; // Ganti dengan URL API Anda
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
        "http://192.168.0.105/api_gambar/download.php"; // Ganti dengan URL API download Anda
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color(0xFFe91e63),
        ),
      );
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

  Future<void> deleteFile(String fileId) async {
    const String baseUrl =
        "http://192.168.0.105/api_gambar/delete.php"; // Sesuaikan dengan API Anda
    String message = '';

    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Konfirmasi"),
          content:
              const Text("Apakah Anda yakin ingin menghapus dokumentasi ini?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("Batal"),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Hapus"),
            ),
          ],
        );
      },
    );

    if (confirmDelete) {
      try {
        final response = await http.delete(Uri.parse("$baseUrl?id=$fileId"));

        if (response.statusCode == 200) {
          final jsonResponse = json.decode(response.body);
          if (jsonResponse['success'] == true) {
            message = "File berhasil dihapus";

            // Perbarui daftar file setelah penghapusan
            setState(() {
              _fileListFuture = fetchFiles();
            });
          } else {
            message = jsonResponse['message'] ?? "Gagal menghapus file";
          }
        } else {
          message = "Gagal menghapus file. Status: ${response.statusCode}";
        }
      } catch (e) {
        message = "Terjadi kesalahan: $e";
      }

      // Tampilkan pesan dengan SnackBar
      if (message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void updateFile(String fileId, String name) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FileUpdatePage(fileId: fileId, name: name),
      ),
    ).then((value) {
      if (value == true) {
        _refreshFileList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dokumentation File'),
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
      body: RefreshIndicator(
        onRefresh: _refreshFileList,
        child: FutureBuilder<List<FileItem>>(
          future: _fileListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Tidak ada data.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('Tidak ada data.'));
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  final file = snapshot.data![index];
                  return ListTile(
                    title: Text(file.name),
                    subtitle: Text(file.fileName),
                    leading: const Icon(Icons.insert_drive_file),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          // onPressed: () => {},
                          onPressed: () => updateFile(file.id, file.name),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteFile(file.id),
                        ),
                      ],
                    ),
                    onTap: () {
                      downloadFile(file.id, file.fileName);
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class FileItem {
  final String id;
  final String name;
  final String fileName;
  final String filePath;

  FileItem({
    required this.id,
    required this.name,
    required this.fileName,
    required this.filePath,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'],
      name: json['name'],
      fileName: json['file_name'],
      filePath: json['file_path'],
    );
  }
}
