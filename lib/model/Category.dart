import 'dish.dart';

class Category {
  final int id;
  final String name;
  final String? image;
  final List<Dish> products;

  Category({
    required this.id,
    required this.name,
    this.image,
    required this.products,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] ?? 0, // fallback nếu id null
      name: json['title'] ?? '',
      image: json['image'],
      products: (json['products'] as List<dynamic>? ?? [])
          .map((item) => Dish.fromJson(item))
          .toList(),
    );
  }
}
