import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/login_bonus_provider.dart';
import 'dart:math' as math;

final calendarMonthProvider = StateProvider<DateTime>((ref) {
  return DateTime(DateTime.now().year, DateTime.now().month, 1);
});

class LoginCalendar extends ConsumerWidget {
  const LoginCalendar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loginBonusState = ref.watch(loginBonusProvider);
    final loginHistory = loginBonusState.loginHistory;
    final currentMonth = ref.watch(calendarMonthProvider);

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.blue, size: 32),
                  onPressed: () {
                    // 前月に移動
                    final previousMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month - 1,
                      1,
                    );
                    ref.read(calendarMonthProvider.notifier).state =
                        previousMonth;
                  },
                ),
                Text(
                  '${_getMonthName(context, currentMonth.month)} ${currentMonth.year}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right,
                      color: Colors.blue, size: 32),
                  onPressed: () {
                    // 翌月に移動
                    final nextMonth = DateTime(
                      currentMonth.year,
                      currentMonth.month + 1,
                      1,
                    );
                    ref.read(calendarMonthProvider.notifier).state = nextMonth;
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildCalendarHeader(context),
            const SizedBox(height: 8),
            _buildCalendarGrid(context, currentMonth, loginHistory),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dayNames = [
      l10n.sun,
      l10n.mon,
      l10n.tue,
      l10n.wed,
      l10n.thu,
      l10n.fri,
      l10n.sat,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: dayNames.map((day) {
        final isWeekend = day == l10n.sun || day == l10n.sat;
        return Expanded(
          child: Text(
            day,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWeekend
                  ? (day == l10n.sun ? Colors.red : Colors.blue)
                  : Colors.grey,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(
      BuildContext context, DateTime month, List<DateTime> loginHistory) {
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 0が日曜日になるように調整

    final daysInCalendar = <Widget>[];

    // 前月の日を追加
    for (int i = 0; i < firstWeekday; i++) {
      daysInCalendar.add(
        const Padding(
          padding: EdgeInsets.all(4.0),
          child: SizedBox(
            height: 40,
            width: 40,
            child: Center(
              child: Text(
                '',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
        ),
      );
    }

    // 当月の日を追加
    for (int i = 1; i <= daysInMonth; i++) {
      final date = DateTime(month.year, month.month, i);
      final isToday = _isSameDay(date, DateTime.now());
      final hasLoginOnThisDay =
          loginHistory.any((loginDate) => _isSameDay(loginDate, date));

      final dayColor = date.weekday == 7
          ? Colors.red
          : (date.weekday == 6 ? Colors.blue : Colors.black);

      daysInCalendar.add(
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 40,
                width: 40,
                decoration: isToday
                    ? BoxDecoration(
                        color: Colors.blue.withOpacity(0.3),
                        shape: BoxShape.circle,
                      )
                    : null,
                child: Center(
                  child: Text(
                    '$i',
                    style: TextStyle(
                      color: dayColor,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ),
              if (hasLoginOnThisDay) const StampMark(color: Colors.red),
            ],
          ),
        ),
      );
    }

    // 翌月の日を追加（7の倍数になるまで）
    final remainingDays = 7 - (daysInCalendar.length % 7);
    if (remainingDays < 7) {
      for (int i = 0; i < remainingDays; i++) {
        daysInCalendar.add(
          const Padding(
            padding: EdgeInsets.all(4.0),
            child: SizedBox(
              height: 40,
              width: 40,
              child: Center(
                child: Text(
                  '',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ),
        );
      }
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: daysInCalendar,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.day == b.day && a.month == b.month && a.year == b.year;
  }

  String _getMonthName(BuildContext context, int month) {
    final l10n = AppLocalizations.of(context)!;
    final monthNames = [
      l10n.january,
      l10n.february,
      l10n.march,
      l10n.april,
      l10n.may,
      l10n.june,
      l10n.july,
      l10n.august,
      l10n.september,
      l10n.october,
      l10n.november,
      l10n.december
    ];
    return monthNames[month - 1];
  }
}

class StampMark extends StatelessWidget {
  final Color color;

  const StampMark({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(30, 30),
      painter: StampPainter(color: color),
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
          fontSize: radius * 1.0,
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
