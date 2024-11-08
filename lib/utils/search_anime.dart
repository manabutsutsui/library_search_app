import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnimeSearchDelegate extends SearchDelegate<String> {
  final Function(String) onAnimeSelected;

  AnimeSearchDelegate({required this.onAnimeSelected});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildAnimeList();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'アニメ作品名を入力してください',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
        if (query.isNotEmpty)
          Expanded(
            child: _buildAnimeList(),
          ),
      ],
    );
  }

  Widget _buildAnimeList() {
    if (query.isEmpty) {
      return const SizedBox.shrink();
    }

    final String searchQuery = query.toLowerCase();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('spots')
          .orderBy('work')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('エラーが発生しました'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        Set<String> uniqueAnimes = snapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['work'] as String)
            .where((work) => work.toLowerCase().contains(searchQuery))
            .toSet();

        final sortedAnimes = uniqueAnimes.toList()..sort();

        if (sortedAnimes.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('該当する作品が見つかりませんでした'),
            ),
          );
        }

        return ListView.builder(
          itemCount: sortedAnimes.length,
          itemBuilder: (context, index) {
            final animeName = sortedAnimes[index];
            return ListTile(
              title: Text(
                animeName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.movie_outlined),
              onTap: () {
                onAnimeSelected(animeName);
                close(context, animeName);
              },
            );
          },
        );
      },
    );
  }
}