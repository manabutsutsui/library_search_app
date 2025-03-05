import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'seichi_spots.dart';

class AnimeSearchBottomSheet extends StatefulWidget {
  final Function(SeichiSpot) onSpotSelected;

  const AnimeSearchBottomSheet({
    super.key,
    required this.onSpotSelected,
  });

  @override
  State<AnimeSearchBottomSheet> createState() => _AnimeSearchBottomSheetState();
}

class _AnimeSearchBottomSheetState extends State<AnimeSearchBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<SeichiSpot> _searchResults = [];
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
      // 聖地名と作品名での検索（部分一致）
      final results = seichiSpots.where((spot) {
        final nameMatch = spot.name.toLowerCase().contains(query.toLowerCase());
        final workMatch =
            spot.workName.toLowerCase().contains(query.toLowerCase());
        return nameMatch || workMatch;
      }).toList();

      setState(() {
        _searchResults = results;
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
                        return ListTile(
                          title: Text(spot.name),
                          subtitle: Text('${l10n.workName}: ${spot.workName}'),
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
