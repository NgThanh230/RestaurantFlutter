import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:test2/screen/cart/cart_provider.dart';
import 'package:intl/intl.dart';

class CartItemWidget extends StatelessWidget {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image;
  final bool isEditable; // Thêm tham số isEditable

  // Sửa lỗi ở dòng 25: Thêm từ khóa const
  const CartItemWidget({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
    this.isEditable = true, // Mặc định cho phép chỉnh sửa
  });

  @override
  Widget build(BuildContext context) {
    final imgProvider = image.startsWith('http')
        ? NetworkImage(image)
        : AssetImage(image) as ImageProvider;

    final formatCurrency = NumberFormat('#,###', 'vi_VN');

    return Dismissible(
      key: ValueKey(id),
      background: Container(
        color: Theme.of(context).colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: const Icon(Icons.delete, color: Colors.white, size: 40),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        Provider.of<CartProvider>(context, listen: false).removeItem(id);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: ListTile(
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: imgProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(name),
            subtitle: Text('Tổng: ${formatCurrency.format(price * quantity)}đ'),
            trailing: isEditable
                ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove),
                  onPressed: () {
                    if (quantity > 1) {
                      Provider.of<CartProvider>(context, listen: false)
                          .updateQuantity(id, quantity - 1);
                    } else {
                      Provider.of<CartProvider>(context, listen: false)
                          .removeItem(id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Đã xóa món "$name" khỏi giỏ hàng'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),
                Text('$quantity'),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    Provider.of<CartProvider>(context, listen: false)
                        .updateQuantity(id, quantity + 1);
                  },
                ),
              ],
            )
                : null, // Nếu không cho phép chỉnh sửa, không hiển thị các nút
          ),
        ),
      ),
    );
  }
}