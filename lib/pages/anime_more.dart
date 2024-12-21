import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../utils/anime_lists.dart';
import 'anime_detail.dart';

class AnimeMorePage extends StatefulWidget {
  const AnimeMorePage({super.key});

  @override
  State<AnimeMorePage> createState() => _AnimeMorePageState();
}

class _AnimeMorePageState extends State<AnimeMorePage> {
  String? selectedGenre;
  late List<String> genres;

  @override
  void initState() {
    super.initState();
    genres = animeList.map((anime) => anime.genre).toSet().toList()..sort();
  }

  String _translateGenre(BuildContext context, String genre) {
    final l10n = AppLocalizations.of(context)!;
    switch (genre) {
      case '映画':
        return l10n.movie;
      case 'スポーツ/競技':
        return l10n.sports;
      case '恋愛/ラブコメ':
        return l10n.romance;
      case 'アクション/バトル':
        return l10n.action;
      case 'ホラー/サスペンス/推理':
        return l10n.horror;
      case '日常/ほのぼの':
        return l10n.daily;
      case 'ドラマ/青春':
        return l10n.drama;
      case 'SF/ファンタジー':
        return l10n.sf;
      default:
        return genre;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredAnimeList = selectedGenre == null
        ? animeList
        : animeList.where((anime) => anime.genre == selectedGenre).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          l10n.worksList,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              itemCount: genres.length,
              itemBuilder: (context, index) {
                final genre = genres[index];
                final isSelected = selectedGenre == genre;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(_translateGenre(context, genre)),
                    onSelected: (selected) {
                      setState(() {
                        selectedGenre = selected ? genre : null;
                      });
                    },
                    backgroundColor: Colors.white,
                    selectedColor: Colors.blue.withOpacity(0.2),
                    checkmarkColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: filteredAnimeList.isEmpty
                ? Center(child: Text(l10n.noWorksFound))
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GridView.builder(
                      itemCount: filteredAnimeList.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 1.2,
                      ),
                      itemBuilder: (context, index) {
                        final anime = filteredAnimeList[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AnimeDetailPage(anime: anime),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.asset(
                                  anime.imageAsset,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  anime.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
