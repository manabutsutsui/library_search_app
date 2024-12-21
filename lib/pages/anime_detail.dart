import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/anime_lists.dart';
import 'spot_detail.dart';

class AnimeDetailPage extends StatefulWidget {
  final AnimeList anime;

  const AnimeDetailPage({super.key, required this.anime});

  @override
  AnimeDetailPageState createState() => AnimeDetailPageState();
}

class AnimeDetailPageState extends State<AnimeDetailPage> {
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
    final l10n = AppLocalizations.of(context)!;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(widget.anime.name, 
          style: const TextStyle(
            fontWeight: FontWeight.bold, 
            fontSize: 16, 
            color: Colors.white
          )
        ),
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
                        '${l10n.sourceImage}: ${widget.anime.imageUrl}',
                        style: const TextStyle(
                          fontSize: 8,
                          color: Colors.blue,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "'${widget.anime.name}'${l10n.holyPlaceList}", 
                      style: const TextStyle(
                        fontSize: 20, 
                        fontWeight: FontWeight.bold
                      )
                    )
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '${l10n.numberOfHolyPlaces}: ${_spots.length}${l10n.places}', 
                      style: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold
                      )
                    )
                  ),
                  const SizedBox(height: 16),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _spots.isEmpty
                          ? Center(child: Text(l10n.noHolyPlacesFound))
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 8.0,
                                mainAxisSpacing: 8.0,
                                childAspectRatio: 1.3,
                              ),
                              itemCount: _spots.length,
                              itemBuilder: (context, index) {
                                final spot = _spots[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            SpotDetailPage(spot: spot),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: spot['imageURL'] != null &&
                                                spot['imageURL']
                                                    .toString()
                                                    .isNotEmpty
                                            ? ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  spot['imageURL'],
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            : Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 40,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Text(
                                        spot['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
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
    final l10n = AppLocalizations.of(context)!;
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw '${l10n.failedToOpenUrl}: $url';
    }
  }
}
