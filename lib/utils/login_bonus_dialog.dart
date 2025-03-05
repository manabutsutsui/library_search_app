import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_bonus_provider.dart';
import '../providers/subscription_state.dart';
import 'dart:math' as math;

class LoginBonusDialog extends ConsumerStatefulWidget {
  const LoginBonusDialog({super.key});

  @override
  ConsumerState<LoginBonusDialog> createState() => _LoginBonusDialogState();
}

class _LoginBonusDialogState extends ConsumerState<LoginBonusDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _showStamp = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // アニメーションを少し遅延させて開始
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showStamp = true;
        });
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loginBonus = ref.watch(loginBonusProvider);
    final isPremium = ref.watch(subscriptionProvider).value ?? false;

    // ログイン履歴を日付のみに変換（年月日）
    final loginDates = loginBonus.loginHistory
        .map((date) => DateTime(date.year, date.month, date.day))
        .toList();

    // 連続ログイン日数に応じたボーナス報酬を決定
    String rewardText;

    if (loginBonus.consecutiveDays % 7 == 0) {
      // 7日ごとの特別ボーナス
      rewardText =
          isPremium ? l10n.loginBonusSpecialPremium : l10n.loginBonusSpecial;
    } else {
      // 通常のボーナス
      rewardText =
          isPremium ? l10n.loginBonusDailyPremium : l10n.loginBonusDaily;
    }

    // 今月のカレンダーを生成
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    // 月の最初の日の曜日（0 = 日曜日）
    final firstWeekday = firstDayOfMonth.weekday % 7;

    // 前月の日を埋める
    final daysInCalendar = <Widget>[];
    for (int i = 0; i < firstWeekday; i++) {
      daysInCalendar.add(
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 32,
            height: 32,
          ),
        ),
      );
    }

    // 今月の日を追加
    for (int i = 1; i <= lastDayOfMonth.day; i++) {
      final date = DateTime(now.year, now.month, i);
      final isToday = date.day == now.day &&
          date.month == now.month &&
          date.year == now.year;

      // その日にログインしたかどうかを確認
      final hasLoggedInOnThisDay = loginDates.any((loginDate) =>
          loginDate.day == date.day &&
          loginDate.month == date.month &&
          loginDate.year == date.year);

      daysInCalendar.add(
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isToday ? Colors.blue.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Text(
                    '$i',
                    style: TextStyle(
                      color: isToday ? Colors.blue : Colors.black87,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              // ログイン済みの日付またはアプリを開いた今日の日付にのみスタンプ表示
              if (hasLoggedInOnThisDay)
                Positioned.fill(
                  child: isToday && _showStamp
                      ? AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _rotationAnimation.value,
                              child: Transform.scale(
                                scale: _scaleAnimation.value,
                                child: child,
                              ),
                            );
                          },
                          child: const _StampMark(color: Colors.redAccent),
                        )
                      : const _StampMark(color: Colors.red),
                ),
            ],
          ),
        ),
      );
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Text(
              l10n.loginBonusTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Icon(Icons.card_giftcard, size: 60, color: Colors.blue),
            const SizedBox(height: 12),
            Text(
              '${now.year}年${now.month}月',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Text('日', style: TextStyle(color: Colors.red)),
                Text('月'),
                Text('火'),
                Text('水'),
                Text('木'),
                Text('金'),
                Text('土', style: TextStyle(color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 4),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: daysInCalendar,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.consecutiveLoginDays(loginBonus.consecutiveDays),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              rewardText,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref
                      .read(loginBonusProvider.notifier)
                      .claimLoginBonus(isPremium);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.pointsAdded),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(l10n.claim),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StampMark extends StatelessWidget {
  final Color color;

  const _StampMark({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: StampPainter(color: color),
      size: const Size(36, 36),
    );
  }
}

class StampPainter extends CustomPainter {
  final Color color;

  StampPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // 円形の枠
    canvas.drawCircle(center, radius * 0.8, paint);

    // 「出」の字を描く
    paint.style = PaintingStyle.fill;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '出',
        style: TextStyle(
          color: color.withOpacity(0.7),
          fontSize: radius * 1.2,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(StampPainter oldDelegate) => color != oldDelegate.color;
}
