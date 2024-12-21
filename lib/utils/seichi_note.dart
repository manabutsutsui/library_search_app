import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SeichiNote extends StatefulWidget {
  final String spotId;

  const SeichiNote({super.key, required this.spotId});

  @override
  State<SeichiNote> createState() => _SeichiNoteState();
}

class _SeichiNoteState extends State<SeichiNote> {
  final TextEditingController _noteController = TextEditingController();
  List<String> _imageUrls = [];
  bool _isLoading = true;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      final noteDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('seichi_notes')
          .doc(widget.spotId)
          .get();

      if (noteDoc.exists) {
        setState(() {
          _noteController.text = noteDoc.data()?['note'] ?? '';
          _imageUrls = List<String>.from(noteDoc.data()?['images'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error loading note: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveNote() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('seichi_notes')
          .doc(widget.spotId)
          .set({
        'note': _noteController.text,
        'images': _imageUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveSuccess)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveError)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addImage() async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();

    if (images.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) return;

      for (final image in images) {
        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = FirebaseStorage.instance
            .ref()
            .child('seichi_notes')
            .child(userId)
            .child(widget.spotId)
            .child(fileName);

        await ref.putFile(File(image.path));
        final String downloadUrl = await ref.getDownloadURL();

        setState(() {
          _imageUrls.add(downloadUrl);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveError)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeImage(int index) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final String imageUrl = _imageUrls[index];
      // Delete from Storage
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();

      setState(() {
        _imageUrls.removeAt(index);
      });

      await _saveNote();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.saveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.note,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: l10n.noteDescription,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return l10n.noteInputError;
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.photo,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _addImage,
                  icon: const Icon(Icons.add_photo_alternate),
                  label: Text(l10n.addPhoto),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_imageUrls.isNotEmpty)
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _imageUrls.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _imageUrls[index],
                          fit: BoxFit.contain,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: IconButton(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    ListTile(
                                      leading: const Icon(Icons.delete, color: Colors.red),
                                      title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                      onTap: () async {
                                        final bool? confirmDelete = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(l10n.confirm),
                                              content: Text(l10n.deleteConfirmation, style: const TextStyle(fontSize: 12)),
                                              actions: <Widget>[
                                                TextButton(
                                                  child: Text(l10n.cancel),
                                                  onPressed: () => Navigator.of(context).pop(false),
                                                ),
                                                TextButton(
                                                  child: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                                                  onPressed: () => Navigator.of(context).pop(true),
                                                ),
                                              ],
                                            );
                                          },
                                        );

                                        if (confirmDelete == true) {
                                          await _removeImage(index);
                                          Navigator.of(context).pop();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(l10n.deleteSuccess)),
                                          );
                                        } else {
                                          Navigator.of(context).pop();
                                        }
                                      },
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.cancel),
                                      title: Text(l10n.cancel),
                                      onTap: () {
                                        Navigator.pop(context);
                                      },
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveNote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.saveNote,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
