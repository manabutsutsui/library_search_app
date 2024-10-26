import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:http/http.dart' as http;
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

// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   print('バックグラウンドで通知を受信しました: ${message.messageId}');
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  // late FirebaseMessaging _messaging;
  // late int _currentVersion;

  @override
  void initState() {
    super.initState();
    // _initialize();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).checkSubscription();
    });
  }

  // Future<void> _initialize() async {
  //   PackageInfo packageInfo = await PackageInfo.fromPlatform();
  //   _currentVersion = int.parse(packageInfo.buildNumber);

  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   int savedVersion = prefs.getInt('appVersion') ?? 0;

  //   if (_currentVersion > savedVersion) {
  //     await prefs.setInt('appVersion', _currentVersion);
  //     await notifyUpdate(_currentVersion);
  //   }

  //   _messaging = FirebaseMessaging.instance;

  //   NotificationSettings settings = await _messaging.requestPermission(
  //     alert: true,
  //     badge: true,
  //     sound: true,
  //   );

  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     // print('ユーザーは通知を許可しました');
  //     _getToken();
  //   } else {
  //     // print('ユーザーは通知を許可しませんでした');
  //   }

  //   FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //     if (message.notification != null) {
  //       showDialog(
  //         context: context,
  //         builder: (_) => AlertDialog(
  //           title: Text(message.notification!.title ?? '通知'),
  //           content: Text(message.notification!.body ?? ''),
  //           actions: [
  //             TextButton(
  //               onPressed: () => Navigator.of(context).pop(),
  //               child: const Text('閉じる'),
  //             ),
  //           ],
  //         ),
  //       );
  //     }
  //   });

  //   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  //     // print('通知をタップしてアプリが起動されました: ${message.messageId}');
  //   });
  // }

  // Future<void> _getToken() async {
  //   String? token = await _messaging.getToken();
  //   if (token != null) {
  //     // print('FCM トークン: $token');
  //     await sendTokenToServer(token);
  //   }
  // }

  // Future<void> sendTokenToServer(String token) async {
  //   final url = Uri.parse('https://us-central1-movie-and-anime-holy-land.cloudfunctions.net/saveToken');

  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({'token': token}),
  //   );

  //   if (response.statusCode == 200) {
  //     print('トークンをサーバーに正常に送信しました');
  //   } else {
  //     print('トークンの送信に失敗しました: ${response.statusCode}');
  //   }
  // }

  // Future<void> notifyUpdate(int version) async {
  //   final url = Uri.parse('https://us-central1-movie-and-anime-holy-land.cloudfunctions.net/notifyUpdate');

  //   final response = await http.post(
  //     url,
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({'version': version.toString()}),
  //   );

  //   if (response.statusCode == 200) {
  //     print('アップデート通知が正常に送信されました');
  //   } else {
  //     print('アップデート通知の送信に失敗しました: ${response.statusCode}');
  //   }
  // }

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
  const AppWithBottomNavigation({Key? key}) : super(key: key);

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
            const AdBanner(),
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