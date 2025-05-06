import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test2/screen/template.dart';
import 'package:test2/screen/cart/cart_provider.dart';

// Model Category
class Category {
  final int id;
  final String title;
  final String? image;
  final List<dynamic> products;

  Category({
    required this.id,
    required this.title,
    this.image,
    required this.products,
  });
}

class OrderScreen extends StatefulWidget {
  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  int selectedIndex = 0;
  Map<String, int> productQuantities = {};
  List<Category> categories = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.44.2:8080/api/dishes'));

      if (response.statusCode == 200) {
        try {
          final data = json.decode(utf8.decode(response.bodyBytes));
          Map<int, Category> categoriesMap = {};

          for (var dish in data) {
            final categoryId = dish['category']?['categoryId'] is int
                ? dish['category']['categoryId']
                : int.tryParse(dish['category']?['categoryId'].toString() ?? '') ?? 0;

            if (categoryId == 100) continue;

            final categoryMap = dish['category'] ?? {};
            final categoryName = categoryMap['name'] ?? 'Unknown';
            final categoryImage = categoryMap['imageUrl'] ?? '';

            categoriesMap.putIfAbsent(
              categoryId,
                  () => Category(
                id: categoryId,
                title: categoryName,
                image: categoryImage,
                products: [],
              ),
            );

            categoriesMap[categoryId]!.products.add({
              'id': dish['id'],
              'name': dish['name'],
              'description': dish['description'],
              'price': dish['price'],
              'image': dish['imageUrl'],
            });

          }

          if (mounted) {
            setState(() {
              categories = categoriesMap.values.toList();

              final customOrder = [80, 90];
              categories.sort((a, b) {
                int indexA = customOrder.indexOf(a.id);
                int indexB = customOrder.indexOf(b.id);

                if (indexA == -1) indexA = customOrder.length + a.id;
                if (indexB == -1) indexB = customOrder.length + b.id;

                return indexA.compareTo(indexB);
              });

              isLoading = false;
              errorMessage = '';
            });
          }
        } catch (e) {
          setState(() {
            isLoading = false;
            errorMessage = 'Lỗi parse JSON: $e';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi tải dữ liệu: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Lỗi kết nối: $e';
      });
    }
  }

  int getQuantity(String productName) => productQuantities[productName] ?? 0;

  void updateQuantity(String productName, bool increase) {
    setState(() {
      productQuantities[productName] = getQuantity(productName) + (increase ? 1 : -1);
      if (productQuantities[productName]! < 0) {
        productQuantities[productName] = 0;
      }
    });
  }

  String formatCurrency(double price) {
    String priceString = price.toInt().toString();
    String result = '';
    int count = 0;

    for (int i = priceString.length - 1; i >= 0; i--) {
      count++;
      result = priceString[i] + result;
      if (count % 3 == 0 && i > 0) {
        result = '.' + result;
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return TemplateScreen(
      currentIndex: 1,
      child: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
          ? Center(child: Text(errorMessage))
          : categories.isEmpty
          ? const Center(child: Text('Không có danh mục nào'))
          : ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Danh mục',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 140,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = selectedIndex == index;
                return InkWell(
                  onTap: () => setState(() => selectedIndex = index),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              category.image ?? '',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.fastfood, size: 40);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          category.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              categories[selectedIndex].title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          ...categories[selectedIndex].products
              .map((product) => _buildProductItem(context, product))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildProductItem(BuildContext context, Map<String, dynamic> product) {
    final name = product['name'] ?? '';
    final price = double.tryParse(product['price']?.toString() ?? '0') ?? 0;
    final formattedPrice = formatCurrency(price);
    final quantity = getQuantity(name);
    final description = product['description'] ?? '';
    final imageUrl = product['image'] ?? '';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (_) {
            return AlertDialog(
              backgroundColor: Colors.white,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(Icons.fastfood, size: 40),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(name, style: TextStyle(fontSize: 20)),
                  const SizedBox(height: 10),
                  Text('Giá: ${formattedPrice}đ'),
                  const SizedBox(height: 10),
                  Text(description),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Đóng'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: ListTile(
          leading: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                const Center(child: Icon(Icons.fastfood, size: 30)),
              ),
            ),
          ),
          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${formattedPrice}đ',
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quantity > 0) ...[
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.green),
                  onPressed: () {
                    updateQuantity(name, false);
                    Provider.of<CartProvider>(context, listen: false).removeItem(name);
                  },
                ),
                SizedBox(
                  width: 24,
                  child: Text(
                    '$quantity',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                onPressed: () {
                  updateQuantity(name, true);
                  Provider.of<CartProvider>(context, listen: false).addItem(
                    "${product['id']}_$name",
                    name,
                    price,
                    imageUrl,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đã thêm $name vào giỏ hàng'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
                },
              ),
            ],
          ),
          isThreeLine: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}