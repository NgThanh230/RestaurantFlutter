import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test2/screen/template.dart'; // Đảm bảo đường dẫn đúng đến TemplateScreen

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> orders = [];

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/reservations'), // Đổi IP nếu cần
      );
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final List<dynamic> fetchedOrders = body is List ? body : [body];

        // Sắp xếp theo thời gian giảm dần (gần nhất lên trước)
        fetchedOrders.sort((a, b) {
          final timeA = DateTime.tryParse(a['startTime'] ?? '') ?? DateTime(1970);
          final timeB = DateTime.tryParse(b['startTime'] ?? '') ?? DateTime(1970);
          return timeB.compareTo(timeA); // thời gian mới nhất lên trước
        });

        setState(() {
          orders = fetchedOrders;
        });
      } else {
        print('Failed to load orders: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e, stack) {
      print('Error fetching orders: $e');
      print(stack);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TemplateScreen(
      currentIndex: 4,
      child: orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.restaurant, color: Color(0xFF8EA383)),
              title: Text('Khách: ${order['guestName'] ?? 'N/A'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('SĐT: ${order['guestPhone'] ?? 'N/A'}'),
                  Text('Số khách: ${order['numberOfGuests'] ?? 'N/A'}'),
                  Text('Ghi chú: ${order['notes'] ?? ''}'),
                  Text('Thời gian: ${order['startTime'] ?? 'N/A'}'),
                  Text('Trạng thái: ${order['status'] ?? 'N/A'}'),
                ],
              ),
              isThreeLine: true,
              onTap: () {
                //
              },
            ),
          );
        },
      ),
    );
  }
}
