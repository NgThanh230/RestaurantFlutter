import 'package:flutter/foundation.dart';
import 'package:test2/model/cartmodel.dart';

class CartProvider with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
  }

  void addItem(String productId, String name, double price, String image) {
    if (_items.containsKey(productId)) {
      _items.update(
        productId,
            (existingCartItem) => existingCartItem.copyWith(quantity: existingCartItem.quantity + 1),
      );
    } else {
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

  List<Map<String, dynamic>> getOrderItems() {
    return _items.values.map((item) => {
      'dishId': int.tryParse(item.id), // quan trọng
      'quantity': item.quantity,
    }).toList();
  }
}