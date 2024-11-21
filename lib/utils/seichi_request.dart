import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SpotRequestDialog extends StatefulWidget {
  const SpotRequestDialog({super.key});

  @override
  SpotRequestDialogState createState() => SpotRequestDialogState();
}

class SpotRequestDialogState extends State<SpotRequestDialog> {
  final TextEditingController _spotNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _workNameController = TextEditingController();
  String _errorMessage = '';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: EdgeInsets.zero,
      child: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        color: Colors.grey[900],
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              title: const Text(
                '聖地をリクエスト',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_location,
                      size: 80,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 16),
                    const Text('あなたが追加したい聖地をリクエストできます。',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _spotNameController,
                      decoration: const InputDecoration(
                        hintText: '聖地名',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: '住所',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _workNameController,
                      decoration: const InputDecoration(
                        hintText: '作品名',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          _errorMessage = '';
                        });
                        if (_spotNameController.text.isNotEmpty &&
                            _addressController.text.isNotEmpty &&
                            _workNameController.text.isNotEmpty) {
                          try {
                            await FirebaseFirestore.instance
                                .collection('spot_requests')
                                .add({
                              'spotName': _spotNameController.text,
                              'address': _addressController.text,
                              'workName': _workNameController.text,
                              'userEmail': FirebaseAuth.instance.currentUser?.email ?? 'unknown',
                              'timestamp': FieldValue.serverTimestamp(),
                            });
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('リクエストが送信されました')),
                            );
                          } catch (e) {
                            setState(() {
                              _errorMessage = 'エラーが発生しました: $e';
                            });
                          }
                        } else {
                          setState(() {
                            _errorMessage = 'すべてのフィールドを入力してください';
                          });
                        }
                      },
                      child: const Text('リクエストを送信'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
