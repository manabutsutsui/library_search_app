import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io' show Platform;
import 'package:in_app_review/in_app_review.dart';

class ReviewRequestManager {
  static const String _keyFirstLaunchDate = 'first_launch_date';
  static const String _keyHasShownReviewDialog = 'has_shown_review_dialog';
  static final InAppReview _inAppReview = InAppReview.instance;

  static Future<void> checkAndShowReviewDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    // 初回起動日時を取得または保存
    final firstLaunchDate = prefs.getInt(_keyFirstLaunchDate) ??
        DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_keyFirstLaunchDate, firstLaunchDate);

    // レビューダイアログが既に表示されているか確認
    final hasShownReviewDialog =
        prefs.getBool(_keyHasShownReviewDialog) ?? false;
    if (hasShownReviewDialog) return;

    // 初回起動から24時間経過しているか確認
    final now = DateTime.now().millisecondsSinceEpoch;
    final daysSinceFirstLaunch =
        (now - firstLaunchDate) / (1000 * 60 * 60 * 24);

    if (daysSinceFirstLaunch >= 1) {
      // ダイアログを表示済みとしてマーク
      await prefs.setBool(_keyHasShownReviewDialog, true);

      if (context.mounted) {
        _showReviewDialog(context);
      }
    }
  }

  static void _showReviewDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.reviewRequestTitle,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Text(l10n.reviewRequestMessage,
            style: const TextStyle(fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.later),
          ),
          TextButton(
            onPressed: () async {
              if (Platform.isAndroid) {
                final url =
                    'market://details?id=com.your.package.name'; // あなたのアプリのPackage名に置き換えてください
                if (await canLaunch(url)) {
                  await launch(url);
                }
              } else if (Platform.isIOS) {
                if (await _inAppReview.isAvailable()) {
                  await _inAppReview.openStoreListing(
                    appStoreId: '6723886292',
                  );
                }
              }
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(l10n.review),
          ),
        ],
      ),
    );
  }
}
