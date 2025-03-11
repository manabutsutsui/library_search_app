import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pages/map.dart';
import 'pages/profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ad/ad_banner.dart';
import 'pages/home.dart';
import 'pages/ranking.dart';
import 'pages/anime_more.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/subscription_state.dart';
import 'pages/create_account.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/locale_provider.dart';
import 'ad/ad_app_open.dart';
import 'providers/login_bonus_provider.dart';
import 'utils/login_bonus_dialog.dart';
import 'providers/points_provider.dart';

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

class AppWithBottomNavigationState
    extends ConsumerState<AppWithBottomNavigation> {
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
      GlobalKey<NavigatorState>(),
    ];
    _updatePages();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLoginBonus();
    });
  }

  void _checkLoginBonus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await ref.read(loginBonusProvider.notifier).checkAndUpdateLoginBonus();
      await ref.read(pointsProvider.notifier).loadPoints();
      final loginBonusState = ref.read(loginBonusProvider);

      if (loginBonusState.hasTodayBonus) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const LoginBonusDialog(),
          );
        }
      }
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
      const AnimeMorePage(),
      const RankingPage(),
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
                  icon: const Icon(
                    Icons.home,
                  ),
                  label: AppLocalizations.of(context)!.home,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.map),
                  label: AppLocalizations.of(context)!.map,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.work),
                  label: AppLocalizations.of(context)!.works,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.emoji_events),
                  label: AppLocalizations.of(context)!.ranking,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.person),
                  label: AppLocalizations.of(context)!.profile,
                ),
              ],
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: Colors.blue,
              selectedLabelStyle: const TextStyle(fontSize: 12),
              unselectedLabelStyle: const TextStyle(fontSize: 10),
              onTap: _onItemTapped,
            ),
          ],
        ),
      ),
    );
  }
}
