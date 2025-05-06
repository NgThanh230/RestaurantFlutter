import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:test2/screen/cart/cart_provider.dart';
import 'package:test2/screen/booking/reservation.dart';
import 'package:test2/screen/template.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  List<Map<String, dynamic>> slideItems = [];
  List<Map<String, dynamic>> promotions = [];
  Timer? _carouselTimer;
  final LatLng restaurantLocation = LatLng(21.028925059383504, 105.78188583609558);

  @override
  void initState() {
    super.initState();
    fetchData();
    _carouselTimer = Timer.periodic(Duration(seconds: 3), (Timer timer) {
      if (mounted && _pageController.hasClients && slideItems.isNotEmpty) {
        _currentPage = (_currentPage + 1) % slideItems.length;
        _pageController.animateToPage(
          _currentPage,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeIn,
        );
      }
    });
  }

  Future<void> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/api/dishes'),
        headers: {
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));

        final slideDishes = data
            .where((dish) =>
        dish['category'] != null &&
            dish['category']['categoryId'] == 10)
            .take(5)
            .toList();
        print(slideDishes);
        final promotionDishes = data
            .where((dish) =>
        dish['category'] != null &&
            dish['category']['categoryId'] == 10)
            .take(5)
            .toList();

        if (!mounted) return;

        setState(() {
          slideItems = List<Map<String, dynamic>>.from(slideDishes);
          promotions = List<Map<String, dynamic>>.from(promotionDishes);
          print("Slide items count: ${slideItems.length}");
        });
      } else {
        print('Lỗi response: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi khi fetch data: $e');
    }
  }


  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }


  String formatCurrency(double price) {
    final formatter = NumberFormat('#,###', 'vi_VN');
    return formatter.format(price).replaceAll(',', '.');
  }

  @override
  Widget build(BuildContext context) {
    return TemplateScreen(
      currentIndex: 0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16),
            if (slideItems.isNotEmpty) _buildAutoSlide(),
            _buildSectionTitle('Khuyến mại đặc biệt'),
            _buildPromotionSection(),
            _buildReservationButton(),
            _buildSectionTitle('Địa chỉ nhà hàng'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'Gourmet, số 8 Tôn Thất Thuyết, Cầu Giấy, Hà Nội',
                style: TextStyle(fontSize: 16),
              ),
            ),
            _buildMap(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAutoSlide() {
    return Container(
      height: 200,
      child: PageView.builder(
        controller: _pageController,
        itemCount: slideItems.length,
        itemBuilder: (context, index) {
          final item = slideItems[index];
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(item['imageUrl'] as String? ?? ''),
                fit: BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionSection() {
    if (promotions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: promotions.map((item) {
          double price = (item['price'] as num).toDouble();
          double originalPrice = price * 1.2; // Giá gốc = giá hiện tại * 1.2
          String formattedPrice = formatCurrency(price);
          String formattedOriginalPrice = formatCurrency(originalPrice);

          return GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Text(item['name'], style: TextStyle(fontWeight: FontWeight.bold)),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item['imageUrl'] ?? '', height: 180, fit: BoxFit.cover),
                        ),
                        SizedBox(height: 12),
                        Text(
                          item['description'] ?? 'Không có mô tả',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${formattedOriginalPrice}đ',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '${formattedPrice}đ',
                              style: TextStyle(fontSize: 16, color: Colors.red, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Đóng'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Provider.of<CartProvider>(context, listen: false).addItem(
                          item['dishId'].toString(),
                          item['name'],
                          price,
                          item['imageUrl'] ?? '',
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm vào giỏ hàng!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF8EA383)),
                      child: Text('Thêm vào giỏ'),
                    ),
                  ],
                ),
              );
            },
            child: Container(
              margin: EdgeInsets.only(right: 16, left: 16),
              width: MediaQuery.of(context).size.width * 0.48,
              height: 320,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), spreadRadius: 1, blurRadius: 5)],
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        image: DecorationImage(
                          image: NetworkImage(item['imageUrl'] as String? ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Expanded(
                            child: Text(
                              item['description'] ?? 'Không có mô tả',
                              style: TextStyle(fontSize: 12),
                              maxLines: 5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${formattedOriginalPrice}đ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    '${formattedPrice}đ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              QuantitySelector(
                                onAdd: (quantity) {
                                  for (int i = 0; i < quantity; i++) {
                                    Provider.of<CartProvider>(context, listen: false).addItem(
                                      item['dishId'].toString(),
                                      item['name'],
                                      price,
                                      item['imageUrl'] ?? '',
                                    );
                                  }
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Đã thêm $quantity sản phẩm vào giỏ hàng!'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildReservationButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 24.0),
      child: Center(
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 32,
          height: 50, // 1/4 của slide (slide height = 200)
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ReservationScreen()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF8EA383),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Đặt bàn',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 250,
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 7)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            center: restaurantLocation,
            zoom: 16.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.app',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: restaurantLocation,
                  width: 40,
                  height: 40,
                  child: Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class QuantitySelector extends StatefulWidget {
  final Function(int) onAdd;

  const QuantitySelector({
    Key? key,
    required this.onAdd,
  }) : super(key: key);

  @override
  _QuantitySelectorState createState() => _QuantitySelectorState();
}

class _QuantitySelectorState extends State<QuantitySelector> {
  int quantity = 0;
  bool isAdding = false;

  final double buttonSize = 24.0;
  final double iconSize = 14.0;

  @override
  Widget build(BuildContext context) {
    if (!isAdding) {
      // Hiển thị nút + nhỏ hơn
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: ElevatedButton(
          onPressed: () {
            setState(() {
              isAdding = true;
              quantity = 1;
            });
            widget.onAdd(quantity);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF8EA383),
            shape: CircleBorder(),
            padding: EdgeInsets.zero,
          ),
          child: Icon(Icons.add, color: Colors.white, size: iconSize),
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(buttonSize/2),
          border: Border.all(color: Color(0xFF8EA383)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: buttonSize/2,
                icon: Icon(Icons.remove, size: iconSize, color: Color(0xFF8EA383)),
                onPressed: quantity > 1
                    ? () {
                  setState(() {
                    quantity--;

                    if (quantity <= 0) {
                      isAdding = false;
                      quantity = 0;
                    }
                  });

                  if (isAdding) {
                    widget.onAdd(quantity);
                  }
                }
                    : () {
                  setState(() {
                    isAdding = false;
                    quantity = 0;
                  });
                },
              ),
            ),
            // Hiển thị số lượng
            Container(
              width: buttonSize,
              alignment: Alignment.center,
              child: Text(
                '$quantity',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            // Nút tăng số lượng
            SizedBox(
              width: buttonSize,
              height: buttonSize,
              child: IconButton(
                padding: EdgeInsets.zero,
                splashRadius: buttonSize/2,
                icon: Icon(Icons.add, size: iconSize, color: Color(0xFF8EA383)),
                onPressed: () {
                  setState(() {
                    quantity++;
                  });
                  widget.onAdd(quantity);
                },
              ),
            ),
          ],
        ),
      );
    }
  }
}