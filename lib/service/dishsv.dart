import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/dish.dart';

class DishService {
  static Future<List<Dish>> fetchDishes() async {
    final response = await http.get(Uri.parse('http://localhost:8080/api/dishes'));

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Dish.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load dishes');
    }
  }
}
