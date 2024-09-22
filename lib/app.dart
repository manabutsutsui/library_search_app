import 'package:flutter/material.dart';
import 'main.dart';
import 'login.dart';
import 'profile.dart';

class AppWithBottomNavigation extends StatefulWidget {
  const AppWithBottomNavigation({Key? key}) : super(key: key);

  @override
  _AppWithBottomNavigationState createState() => _AppWithBottomNavigationState();
}

class _AppWithBottomNavigationState extends State<AppWithBottomNavigation> {
  int _selectedIndex = 0;

  // ログイン状態を追跡する変数
  bool _isLoggedIn = false;

  // ページリストを動的に更新するメソッド
  List<Widget> _getPages() {
    return <Widget>[
      const MyHomePage(),
      _isLoggedIn ? ProfilePage(onLogoutSuccess: _handleLogoutSuccess) : LoginPage(onLoginSuccess: _handleLoginSuccess),
    ];
  }

  // ログイン成功時に呼び出されるコールバック
  void _handleLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
  }

  void _handleLogoutSuccess() {
    setState(() {
      _isLoggedIn = false;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = _getPages();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: '地図',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'プロフィール',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}