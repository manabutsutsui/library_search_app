import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'seichi_search.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/visited_spots_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SeichiRegistrationPage extends ConsumerStatefulWidget {
  const SeichiRegistrationPage({super.key});

  @override
  ConsumerState<SeichiRegistrationPage> createState() => _SeichiRegistrationPageState();
}

class _SeichiRegistrationPageState extends ConsumerState<SeichiRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _memoController = TextEditingController();
  DateTime _visitDate = DateTime.now();
  DocumentSnapshot? _selectedSpot;
  File? _selectedImage;

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate() && _selectedSpot != null) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        String? imageUrl;
        if (_selectedImage != null) {
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('visited_spots')
              .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
          
          await storageRef.putFile(_selectedImage!);
          imageUrl = await storageRef.getDownloadURL();
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('visited_spots')
            .add({
          'createdAt': FieldValue.serverTimestamp(),
          'visitDate': _visitDate,
          'spotName': _selectedSpot!['name'],
          'spotId': _selectedSpot!.id,
          'memo': _memoController.text,
          'imageUrl': imageUrl,
        });

        if (mounted) {
          final visitedSpotsNotifier = ref.read(visitedSpotsProvider.notifier);
          visitedSpotsNotifier.addVisitedSpot(_selectedSpot!.id, _selectedSpot!['name']);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.saveSuccess)),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.saveError}: $e')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.requiredInput)),
      );
    }
  }

  Future<void> _pickImage() async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.imageSelectionError}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(l10n.seichitouroku,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: l10n.visitDate,
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                readOnly: true,
                controller: TextEditingController(
                  text: '${_visitDate.year}年${_visitDate.month}月${_visitDate.day}日',
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _visitDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    locale: const Locale('ja'),
                  );
                  if (picked != null) {
                    setState(() {
                      _visitDate = picked;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              Text(l10n.selectHolyPlace, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (BuildContext context) => SeichiSearchBottomSheet(
                        onSpotSelected: (spot) {
                          setState(() {
                            _selectedSpot = spot;
                          });
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedSpot != null
                            ? _selectedSpot!['name']
                            : l10n.selectHolyPlace,
                        style: TextStyle(
                          color: _selectedSpot != null ? Colors.black : Colors.grey,
                        ),
                      ),
                      const Icon(Icons.search),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.addPhoto, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_a_photo, size: 64, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text(l10n.tapToAddPhoto,
                                style: const TextStyle(color: Colors.grey)),
                          ],
                        )
                      : Stack(
                          children: [
                            Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Positioned(
                              right: 0,
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedImage = null;
                                  });
                                },
                                child: Container(
                                  color: Colors.black54,
                                  child: const Icon(
                                    Icons.close,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.memo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              TextFormField(
                controller: _memoController,
                decoration: InputDecoration(
                  labelText: l10n.memo,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return l10n.memoInputError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.blue,
                ),
                child: Text(
                  l10n.register,
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
