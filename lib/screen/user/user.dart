import 'package:flutter/material.dart';
import 'package:test2/screen/template.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TemplateScreen(
      currentIndex: 0, // Icon tương ứng với Home
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hai nút "Đặt bàn" và "Giao đi"
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic "Đặt bàn"
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8EA383),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Đặt bàn'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Logic "Giao đi"
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF8EA383),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Giao đi'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Slide tự động
            SizedBox(
              height: 180,
              child: PageView(
                children: [
                  _buildSlide('assets/img/food/comboga.jpg'),
                  _buildSlide('assets/img/food/comboham.jpg'),
                  _buildSlide('assets/img/food/combosteak.jpg'),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Khuyến mại đặc biệt
            Text(
              'Khuyến mại đặc biệt',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPromotionItem('assets/img/food/bwelinton.jpg'),
                  _buildPromotionItem('assets/img/food/ham.jpg'),
                  _buildPromotionItem('assets/img/food/kfc.jpg'),
                  _buildPromotionItem('assets/img/food/spgt.jpg'),
                  _buildPromotionItem('assets/img/food/steak.jpg'),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Tin tức
            Text(
              'Tin tức',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(5, (index) {
                  return _buildNewsItem('News ${index + 1}');
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget cho từng slide
  Widget _buildSlide(String imagePath) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Widget cho item Khuyến mại
  Widget _buildPromotionItem(String imagePath) {
    return Container(
      width: 150,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Widget cho item Tin tức
  Widget _buildNewsItem(String title) {
    return Container(
      width: 100,
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.lightBlueAccent,
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
