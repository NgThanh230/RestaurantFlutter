import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:test2/screen/template.dart';
import 'package:test2/screen/cart/cart_provider.dart';

import '../../model/Category.dart';
import '../../model/dish.dart';


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
      final categoryResponse = await http.get(Uri.parse('http://localhost:8080/api/categories'));

      if (categoryResponse.statusCode == 200) {
        try {

          final categoryData = json.decode(utf8.decode(categoryResponse.bodyBytes));
          Map<int, Category> categoriesMap = {};

          for (var categoryJson in categoryData) {
            final categoryId = categoryJson['categoryId'] ?? 0;
            final categoryName = categoryJson['name'] ?? 'Unknown';
            final categoryImage = categoryJson['imageUrl'] ?? '';

            categoriesMap[categoryId] = Category(
              id: categoryId,
              name: categoryName,
              image: categoryImage,
              products: [],
            );
          }

          final dishResponse = await http.get(Uri.parse('http://localhost:8080/api/dishes'));

          if (dishResponse.statusCode == 200) {

            final dishData = json.decode(utf8.decode(dishResponse.bodyBytes));


            for (var dishJson in dishData) {
              final categoryId = dishJson['categoryId'] ?? 0;

              if (categoryId != null) {
                categoriesMap[categoryId]?.products.add(Dish.fromJson(dishJson));
              } else {
                print('Danh mục ID: $categoryId không tồn tại trong categoriesMap!');
              }
            }

            // 5. Cập nhật giao diện
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
          } else {
            print('Lỗi tải món ăn: ${dishResponse.statusCode}');
            setState(() {
              isLoading = false;
              errorMessage = 'Lỗi tải món ăn: ${dishResponse.statusCode}';
            });
          }
        } catch (e) {
          print('Lỗi trong quá trình parse danh mục: $e');
          setState(() {
            isLoading = false;
            errorMessage = 'Lỗi parse danh mục: $e';
          });
        }
      } else {
        print('Lỗi tải danh mục: ${categoryResponse.statusCode}');
        setState(() {
          isLoading = false;
          errorMessage = 'Lỗi tải danh mục: ${categoryResponse.statusCode}';
        });
      }
    } catch (e) {
      print('Lỗi kết nối hoặc ngoại lệ không xác định: $e');
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
                          category.name,
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
              categories[selectedIndex].name,
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
  Widget _buildProductItem(BuildContext context, Dish product) {
    final id = product.id;
    final name = product.name;
    final price = product.price.toDouble();
    final formattedPrice = formatCurrency(price);
    final quantity = getQuantity(name);
    final description = product.description;
    final imageUrl = product.image ?? '';

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
                    id.toString(),
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