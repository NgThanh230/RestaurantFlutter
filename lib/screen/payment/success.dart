import 'package:flutter/material.dart';
import 'package:test2/screen/home1/home.dart';

class SuccessScreen extends StatelessWidget {
  final String? txnRef;

  const SuccessScreen({Key? key, this.txnRef}) : super(key: key);

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
                Icons.check_circle_outline,
                color: Colors.green,
                size: 100,
              ),
              const SizedBox(height: 24),
              const Text(
                'Thanh toán thành công!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Cảm ơn quý khách đã sử dụng dịch vụ của chúng tôi.',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              if (txnRef != null) ...[
                const SizedBox(height: 20),
                Text(
                  'Mã giao dịch: $txnRef',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
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
                  backgroundColor: Colors.green,
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
