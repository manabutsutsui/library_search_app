import 'package:flutter/material.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  ReportDialogState createState() => ReportDialogState();
}

class ReportDialogState extends State<ReportDialog> {
  final List<String> _reportReasons = [
    '不適なコンテンツ',
    'スパムまたは広告',
    '誤った情報',
    'その他',
  ];
  String? _selectedReason;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('報告理由を選択してください',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_reportReasons.length, (index) {
          return RadioListTile<String>(
            title: Text(_reportReasons[index]),
            value: _reportReasons[index],
            groupValue: _selectedReason,
            onChanged: (String? value) {
              setState(() {
                _selectedReason = value;
              });
            },
          );
        }),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          child: const Text('報告する'),
          onPressed: () {
            Navigator.of(context).pop(_selectedReason);
          },
        ),
      ],
    );
  }
}
