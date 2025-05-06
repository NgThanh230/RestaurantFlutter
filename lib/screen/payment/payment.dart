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
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:vnpay_flutter/vnpay_flutter.dart'; // Import VNPay Flutter package

class PaymentScreen extends StatefulWidget {
  final double amount;
  final String orderId;

  const PaymentScreen({
    Key? key,
    required this.amount,
    required this.orderId,
  }) : super(key: key);

  @override
  PaymentScreenState createState() => PaymentScreenState();
}

class PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String? _paymentUrl;
  String? _errorMessage;
  String _selectedMethod = "paypal";
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  // Tab mới để theo dõi trạng thái
  html.WindowBase? _paymentWindow;
  bool _isCheckingPaymentStatus = false;
  Timer? _statusCheckTimer;
  String? _responseCode;

  Future<void> _initializePayment() async {
    // Xử lý trường hợp thanh toán tiền mặt
    if (_selectedMethod == "cash") {
      // Cập nhật trạng thái đơn hàng thành "đang xử lý" hoặc "chờ thanh toán"
      await _updateOrderStatus("pending");

      // Chuyển thẳng sang trang success
      Provider.of<CartProvider>(context, listen: false).clear();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SuccessScreen()),
      );
      return;
    }

    // Xử lý thanh toán VNPay riêng
    if (_selectedMethod == "vnpay") {
      await _processVNPayPayment();
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

  Future<void> _processVNPayPayment() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentUrl = VNPAYFlutter.instance.generatePaymentUrl(
        url: 'https://sandbox.vnpayment.vn/paymentv2/vpcpay.html',
        version: '2.0.1',
        tmnCode: 'PHCKMLTO', // Sử dụng TMN code được cung cấp
        txnRef: widget.orderId,
        orderInfo: 'Thanh toán đơn hàng #${widget.orderId}',
        amount: widget.amount, // Sử dụng kiểu double trực tiếp
        returnUrl: 'http://192.168.44.2:8080/api/payments/vnpay/return', // Địa chỉ API nhận kết quả
        ipAdress: '192.168.44.2', // Thay đổi địa chỉ IP phù hợp với máy chủ của bạn
        vnpayHashKey: 'WKBFORFGBUGKCVZOT1SK3BNGZOBELGFK', // Sử dụng vnp_HashSecret được cung cấp
        vnPayHashType: VNPayHashType.HMACSHA512,
        vnpayExpireDate: DateTime.now().add(const Duration(minutes: 15)),
      );

      setState(() {
        _isLoading = false;
      });

      await VNPAYFlutter.instance.show(
        paymentUrl: paymentUrl,
        onPaymentSuccess: (params) async {
          setState(() {
            _responseCode = params['vnp_ResponseCode'];
          });

          if (_responseCode == '00') { // Mã thành công từ VNPay
            // Cập nhật trạng thái đơn hàng trên server
            await _updateOrderStatus("completed");

            // Xóa giỏ hàng và chuyển đến trang thành công
            Provider.of<CartProvider>(context, listen: false).clear();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SuccessScreen()),
            );
          } else {
            // Xử lý các trạng thái khác từ VNPay
            _showPaymentErrorDialog('Thanh toán không thành công. Mã lỗi: $_responseCode');
          }
        },
        onPaymentError: (params) {
          setState(() {
            _responseCode = 'Error';
          });
          _showPaymentErrorDialog('Đã xảy ra lỗi trong quá trình thanh toán.');
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Không thể khởi tạo thanh toán VNPay: $e';
      });
    }
  }

  void _showPaymentErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lỗi thanh toán"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Đóng"),
          ),
        ],
      ),
    );
  }

  Future<String> _createPaymentUrl() async {
    // Giữ nguyên xử lý cho các phương thức khác (PayPal)
    final url = Uri.parse('http://192.168.44.2:8080/api/payments/create');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "orderId": widget.orderId,
          "amount": widget.amount,
          "method": _selectedMethod,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['paymentUrl'] ??
            'https://api-m.sandbox.paypal.com/v2/checkout/orders';
      } else {
        throw Exception('Lỗi tạo URL thanh toán: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi tạo URL thanh toán: $e');
      return 'https://api-m.sandbox.paypal.com/v2/checkout/orders';
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
      final url = Uri.parse('http://192.168.44.2:8080/api/orders/${widget.orderId}/status');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data['status'];

        if (status == 'completed') {
          // Thanh toán thành công
          _statusCheckTimer?.cancel();
          setState(() {
            _isCheckingPaymentStatus = false;
          });

          // Xóa giỏ hàng
          Provider.of<CartProvider>(context, listen: false).clear();

          // Chuyển thẳng sang trang success
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SuccessScreen()),
          );
        } else if (status == 'cancelled') {
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

  Future<void> _updateOrderStatus(String status) async {
    try {
      final url = Uri.parse('http://192.168.44.2:8080/api/orders/${widget.orderId}/status');

      await http.put(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"status": status}),
      );

      if (status == "completed" || status == "pending") {
        Provider.of<CartProvider>(context, listen: false).clear();
      }
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái đơn hàng: $e');
    }
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
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ),
    );
  }
}