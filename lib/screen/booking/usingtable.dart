import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:test2/screen/order/order.dart';
import 'package:test2/screen/payment/payment.dart';
import 'package:test2/screen/cart/cart_provider.dart';
import 'package:provider/provider.dart';
import 'package:test2/screen/template.dart';
import 'package:test2/model/reservation.dart';
import 'package:test2/screen/user/history.dart';
import 'package:test2/screen/booking/reservation.dart';

class UsingTableScreen extends StatefulWidget {
  final int? reservationId;
  final Reservation? reservationData;

  const UsingTableScreen({super.key, this.reservationId, this.reservationData});

  @override
  State<UsingTableScreen> createState() => _UsingTableScreenState();
}

class _UsingTableScreenState extends State<UsingTableScreen> {
  late Future<TableReservation?> futureReservation;
  bool isCreatingOrder = false;
  String? errorMessage;
  TableReservation? reservation;
  bool isCheckedIn = false;
  bool hasNoReservation = false;

  @override
  void initState() {
    super.initState();

    // Xử lý cả hai trường hợp: khi có sẵn data hoặc cần fetch
    if (widget.reservationData != null) {
      // Nếu có data được truyền vào, chuyển đổi sang TableReservation
      reservation = _convertToTableReservation(widget.reservationData!);
      futureReservation = Future.value(reservation);
      print("Sử dụng dữ liệu đặt bàn đã truyền: ${widget.reservationData!.id}");
    } else if (widget.reservationId != null) {
      // Nếu chỉ có ID, fetch data từ API
      print("Đang tải dữ liệu đặt bàn với ID: ${widget.reservationId}");
      futureReservation = fetchReservationById(widget.reservationId!);
    } else {
      // Trường hợp không có data nào được cung cấp
      hasNoReservation = true;
      futureReservation = Future.value(null);
    }
  }

  TableReservation _convertToTableReservation(Reservation data) {
    print("Chuyển đổi dữ liệu đặt bàn: ${data.guestName}, ${data.numberOfGuests} người");
    return TableReservation(
      id: data.id,
      guestName: data.guestName,
      guestPhone: data.guestPhone,
      numberOfGuests: data.numberOfGuests,
      startTime: data.startTime,
      createdAt: DateTime.now(), // Hoặc lấy từ data nếu có
      notes: data.notes,
      status: data.status,
    );
  }

  Future<TableReservation?> fetchReservationById(int reservationId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.44.2:8080/api/reservations/$reservationId'),
      );

      print("Trạng thái phản hồi API: ${response.statusCode}");
      print("Nội dung phản hồi API: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return TableReservation.fromJson(data);
      } else if (response.statusCode == 404) {
        // Không tìm thấy đặt bàn
        setState(() {
          hasNoReservation = true;
        });
        return null;
      } else {
        throw Exception('Không thể tải thông tin đặt bàn: ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi khi tải thông tin đặt bàn: $e");
      throw Exception('Lỗi khi tải thông tin đặt bàn: $e');
    }
  }

  void _handleCheckIn() {
    setState(() {
      isCheckedIn = true;
    });
  }

