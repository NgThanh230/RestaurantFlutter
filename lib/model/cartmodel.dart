// Đây là mã giả định cho model/cartmodel.dart
class CartItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String image;
  // Không cần thuộc tính dishId riêng biệt vì sẽ sử dụng id

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });

  // Hàm copyWith để tạo bản sao với các thuộc tính có thể thay đổi
  CartItem copyWith({
    String? id,
    String? name,
    double? price,
    int? quantity,
    String? image,
  }) {
    return CartItem(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
    );
  }
}