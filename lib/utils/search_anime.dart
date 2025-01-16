import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnimeSearchBottomSheet extends StatefulWidget {
  final Function(DocumentSnapshot) onSpotSelected;

  const AnimeSearchBottomSheet({
    Key? key,
    required this.onSpotSelected,
  }) : super(key: key);

  @override
  State<AnimeSearchBottomSheet> createState() => _AnimeSearchBottomSheetState();
}

class _AnimeSearchBottomSheetState extends State<AnimeSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<DocumentSnapshot> _searchResults = [];
  bool _isLoading = false;

  Future<void> _searchSpots(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final spotsRef = FirebaseFirestore.instance.collection('spots');
      
      // 聖地名での検索（部分一致）
      final nameQuerySnapshot = await spotsRef
          .orderBy('name')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      // 作品名での検索（部分一致）
      final workQuerySnapshot = await spotsRef
          .orderBy('work')
          .startAt([query])
          .endAt([query + '\uf8ff'])
          .get();

      // 結果をマージして重複を除去
      final Set<String> uniqueIds = {};
      final List<DocumentSnapshot> mergedResults = [];

      for (var doc in nameQuerySnapshot.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          mergedResults.add(doc);
        }
      }

      for (var doc in workQuerySnapshot.docs) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          mergedResults.add(doc);
        }
      }

      setState(() {
        _searchResults = mergedResults;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(l10n.selectHolyPlace,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: l10n.searchHolyPlace,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              onChanged: (value) {
                _searchSpots(value);
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final spot = _searchResults[index];
                        final data = spot.data() as Map<String, dynamic>;
                        
                        return ListTile(
                          title: Text(data['name'] ?? ''),
                          subtitle: Text('${l10n.workName}: ${data['work'] ?? ''}'),
                          onTap: () {
                            widget.onSpotSelected(spot);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}