  void _handleCancel() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận hủy'),
          content: Text('Quý khách thực sự muốn hủy?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Không'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();

                // Gọi API để cập nhật trạng thái của reservation thành CANCELLED
                if (reservation != null && reservation!.id != null) {
                  try {
                    final response = await http.put(
                      Uri.parse('http://192.168.44.2:8080/api/reservations/${reservation!.id}/cancel'),
                      headers: {'Content-Type': 'application/json'},
                    );

                    if (response.statusCode == 200) {
                      print("Đã hủy đặt bàn thành công");
                    } else {
                      print("Không thể hủy đặt bàn: ${response.statusCode}");
                    }
                  } catch (e) {
                    print("Lỗi khi hủy đặt bàn: $e");
                  }
                }

                // Chuyển hướng sang màn hình lịch sử
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HistoryScreen()),
                );
              },
              child: Text('Có'),
            ),
          ],
        );
      },
    );
  }

  // Hàm tạo đơn hàng và chuyển đến thanh toán
  Future<void> createOrderAndGoToPayment(BuildContext context, TableReservation reservation) async {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final cartItems = cartProvider.items;

    if (cartItems.isEmpty) {
      setState(() {
        errorMessage = 'Chưa có món nào được đặt. Vui lòng thêm món vào giỏ hàng.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có món nào được đặt. Vui lòng thêm món vào giỏ hàng.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      isCreatingOrder = true;
      errorMessage = null;
    });

    try {
      double totalAmount = cartProvider.totalAmount;

      final List<Map<String, dynamic>> orderItems = [];
      cartItems.forEach((productId, cartItem) {
        orderItems.add({
          'productId': productId,
          'quantity': cartItem.quantity,
          'price': cartItem.price,
        });
      });

      final reservationIdToUse = widget.reservationId ?? reservation.id;

      if (reservationIdToUse == null) {
        throw Exception('Không tìm thấy reservationId');
      }

      final orderData = {
        'reservationId': reservationIdToUse,
        'items': orderItems,
        'totalAmount': totalAmount,
        'status': 'PENDING',
      };

      print('Gửi dữ liệu đơn hàng: ${json.encode(orderData)}');

      final response = await http.post(
        Uri.parse('http://192.168.44.2:8080/api/orders'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(orderData),
      );

      print('Trạng thái phản hồi: ${response.statusCode}');
      print('Nội dung phản hồi: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final createdOrder = json.decode(response.body);
        final orderId = createdOrder['id'].toString();

        cartProvider.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(
              amount: totalAmount,
              orderId: orderId,
            ),
          ),
        );
      } else {
        setState(() {
          isCreatingOrder = false;
          errorMessage = 'Không thể tạo đơn hàng. Mã lỗi: ${response.statusCode}';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tạo đơn hàng. Mã lỗi: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isCreatingOrder = false;
        errorMessage = 'Đã xảy ra lỗi: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xảy ra lỗi: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Hàm chuyển đến màn hình đặt bàn
  void _navigateToReservationScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReservationScreen()),
    ).then((_) {
      // Sau khi quay lại từ màn hình ReservationScreen, kiểm tra lại dữ liệu
      setState(() {
        if (widget.reservationId != null) {
          futureReservation = fetchReservationById(widget.reservationId!);
          hasNoReservation = false;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('HH:mm');

    final cartProvider = Provider.of<CartProvider>(context);
    final cartItems = cartProvider.items;

    return TemplateScreen(
      currentIndex: 2,
      reservationId: widget.reservationId,
      child: FutureBuilder<TableReservation?>(
        future: futureReservation,
        builder: (context, snapshot) {
          // Hiển thị loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Hiển thị thông báo khi chưa đặt bàn
          if (hasNoReservation || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Bạn chưa đặt bàn",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: _navigateToReservationScreen,
                    child: const Text('Đặt bàn ngay'),
                  ),
                ],
              ),
            );
          }
          else if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final displayReservation = reservation ?? snapshot.data!;

          // Tính thời gian đã sử dụng
          final duration = DateTime.now().difference(displayReservation.createdAt);
          final usedTime = '${duration.inHours} giờ ${duration.inMinutes % 60} phút';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isCheckedIn ? "Bàn đang sử dụng" : "Thông tin đặt bàn",
                      style: TextStyle(
                          fontSize: 20,
                          color: isCheckedIn ? Colors.green : Colors.blue,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    // Hiển thị hai nút Đã đến và Hủy khi chưa check-in
                    if (!isCheckedIn)
                      Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _handleCheckIn,
                            child: Text('Đã đến'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            onPressed: _handleCancel,
                            child: Text('Hủy'),
                          ),
                        ],
                      ),
                    // Hiển thị status "Đang sử dụng" khi đã check-in
                    if (isCheckedIn)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          "Đang sử dụng",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isCheckedIn ? Colors.green.shade100 : Colors.blue.shade100, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Bàn số ${displayReservation.id?.toString().padLeft(2, '0') ?? 'N/A'}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCheckedIn ? Colors.green : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      InfoRow(label: "Tên khách hàng", value: displayReservation.guestName),
                      InfoRow(label: "Số điện thoại", value: displayReservation.guestPhone),
                      InfoRow(label: "Số lượng khách", value: "${displayReservation.numberOfGuests} người"),
                      InfoRow(label: "Ngày đặt", value: dateFormat.format(displayReservation.startTime)),
                      InfoRow(label: "Giờ đặt", value: timeFormat.format(displayReservation.startTime)),
                      if (isCheckedIn) InfoRow(label: "Giờ check-in", value: timeFormat.format(displayReservation.createdAt)),
                      if (isCheckedIn) InfoRow(label: "Thời gian đã sử dụng", value: usedTime),
                      InfoRow(
                          label: "Ưu đãi",
                          value: displayReservation.notes.contains("sinh nhật") ? "Ưu đãi sinh nhật" : "Không"
                      ),
                      InfoRow(
                          label: "Ghi chú",
                          value: displayReservation.notes.isNotEmpty ? displayReservation.notes : "Không có"
                      ),
                    ],
                  ),
                ),

                // Phần hiển thị món đã đặt và các nút chức năng
                if (isCheckedIn) ...[
                  const SizedBox(height: 20),
                  const Text(
                      "Món đã đặt",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      )
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: cartItems.isEmpty
                        ? const Center(
                      child: Text(
                        "Chưa có món nào được đặt",
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                    )
                        : Column(
                      children: [
                        ...cartItems.entries.map((entry) {
                          final item = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: NetworkImage(item.image),
                                      fit: BoxFit.cover,
                                      onError: (obj, stackTrace) {
                                        // Xử lý khi hình ảnh không tải được
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${item.price.toStringAsFixed(0)}đ x ${item.quantity}',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${(item.price * item.quantity).toStringAsFixed(0)}đ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Tổng cộng:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${cartProvider.totalAmount.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(
                      "Gọi món",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => OrderScreen()),
                      ).then((_) {
                        setState(() {});
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.payment),
                    label: Text(
                      isCreatingOrder ? "Đang xử lý..." : "Thanh toán",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    onPressed: isCreatingOrder
                        ? null
                        : () => createOrderAndGoToPayment(context, displayReservation),
                  ),
                ],
                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class TableReservation {
  final int? id;
  final String guestName;
  final String guestPhone;
  final int numberOfGuests;
  final DateTime startTime;
  final DateTime createdAt;
  final String notes;
  final String status;

  TableReservation({
    this.id,
    required this.guestName,
    required this.guestPhone,
    required this.numberOfGuests,
    required this.startTime,
    required this.createdAt,
    required this.notes,
    required this.status,
  });

  factory TableReservation.fromJson(Map<String, dynamic> json) {
    return TableReservation(
      id: json['id'],
      guestName: json['guestName'] ?? '',
      guestPhone: json['guestPhone'] ?? '',
      numberOfGuests: json['numberOfGuests'] ?? 0,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'])
          : DateTime.now(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      notes: json['notes'] ?? '',
      status: json['status'] ?? '',
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              flex: 3,
              child: Text(
                  "$label:",
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                  )
              )
          ),
          Expanded(
              flex: 5,
              child: Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  )
              )
          ),
        ],
      ),
    );
  }
}