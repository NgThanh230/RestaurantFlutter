import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test2/screen/home1/home.dart';
import 'package:test2/screen/cart/cart_provider.dart';



void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Chỉ khởi tạo WebView khi KHÔNG chạy trên web
  if (!kIsWeb) {
    // Chỉ chạy code này trên Android hoặc iOS
    try {
      if (Platform.isAndroid) {
        // Code dành cho Android
        //WebView.platform = AndroidInAppWebViewPlatform();
      }
    } catch (e) {
      // Bỏ qua lỗi liên quan đến Platform khi chạy trên web
      print('WebView initialization error: $e');
    }
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Restaurant Management',
      initialRoute: '/',
      routes: {
        '/': (context) => HomePage(),
      },
    );
  }
}