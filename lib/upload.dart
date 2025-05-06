import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mysql1/mysql1.dart';

class UploadImageScreen extends StatefulWidget {
  @override
  _UploadImageScreenState createState() => _UploadImageScreenState();
}

class _UploadImageScreenState extends State<UploadImageScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _imageUrl;

  // Chọn ảnh từ thư viện
  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  // Upload ảnh lên Cloudinary
  Future<void> _uploadToCloudinary() async {
    if (_imageFile == null) return;

    String cloudName = "dmg98ght0";
    String uploadPreset = "menu";

    var url = Uri.parse("https://api.cloudinary.com/v1_1/dmg98ght0/image/upload");

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', _imageFile!.path));

    var response = await request.send();
    var responseData = await response.stream.bytesToString();
    var jsonData = json.decode(responseData);

    setState(() {
      _imageUrl = jsonData['secure_url'];
    });

    if (_imageUrl != null) {
      await _saveImageUrlToMySQL(_imageUrl!);
    }
  }

  // Lưu URL vào MySQL
  Future<void> _saveImageUrlToMySQL(String imageUrl) async {
    final conn = await MySqlConnection.connect(ConnectionSettings(
      host: 'localhost',
      port: 3306,
      user: 'root',
      db: 'restaurant',
      password: '',
    ));

    await conn.query(
      'INSERT INTO menu_items (image_url) VALUES (?)',
      [imageUrl],
    );

    await conn.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Upload Image to Cloudinary")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _imageFile != null ? Image.file(_imageFile!, height: 200) : Text("No Image Selected"),
            ElevatedButton(onPressed: _pickImage, child: Text("Pick Image")),
            ElevatedButton(onPressed: _uploadToCloudinary, child: Text("Upload to Cloudinary")),
            _imageUrl != null ? SelectableText("URL: $_imageUrl") : Container(),
          ],
        ),
      ),
    );
  }
}
