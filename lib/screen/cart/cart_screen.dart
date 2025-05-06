import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test2/screen/template.dart';
import 'package:test2/screen/cart/cart_provider.dart';
import 'package:test2/screen/payment/payment.dart';
import 'package:test2/screen/cart/cartitem.dart';
import 'package:test2/screen/cart/cartmodel.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isLoading = false;

  final String tableId = "1";
  final String note = "idk";

  Future<Map<String, dynamic>?> createOrderApi(List<Map<String, dynamic>> items) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final validItems = items.where((item) =>
      item["dishId"] != null && (item["dishId"] is int && item["dishId"] > 0)).toList();

      if (validItems.isEmpty) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Không có món hàng hợp lệ để đặt');
        return null;
      }

      final url = Uri.parse('http://192.168.44.2:8080/api/orders');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "tableId": tableId,
          "items": validItems,
          "note": note,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        _showErrorSnackBar('Lỗi tạo đơn hàng: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Lỗi kết nối đến máy chủ');
      return null;
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _proceedToPayment() async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (cart.items.isEmpty) {
      _showErrorSnackBar('Giỏ hàng trống!');
      return;
    }

    final List<Map<String, dynamic>> items = [];

    for (var entry in cart.items.entries) {
      String keyId = entry.key;
      int? dishId;

      try {
        dishId = int.parse(keyId);
      } catch (e) {
        continue;
      }

      if (dishId > 0) {
        items.add({
          "dishId": dishId,
          "quantity": entry.value.quantity,
        });
      }
    }

    if (items.isEmpty) {
      _showErrorSnackBar('Không tìm thấy món hàng có ID hợp lệ');
      return;
    }

    final response = await createOrderApi(items);

    if (response != null) {
      final orderId = response['orderId']?.toString();

      if (orderId != null && orderId.isNotEmpty) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              amount: cart.totalAmount,
              orderId: orderId,
            ),
          ),
        );
      } else {
        _showErrorSnackBar('Không tìm thấy mã đơn hàng');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    final formatCurrency = NumberFormat('#,###', 'vi_VN');

    return TemplateScreen(
      currentIndex: 2,
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 10),
              Expanded(
                child: cart.items.isEmpty
                    ? const Center(
                  child: Text(
                    'Giỏ hàng trống!',
                    style: TextStyle(fontSize: 20),
                  ),
                )
                    : ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (ctx, i) {
                    final cartItem = cart.items.values.toList()[i];
                    return CartItemWidget(
                      id: cartItem.id,
                      name: cartItem.name,
                      price: cartItem.price,
                      quantity: cartItem.quantity,
                      image: cartItem.image,
                    );
                  },
                ),
              ),
              Card(
                margin: const EdgeInsets.all(15),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng tiền:',
                        style: TextStyle(fontSize: 20),
                      ),
                      const Spacer(),
                      Chip(
                        label: Text(
                          '${formatCurrency.format(cart.totalAmount)}đ',
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      ElevatedButton(
                        onPressed: cart.items.isEmpty || _isLoading ? null : _proceedToPayment,
                        child: _isLoading
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Text('THANH TOÁN'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}