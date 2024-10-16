import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class SeichiRegistrationEditPage extends StatefulWidget {
  final Map<String, dynamic> visitedSpotData;

  const SeichiRegistrationEditPage({Key? key, required this.visitedSpotData}) : super(key: key);

  @override
  _SeichiRegistrationEditPageState createState() => _SeichiRegistrationEditPageState();
}

class _SeichiRegistrationEditPageState extends State<SeichiRegistrationEditPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _memoController = TextEditingController();
  DateTime? _selectedDate;
  List<String> _existingImageUrls = [];
  List<File> _newImages = [];
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _memoController.text = widget.visitedSpotData['memo'] ?? '';
    _selectedDate = widget.visitedSpotData['visitedDate'] != null
        ? (widget.visitedSpotData['visitedDate'] as Timestamp).toDate()
        : null;
    _existingImageUrls = List<String>.from(widget.visitedSpotData['imageUrls'] ?? []);
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final List<XFile>? images = await picker.pickMultiImage();
      if (images != null && images.isNotEmpty) {
        setState(() {
          _newImages.addAll(images.map((xfile) => File(xfile.path)));
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '画像の選択中にエラーが発生しました: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<List<String>> _uploadNewImages(List<File> images) async {
    List<String> downloadUrls = [];
    try {
      for (File image in images) {
        final firebaseStorageRef = FirebaseStorage.instance
            .ref()
            .child('visited_spots')
            .child('${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}');
        UploadTask uploadTask = firebaseStorageRef.putFile(image);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() {});
        String downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
      return downloadUrls;
    } catch (e) {
      print('画像のアップロード中にエラーが発生しました: $e');
      throw e;
    }
  }

  Future<void> _submitEdit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null) {
      setState(() {
        _errorMessage = '訪れた日付を選択してください。';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'ログインが必要です。';
          _isSubmitting = false;
        });
        return;
      }

      print('Uploading new images...'); // デバッグログ
      List<String> newImageUrls = await _uploadNewImages(_newImages);
      List<String> allImageUrls = [..._existingImageUrls, ...newImageUrls];

      print('Preparing to update Firestore...'); // デバッグログ
      print('Document ID: ${widget.visitedSpotData['id']}'); // デバッグログ

      final visitedSpotRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('visited_spots')
          .doc(widget.visitedSpotData['id']);

      print('Updating Firestore...'); // デバッグログ
      await visitedSpotRef.update({
        'visitedDate': _selectedDate,
        'memo': _memoController.text,
        'imageUrls': allImageUrls,
      });

      print('Update successful'); // デバッグログ

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('編集が完了しました')),
      );

      Navigator.pop(context);
      Navigator.pop(context);
    } catch (e) {
      print('Error during update: $e'); // デバッグログ
      setState(() {
        _errorMessage = '編集中にエラーが発生しました: $e';
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('聖地記録の編集',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: _existingImageUrls.isEmpty && _newImages.isEmpty
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_a_photo,
                                      size: 64, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('タップして写真を追加',
                                      style: TextStyle(color: Colors.grey)),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.all(8.0),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 4,
                                      mainAxisSpacing: 4,
                                    ),
                                itemCount: _existingImageUrls.length + _newImages.length,
                                itemBuilder: (context, index) {
                                  if (index < _existingImageUrls.length) {
                                    return Stack(
                                      children: [
                                        Image.network(
                                          _existingImageUrls[index],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                        Positioned(
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _existingImageUrls.removeAt(index);
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
                                    );
                                  } else {
                                    final newIndex = index - _existingImageUrls.length;
                                    return Stack(
                                      children: [
                                        Image.file(
                                          _newImages[newIndex],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                        Positioned(
                                          right: 0,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _newImages.removeAt(newIndex);
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
                                    );
                                  }
                                },
                              ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => _selectDate(context),
                            icon: const Icon(Icons.calendar_today),
                            label: Text(_selectedDate == null
                                ? '訪れた日付を選択'
                                : '選択済み: ${DateFormat('yyyy/MM/dd').format(_selectedDate!)}'),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _memoController,
                            decoration: const InputDecoration(
                              labelText: 'メモ',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 5,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'メモを入力してください';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (_errorMessage != null)
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          Center(
                            child: ElevatedButton(
                              onPressed: _submitEdit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              child: const Text('更新',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
