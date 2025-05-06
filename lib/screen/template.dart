import 'package:flutter/material.dart';
import 'package:test2/screen/home1/home.dart';
import 'package:test2/screen/order/order.dart';
import 'package:test2/screen/cart/cart_screen.dart';
import 'package:test2/screen/notification/notificationscreen.dart';
import 'package:test2/screen/booking/usingtable.dart';
import 'package:test2/screen/user/history.dart';  // Thêm import màn hình History

class TemplateScreen extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final int? reservationId;

  const TemplateScreen({
    required this.child,
    required this.currentIndex,
    this.reservationId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF8EA383),
        title: Center(
          child: Text(
            'GOURMET',
            style: TextStyle(fontFamily: 'SedgwickAve', fontSize: 24),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => CartScreen()),
              );
            },
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Color(0xFF8EA383),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == currentIndex) return;
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomePage()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => OrderScreen()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => UsingTableScreen(
                    reservationId: reservationId ?? null,
                  ),
                ),
              );
              break;
            case 3:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => NotificationScreen()),
              );
              break;
            case 4: // Điều hướng đến HistoryScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HistoryScreen()),
              );
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.fastfood),
            label: 'Đặt hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.table_bar),
            label: 'Table',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Lịch sử đơn hàng',
          ),
        ],
      ),
    );
  }
}
