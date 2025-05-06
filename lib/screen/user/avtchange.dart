import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ChangeAvatarPage extends StatefulWidget {
  final String? currentAvatarUrl;
  final Function(String) onAvatarChanged;

  ChangeAvatarPage({this.currentAvatarUrl, required this.onAvatarChanged});

  @override
  _ChangeAvatarPageState createState() => _ChangeAvatarPageState();
}

class _ChangeAvatarPageState extends State<ChangeAvatarPage> {
  File? _image;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveAvatar() {
    // Giả lập lưu ảnh và gọi callback để cập nhật avatar
    String newAvatarUrl = _image?.path ?? widget.currentAvatarUrl ?? '';
    widget.onAvatarChanged(newAvatarUrl);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Đổi ảnh đại diện'),
        backgroundColor: Color(0xFF8EA383),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: _image != null
                  ? FileImage(_image!)
                  : widget.currentAvatarUrl != null
                  ? NetworkImage(widget.currentAvatarUrl!)
                  : AssetImage('assets/default_avatar.png')
              as ImageProvider,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Chọn ảnh từ thư viện'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveAvatar,
              child: Text('Lưu thay đổi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF8EA383),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
