import 'package:url_launcher/url_launcher.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test2/screen/cart/cart_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'package:test2/screen/cart/cartitem.dart';
import 'package:intl/intl.dart'; // Thư viện để định dạng số
import 'dart:async';
import 'package:test2/screen/payment/success.dart'; // Import trang success.dart
import 'package:uni_links/uni_links.dart';


class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double amount;
  const PaymentScreen({
    Key? key,

    required this.orderId, required this.amount,
  }) : super(key: key);

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _paymentUrl;
  String? _errorMessage;
  String _selectedMethod = "";
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  // Tab mới để theo dõi trạng thái
  html.WindowBase? _paymentWindow;
  bool _isCheckingPaymentStatus = false;
  Timer? _statusCheckTimer;
  String? _responseCode;

  Future<void> _initializePayment() async {
    // Xử lý trường hợp thanh toán tiền mặt
    if (_selectedMethod == "cash") {
      try {
        // Gọi API thanh toán tiền mặt
        final url = Uri.parse('http://localhost:8080/api/orders/${widget.orderId}/pay-cash');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("Thanh toán tiền mặt thành công: ${data['message']}");

          // Xóa giỏ hàng sau khi thanh toán
          Provider.of<CartProvider>(context, listen: false).clear();

          // Chuyển đến màn hình thành công
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SuccessScreen()),
          );
        } else {
          print('Thanh toán không thành công: ${response.body}');
          // Xử lý khi API trả về lỗi
          _showErrorDialog('Thanh toán không thành công, vui lòng thử lại!');
        }
      } catch (e) {
        print('Lỗi khi thực hiện thanh toán tiền mặt: $e');
        // Hiển thị lỗi cho người dùng
        _showErrorDialog('Có lỗi xảy ra khi thanh toán. Vui lòng thử lại!');
      }
      return;
    }
    if (_selectedMethod == "paypal") {
      await _launchPaypalCheckout(int.parse(widget.orderId));
      _startCheckingPaymentStatus();
      return;
    }

    // Xử lý thanh toán VNPay riêng
    if (_selectedMethod == "vnpay") {
      await _processVNPayPayment();
      _startCheckingPaymentStatus();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentUrl = await _createPaymentUrl();

      setState(() {
        _paymentUrl = paymentUrl;
        _isLoading = false;
      });

      if (kIsWeb && _paymentUrl != null) {
        _openPaymentInNewTab();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể khởi tạo thanh toán: $e';
        _isLoading = false;
      });
    }
  }

  Future<String?> _createPaypalOrder(int orderId) async {
    final url = Uri.parse('http://localhost:8080/api/payment/paypal/create-order?orderId=$orderId');
    try {
      final response = await http.post(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['approvalUrl']; // Trả về URL để redirect đến PayPal
      } else {
        print('Lỗi khi tạo đơn hàng PayPal: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception khi gọi API PayPal: $e');
    }
    return null;
  }

  Future<void> _launchPaypalCheckout(int orderId) async {
    final url = await _createPaypalOrder(orderId);
    if (url != null && await canLaunch(url)) {
      await launch(url); // Mở URL thanh toán
    } else {
      print('Không thể mở URL thanh toán PayPal');
    }
  }

  Future<void> _processVNPayPayment() async {
    try {
      final url = Uri.parse('http://localhost:8080/api/payment/vnpay/order/${widget.orderId}');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Lấy URL thanh toán từ response
        final paymentUrl = data['url']; // ví dụ: "https://sandbox.vnpay.vn/checkout..."

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          // Mở tab thanh toán trên web
          if (kIsWeb) {
            html.window.open(paymentUrl, '_blank');
          }

          _startCheckingPaymentStatus();
        } else {
          _showErrorDialog('Không nhận được URL thanh toán từ VNPay.');
        }
      } else {
        _showErrorDialog('Không thể tạo URL thanh toán. Mã lỗi: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi xử lý thanh toán VNPay: $e');
      _showErrorDialog('Đã xảy ra lỗi trong quá trình tạo URL thanh toán.');
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Lỗi'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }



  Future<String> _createPaymentUrl() async {
    final url = Uri.parse('http://localhost:8080/api/payment/vnpay/order/${widget.orderId}'); // Sử dụng API với orderId

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Giả sử API trả về "url" chứa URL thanh toán
        return data['url'] ?? 'https://api-m.sandbox.paypal.com/v2/checkout/orders'; // URL mặc định nếu không có URL thanh toán
      } else {
        throw Exception('Lỗi tạo URL thanh toán: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tạo URL thanh toán: $e');
      return 'https://api-m.sandbox.paypal.com/v2/checkout/orders'; // URL mặc định nếu có lỗi
    }
  }



  void _openPaymentInNewTab() {
    if (_paymentUrl != null && kIsWeb) {
      // Mở thanh toán trong tab mới
      _paymentWindow = html.window.open(_paymentUrl!, '_blank');

      setState(() {
        _isCheckingPaymentStatus = true;
      });

      // Bắt đầu kiểm tra trạng thái đơn hàng
      _startCheckingPaymentStatus();
    }
  }

  void _startCheckingPaymentStatus() {
    // Hủy timer hiện tại nếu có
    _statusCheckTimer?.cancel();

    // Tạo timer để kiểm tra trạng thái đơn hàng định kỳ
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkPaymentStatus();
    });
  }

  Future<void> _checkPaymentStatus() async {
    try {
      final url = Uri.parse('http://localhost:8080/api/orders/${widget.orderId}');
      final response = await http.get(url);
      print(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['orderStatus']; // Giả sử response có field 'status'
        print(status);
        if (status == 'Completed') {
          // Thanh toán thành công
          _statusCheckTimer?.cancel();
          setState(() {
            _isCheckingPaymentStatus = false;
          });

          // Xóa giỏ hàng
          Provider.of<CartProvider>(context, listen: false).clear();

          // Chuyển sang màn hình thành công (SuccessScreen)
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SuccessScreen(), // nếu SuccessScreen cần orderId
            ),
          );

        } else if (status == 'Cancelled') {
          // Thanh toán bị hủy
          _statusCheckTimer?.cancel();
          setState(() {
            _isCheckingPaymentStatus = false;
          });
          _showCancelDialog();
        }
      }
    } catch (e) {
      print('Lỗi khi kiểm tra trạng thái thanh toán: $e');
    }
  }


  @override
  void dispose() {
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hủy thanh toán"),
        content: const Text("Bạn đã hủy quá trình thanh toán."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Quay lại giỏ hàng"),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodIcon(String method, String label, IconData icon) {
    final isSelected = _selectedMethod == method;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: isSelected ? Colors.blue : Colors.grey),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails() {
    final cart = Provider.of<CartProvider>(context);




    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Chi tiết đơn hàng", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...cart.items.values.map((item) => CartItemWidget(
          id: item.id,
          name: item.name,
          price: item.price,
          quantity: item.quantity,
          image: item.image,
        )).toList(),
        const Divider(thickness: 1.5),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Tổng cộng:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text("${_currencyFormat.format(widget.amount)}đ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _handleDeeplink() async {
    try {
      final Uri? initialUri = (await getInitialLink()) as Uri?; // Lấy deeplink khi mở app
      if (initialUri != null && initialUri.scheme == 'myapp' && initialUri.host == 'payment-result') {
        final status = initialUri.queryParameters['status'];
        final txnRef = initialUri.queryParameters['txnRef'];

        if (status == 'success') {
          // Xoá giỏ hàng
          Provider.of<CartProvider>(context, listen: false).clear();

          // Điều hướng tới trang thành công
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SuccessScreen(txnRef: txnRef)),
          );
        } else {
          _showFailureDialog();
        }
      }
    } catch (e) {
      print('Lỗi khi xử lý deeplink: $e');
    }
  }


  void _showSuccessDialog(String txnRef) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thanh toán thành công'),
          content: Text('Thanh toán đã hoàn tất. Mã giao dịch: $txnRef'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Thanh toán thất bại'),
          content: Text('Thanh toán của bạn không thành công. Vui lòng thử lại sau.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text("Đang xử lý thanh toán..."),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                });
              },
              child: const Text("Thử lại"),
            ),
          ],
        ),
      );
    }

    if (_isCheckingPaymentStatus) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text("Đang chờ xác nhận thanh toán..."),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                _statusCheckTimer?.cancel();
                setState(() {
                  _isCheckingPaymentStatus = false;
                });
              },
              child: const Text("Hủy"),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildOrderDetails(),
          const Text("Chọn phương thức thanh toán:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPaymentMethodIcon("paypal", "PayPal", Icons.payment),
              _buildPaymentMethodIcon("vnpay", "VNPay", Icons.credit_card),
              _buildPaymentMethodIcon("cash", "Tiền mặt", Icons.money),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thanh toán đơn hàng"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Hủy thanh toán?'),
                content: const Text('Bạn có chắc muốn hủy thanh toán này?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Không'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Có'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: _buildBody(),
      bottomNavigationBar: _isCheckingPaymentStatus ? null : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.payment),
          label: const Text("Thanh toán", style: TextStyle(fontSize: 16)),
          onPressed: _initializePayment,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}