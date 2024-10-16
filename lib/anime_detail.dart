import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'anime_lists.dart';
import 'spot_detail.dart';

class AnimeDetailPage extends StatefulWidget {
  final AnimeList anime;

  const AnimeDetailPage({Key? key, required this.anime}) : super(key: key);

  @override
  _AnimeDetailPageState createState() => _AnimeDetailPageState();
}

class _AnimeDetailPageState extends State<AnimeDetailPage> {
  List<DocumentSnapshot> _spots = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSpots();
  }

  Future<void> _fetchSpots() async {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('spots')
        .where('work', isEqualTo: widget.anime.name)
        .get();
    setState(() {
      _spots = snapshot.docs;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.anime.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(widget.anime.imageAsset),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    onTap: () => _launchURL(widget.anime.imageUrl),
                    child: Center(
                      child: Text(
                        '出典元: ${widget.anime.imageUrl}',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(child: Text("'${widget.anime.name}'の聖地一覧", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 32),
                  Center(child: Text('聖地数: ${_spots.length}件', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _spots.isEmpty
                          ? const Center(child: Text('聖地が見つかりませんでした'))
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _spots.length,
                              itemBuilder: (context, index) {
                                final spot = _spots[index];
                                return Card(
                                  child: ListTile(
                                    title: Text(spot['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Text(spot['address']),
                                    trailing: const Icon(Icons.arrow_forward_ios),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SpotDetailPage(spot: spot),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'URLを開けませんでした: $url';
    }
  }
}
