import 'package:flutter/material.dart';
import 'package:test2/screen/home1/home.dart';

class FailScreen extends StatelessWidget {
  final String? errorMessage;

  const FailScreen({Key? key, this.errorMessage}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.cancel_outlined,
                color: Colors.redAccent,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Thanh toán thất bại!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                errorMessage ?? 'Đã xảy ra lỗi khi xử lý giao dịch của bạn. Vui lòng thử lại.',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                        (route) => false,
                  );
                },
                icon: const Icon(Icons.home),
                label: const Text('Về trang chủ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
