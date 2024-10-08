import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class RecommendedProductsListPage extends StatefulWidget {
  const RecommendedProductsListPage({Key? key}) : super(key: key);

  @override
  _RecommendedProductsListPageState createState() => _RecommendedProductsListPageState();
}

class _RecommendedProductsListPageState extends State<RecommendedProductsListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchProducts('人気アニメ グッズ');
  }

  Future<String> _loadRakutenApplicationId() async {
    final String jsonString = await rootBundle.loadString('assets/config/config.json');
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return jsonMap['rakutenApplicationId'];
  }

  Future<void> _fetchProducts(String keyword) async {
    setState(() {
      _isLoading = true;
    });

    final String applicationId = await _loadRakutenApplicationId();
    final String encodedKeyword = Uri.encodeComponent(keyword);
    final response = await http.get(Uri.parse(
        'https://app.rakuten.co.jp/services/api/IchibaItem/Search/20170706?applicationId=$applicationId&keyword=$encodedKeyword&hits=30'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _products = data['Items'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
      throw Exception('楽天APIからデータの取得に失敗しました');
    }
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw '商品ページを開けませんでした: $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('おすすめ商品', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '商品を検索',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    _fetchProducts(_searchController.text);
                  },
                ),
              ),
              onSubmitted: (value) {
                _fetchProducts(value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final item = _products[index]['Item'];
                      return GestureDetector(
                        onTap: () => _launchURL(item['itemUrl']),
                        child: Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                item['mediumImageUrls'][0]['imageUrl'],
                                height: 120,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemName'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '¥${item['itemPrice']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
