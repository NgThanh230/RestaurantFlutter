import 'package:flutter/foundation.dart';
import 'package:test2/screen/cart/cartmodel.dart';

class CartItem {
  final String id;        // ID món ăn (product ID)
  final String name;
  final double price;
  final int quantity;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
    required this.image,
  });
}

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  void addItem(String productId, String name, double price, String image) {
    if (_items.containsKey(productId)) {
      // Nếu sản phẩm đã có trong giỏ -> tăng số lượng
      _items.update(
        productId,
            (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: existingCartItem.quantity + 1,
          image: existingCartItem.image,
        ),
      );
    } else {
      // Nếu sản phẩm chưa có -> thêm mới
      _items.putIfAbsent(
        productId,
            () => CartItem(
          id: productId,
          name: name,
          price: price,
          quantity: 1,
          image: image,
        ),
      );
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void updateQuantity(String id, int newQuantity) {
    if (_items.containsKey(id)) {
      _items.update(
        id,
            (existingCartItem) => CartItem(
          id: existingCartItem.id,
          name: existingCartItem.name,
          price: existingCartItem.price,
          quantity: newQuantity,
          image: existingCartItem.image,
        ),
      );
      notifyListeners();
    }
  }

  void clear() {
    _items = {};
    notifyListeners();
  }

  // Hàm mới: build dữ liệu order để gửi server
  List<Map<String, dynamic>> getOrderItems() {
    return _items.values.map((cartItem) {
      return {
        'product_id': cartItem.id,
        'quantity': cartItem.quantity,
      };
    }).toList();
  }
}
