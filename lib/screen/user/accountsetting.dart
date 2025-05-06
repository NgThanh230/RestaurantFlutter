/*import 'package:flutter/material.dart';
import 'package:test2/screen/template.dart';
import 'package:test2/screen/welcome/login.dart';
import 'package:test2/screen/welcome/register.dart';
import 'package:test2/model/user.dart' as AppUser;

class User {
  final String name;
  final String imageUrl;

  User({required this.name, required this.imageUrl});
  factory User.fromAppUser(AppUser.User user) {
    return User(
      name: user.name, // Giả sử AppUser.User có thuộc tính name
      imageUrl: user.imageUrl ?? 'https://via.placeholder.com/60', // Giả sử AppUser.User có thuộc tính imageUrl
    );
  }
}

class AccountSettings extends StatefulWidget {
  const AccountSettings({Key? key}) : super(key: key);

  @override
  _AccountSettingsState createState() => _AccountSettingsState();
}

class _AccountSettingsState extends State<AccountSettings> {
  bool _isLoggedIn = false;
  User? _currentUser;

  @override
  Widget build(BuildContext context) {
    return TemplateScreen(
      currentIndex: 3,
      child: _isLoggedIn ? _buildLoggedInView() : _buildGuestView(),
    );
  }

  Widget _buildGuestView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Phần trên với nút đăng nhập/đăng ký
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _navigateToLogin(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8EA383),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Đăng nhập',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _navigateToRegister(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8EA383),
                    side: const BorderSide(color: Color(0xFF8EA383)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: const Text(
                    'Đăng ký',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          // Phần dưới với các tính năng
          Expanded(
            child: ListView(
              children: [
                _buildFeatureItem(
                  icon: Icons.notifications_outlined,
                  title: 'Thông báo',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Vui lòng đăng nhập')),
                    );
                  },
                ),
                _buildFeatureItem(
                  icon: Icons.help_outline,
                  title: 'Trợ giúp & Hỗ trợ',
                  onTap: () {},
                ),
                _buildFeatureItem(
                  icon: Icons.info_outline,
                  title: 'Về chúng tôi',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInView() {
    return Column(
      children: [
        // Profile section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: NetworkImage(_currentUser?.imageUrl ??
                    'https://via.placeholder.com/60'),
              ),
              const SizedBox(width: 16),
              Text(
                _currentUser?.name ?? 'User Name',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // Features list
        Expanded(
          child: ListView(
            children: [
              _buildFeatureItem(
                icon: Icons.person_outline,
                title: 'Thông tin cá nhân',
                onTap: () {},
              ),
              _buildFeatureItem(
                icon: Icons.notifications_outlined,
                title: 'Thông báo',
                onTap: () {},
              ),
              _buildFeatureItem(
                icon: Icons.help_outline,
                title: 'Trợ giúp & Hỗ trợ',
                onTap: () {},
              ),
              _buildFeatureItem(
                icon: Icons.info_outline,
                title: 'Về chúng tôi',
                onTap: () {},
              ),
              _buildFeatureItem(
                icon: Icons.logout,
                title: 'Đăng xuất',
                onTap: _handleLogout,
                isDestructive: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : const Color(0xFF8EA383),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen(
        onLoginSuccess: (AppUser.User user) {
          setState(() {
            _isLoggedIn = true;
            _currentUser = User.fromAppUser(user); // Chuyển đổi từ AppUser.User sang User
          });
          Navigator.pop(context);
        },
      )),
    );
  }

  void _navigateToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RegisterPage(
        onRegisterSuccess: (AppUser.User user) {
          setState(() {
            _isLoggedIn = true;
            _currentUser = User.fromAppUser(user); // Chuyển đổi từ AppUser.User sang User
          });
          Navigator.pop(context);
        },
      )),
    );
  }

  void _handleLogout() {
    setState(() {
      _isLoggedIn = false;
      _currentUser = null;
    });
  }
}*/