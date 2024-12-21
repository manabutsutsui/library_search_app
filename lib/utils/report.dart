import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key});

  @override
  ReportDialogState createState() => ReportDialogState();
}

class ReportDialogState extends State<ReportDialog> {
  late List<String> _reportReasons;
  String? _selectedReason;

  @override
  void initState() {
    super.initState();
    final l10n = AppLocalizations.of(context)!;
    _reportReasons = [
      l10n.inappropriateContent,
      l10n.spamOrAdvertisement,
      l10n.incorrectInformation,
      l10n.other,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.selectReportReason,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          child: Text(l10n.cancel),
          onPressed: () => Navigator.of(context).pop(null),
        ),
        TextButton(
          child: Text(l10n.report),
          onPressed: () {
            Navigator.of(context).pop(_selectedReason);
          },
        ),
      ],
    );
  }
}
