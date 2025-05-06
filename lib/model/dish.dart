class Dish {
  final String id;   // Đổi từ int -> String
  final String name;
  final double price;
  final String image;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'].toString(),    // ép toString() ở đây
      name: json['name'],
      price: json['price'].toDouble(),
      image: json['image'],
    );
  }
}
