import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'map.dart';
import 'login.dart';
import 'profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ad/ad_banner.dart';
import 'home.dart';
import 'dart:convert';
import 'registration.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'provider/subscription_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  const isDebug = !bool.fromEnvironment('dart.vm.product');
  
  final config = await loadConfig();
  final configuration = PurchasesConfiguration(
    Platform.isAndroid
      ? config['revenueCatApiKeyAndroid']
      : config['revenueCatApiKeyiOS'],
  );
  
  String appUserId = await _getOrCreateAppUserId();
  
  await Purchases.configure(configuration..appUserID = appUserId);
  
  Purchases.setDebugLogsEnabled(isDebug);

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

Future<Map<String, dynamic>> loadConfig() async {
  final configString = await rootBundle.loadString('assets/config/config.json');
  return json.decode(configString);
}

Future<String> _getOrCreateAppUserId() async {
  final prefs = await SharedPreferences.getInstance();
  String? appUserId = prefs.getString('app_user_id');
  
  if (appUserId == null) {
    appUserId = const Uuid().v4();
    await prefs.setString('app_user_id', appUserId);
  }
  
  return appUserId;
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).checkSubscription();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '映画&アニメ聖地SNS',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AppWithBottomNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWithBottomNavigation extends ConsumerStatefulWidget {
  const AppWithBottomNavigation({super.key});

  @override
  ConsumerState<AppWithBottomNavigation> createState() => AppWithBottomNavigationState();
}

class AppWithBottomNavigationState extends ConsumerState<AppWithBottomNavigation> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;
  late List<Widget> _pages;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
    _auth.authStateChanges().listen((User? user) {
      _updateLoginStatus(user != null);
    });
    _navigatorKeys = [
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
    ];
    _updatePages();
  }

  void _checkLoginStatus() {
    final user = _auth.currentUser;
    _updateLoginStatus(user != null);
  }

  void _updateLoginStatus(bool isLoggedIn) {
    setState(() {
      _isLoggedIn = isLoggedIn;
      _updatePages();
    });
  }

  void _updatePages() {
    _pages = [
      const Home(),
      const MapPage(),
      const RegistrationPage(),
      _isLoggedIn ? const ProfilePage() : LoginPage(onLoginSuccess: _handleLoginSuccess),
    ];
  }

  void _handleLoginSuccess() {
    _updateLoginStatus(true);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
        if (isFirstRouteInCurrentTab) {
          if (_selectedIndex != 0) {
            _onItemTapped(0);
            return false;
          }
        }
        return isFirstRouteInCurrentTab;
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _pages.asMap().entries.map((entry) {
            return Navigator(
              key: _navigatorKeys[entry.key],
              onGenerateRoute: (settings) {
                Widget page;
                if (settings.name == '/') {
                  page = entry.value;
                } else {
                  page = const Scaffold(body: Center(child: Text('404')));
                }
                return MaterialPageRoute(builder: (_) => page);
              },
            );
          }).toList(),
        ),
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer(
              builder: (context, ref, child) {
                final isSubscribed = ref.watch(subscriptionProvider).value == true;
                return isSubscribed ? const SizedBox() : const AdBanner();
              },
            ),
            BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'ホーム',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: '地図',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.favorite),
                  label: '登録',
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
          ],
        ),
      ),
    );
  }
}