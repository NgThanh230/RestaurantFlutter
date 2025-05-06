class Dish {
  final int id;
  final String name;
  final String description;
  final int price;
  final String? image;

  Dish({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.image,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['dishId'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      image: json['imageUrl'],
    );
  }

}
