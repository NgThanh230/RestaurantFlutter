import 'package:flutter/material.dart';
import 'package:test2/screen/template.dart';

class NotificationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TemplateScreen(
      child: Center(
        child: Text(
          'Chưa có thông báo!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      currentIndex: 3,
    );
  }
}
