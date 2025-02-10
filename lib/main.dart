import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/map.dart';
import 'pages/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ad/ad_banner.dart';
import 'pages/home.dart';
import 'dart:convert';
import 'pages/posts.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/subscription_state.dart';
import 'pages/create_account.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/seichi_de_dekirukoto.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'ad/ad_app_open.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final config = await loadConfig();
  final configuration = PurchasesConfiguration(
    Platform.isAndroid
        ? config['revenueCatApiKeyAndroid']
        : config['revenueCatApiKeyiOS'],
  );

  String appUserId = await _getOrCreateAppUserId();

  await Purchases.configure(configuration..appUserID = appUserId);

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

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  late AppOpenAdManager appOpenAdManager;

  @override
  void initState() {
    super.initState();
    appOpenAdManager = AppOpenAdManager(ref: ref);
    appOpenAdManager.loadAd();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(subscriptionProvider.notifier).checkSubscription();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appOpenAdManager.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appOpenAdManager.showAdIfAvailable();
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'アニメ聖地マップ - Seichi',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ja', ''),
        Locale('en', ''),
        Locale('zh', ''),
        Locale('ko', ''),
        Locale('fr', ''),
      ],
      locale: currentLocale,
      home: const AppWithBottomNavigation(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppWithBottomNavigation extends ConsumerStatefulWidget {
  const AppWithBottomNavigation({super.key});

  @override
  ConsumerState<AppWithBottomNavigation> createState() =>
      AppWithBottomNavigationState();
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstLaunch();
    });
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

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch && mounted) {
      await prefs.setBool('is_first_launch', false);
      SeichiDeDekirukoto.show(context);
    }
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
      const PostsPage(),
      _isLoggedIn ? const ProfilePage() : const CreateAccountPage(),
    ];
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
        final isFirstRouteInCurrentTab =
            !await _navigatorKeys[_selectedIndex].currentState!.maybePop();
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
                final isSubscribed =
                    ref.watch(subscriptionProvider).value == true;
                return isSubscribed ? const SizedBox() : const AdBanner();
              },
            ),
            BottomNavigationBar(
              items: <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home),
                  label: AppLocalizations.of(context)!.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map),
                  label: AppLocalizations.of(context)!.map,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.post_add),
                  label: AppLocalizations.of(context)!.posts,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: AppLocalizations.of(context)!.profile,
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
