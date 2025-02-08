import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';

class SeichiPhotos extends StatefulWidget {
  final String spotId;

  const SeichiPhotos({super.key, required this.spotId});

  @override
  State<SeichiPhotos> createState() => _SeichiPhotosState();
}

class _SeichiPhotosState extends State<SeichiPhotos> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _takePhoto() async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // Storageにアップロード
        final storageRef = FirebaseStorage.instance.ref().child(
            'spots_images/${widget.spotId}/photos/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(File(photo.path));
        final downloadUrl = await storageRef.getDownloadURL();

        // Firestoreに保存
        await FirebaseFirestore.instance
            .collection('spots')
            .doc(widget.spotId)
            .collection('photos')
            .add({
          'userId': user.uid,
          'imageUrl': downloadUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.imageSelectionError)),
          );
        }
      }
    }
  }

  Future<void> _openGallery() async {
    final l10n = AppLocalizations.of(context)!;
    final XFile? photo = await _picker.pickImage(source: ImageSource.gallery);

    if (photo != null) {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // Storageにアップロード
        final storageRef = FirebaseStorage.instance.ref().child(
            'spots/${widget.spotId}/photos/${DateTime.now().millisecondsSinceEpoch}.jpg');

        await storageRef.putFile(File(photo.path));
        final downloadUrl = await storageRef.getDownloadURL();

        // Firestoreに保存
        await FirebaseFirestore.instance
            .collection('spots')
            .doc(widget.spotId)
            .collection('photos')
            .add({
          'userId': user.uid,
          'imageUrl': downloadUrl,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.imageSelectionError)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;

    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt, color: Colors.white),
              label: Text(l10n.camera,
                  style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              onPressed: _openGallery,
              icon: const Icon(Icons.photo_library, color: Colors.white),
              label: Text(l10n.gallery,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('spots')
              .doc(widget.spotId)
              .collection('photos')
              .where('userId', isEqualTo: user?.uid)
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(l10n.errorOccurred));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final photos = snapshot.data!.docs;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                final data = photo.data() as Map<String, dynamic>;
                final imageUrl = data['imageUrl'] as String;
                return GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => Dialog(
                        backgroundColor: Colors.transparent,
                        insetPadding: EdgeInsets.zero,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // 背景を半透明の黒にする
                            Container(
                              color: Colors.black.withOpacity(0.9),
                            ),
                            // 画像を表示
                            InteractiveViewer(
                              minScale: 0.5,
                              maxScale: 4.0,
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.contain,
                              ),
                            ),
                            // 閉じるボタン
                            Positioned(
                              top: 40,
                              right: 20,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
