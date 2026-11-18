import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:oruv/components/home/daily_screen_time_card.dart';
import 'package:oruv/services/screen_time_service.dart';

class InsightsWeeklyChartCard extends StatelessWidget {
  final List<int> weekDayMinutes;
  final int todayIndex;
  final int dailyAvgMinutes;
  final int weekTotalMinutes;

  static const Color _primaryText = Color(0xFF1B1B1D);
  static const Color _mutedText = Color(0xFF6E6A6E);
  static const Color _emeraldGreen = Color(0xFF16654E);

  const InsightsWeeklyChartCard({
    super.key,
    required this.weekDayMinutes,
    required this.todayIndex,
    required this.dailyAvgMinutes,
    required this.weekTotalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final maxDay = weekDayMinutes.fold<int>(0, (a, b) => math.max(a, b));
    final peak = math.max(maxDay, dailyAvgMinutes);
    final rawHours = math.max(2, (peak / 60.0).ceil());
    final ceilingHours = rawHours.isEven ? rawHours : rawHours + 1;
    final chartMaxMinutes = math.max(120, ceilingHours * 60);
    const chartHeight = 132.0;
    const axisWidth = 34.0;
    const cardFill = Color(0xFFFDFBF9);
    const avgLineColor = Color(0xFF22A06B);

    final avgRatio = (dailyAvgMinutes / chartMaxMinutes).clamp(0.0, 1.0);
    final avgY = chartHeight * (1.0 - avgRatio);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: cardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0EAE6), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: chartHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final plotWidth = math.max(1.0, constraints.maxWidth - axisWidth);
                final colWidth = plotWidth / 7.0;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 0,
                      top: 0,
                      width: plotWidth,
                      height: chartHeight,
                      child: CustomPaint(
                        painter: WeeklyChartGridPainter(
                          gridColor: const Color(0xFFECE5E1),
                          avgY: avgY,
                          showAvgLine: dailyAvgMinutes > 0,
                          avgLineColor: avgLineColor,
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 0,
                      width: plotWidth,
                      height: chartHeight,
                      child: Row(
                        children: List.generate(7, (idx) {
                          final isFuture = idx > todayIndex;
                          final mins = weekDayMinutes[idx];
                          final ratio = (mins / chartMaxMinutes).clamp(0.0, 1.0);
                          final barH = (!isFuture && mins > 0)
                              ? math.max(5.0, chartHeight * ratio)
                              : 0.0;

                          return SizedBox(
                            width: colWidth,
                            height: chartHeight,
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: barH > 0
                                  ? Container(
                                      width: math.min(
                                        20.0,
                                        math.max(12.0, colWidth * 0.48),
                                      ),
                                      height: barH,
                                      decoration: const BoxDecoration(
                                        color: _emeraldGreen,
                                        borderRadius: BorderRadius.vertical(
                                          top: Radius.circular(5),
                                        ),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          );
                        }),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      width: axisWidth,
                      height: chartHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: 0,
                            child: Text(
                              '${ceilingHours}h',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _mutedText,
                              ),
                            ),
                          ),
                          Positioned(
                            top: chartHeight * 0.5 - 6,
                            child: Text(
                              '${ceilingHours ~/ 2}h',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _mutedText,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            child: Text(
                              '0',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _mutedText,
                              ),
                            ),
                          ),
                          if (dailyAvgMinutes > 0)
                            Positioned(
                              top: (avgY - 7).clamp(4.0, chartHeight - 16.0),
                              child: Container(
                                color: cardFill,
                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                child: Text(
                                  'avg',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: avgLineColor,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: List.generate(7, (idx) {
                    final isToday = idx == todayIndex;
                    final isFuture = idx > todayIndex;
                    return Expanded(
                      child: Center(
                        child: Text(
                          dayLabels[idx],
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight:
                                isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isToday
                                ? _primaryText
                                : (isFuture
                                      ? _mutedText.withValues(alpha: 0.5)
                                      : _mutedText),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(width: axisWidth),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFEFE8E5), height: 1, thickness: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Screen Time',
                style: GoogleFonts.lora(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: _mutedText,
                ),
              ),
              Text(
                AppScreenTimeItem.formatMinutes(weekTotalMinutes),
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _primaryText,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class WeeklyChartGridPainter extends CustomPainter {
  final Color gridColor;
  final double avgY;
  final bool showAvgLine;
  final Color avgLineColor;

  WeeklyChartGridPainter({
    required this.gridColor,
    required this.avgY,
    required this.showAvgLine,
    required this.avgLineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8;

    for (final factor in [0.0, 0.5, 1.0]) {
      final y = size.height * factor;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final dividerPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.65)
      ..strokeWidth = 0.7;
    final colWidth = size.width / 7.0;
    for (int i = 0; i <= 7; i++) {
      final x = colWidth * i;
      double y = 0;
      while (y < size.height) {
        final endY = math.min(y + 2, size.height);
        canvas.drawLine(Offset(x, y), Offset(x, endY), dividerPaint);
        y += 4;
      }
    }

    if (showAvgLine) {
      final avgPaint = Paint()
        ..color = avgLineColor
        ..strokeWidth = 1.5;
      double x = 0;
      while (x < size.width) {
        final endX = math.min(x + 3, size.width);
        canvas.drawLine(Offset(x, avgY), Offset(endX, avgY), avgPaint);
        x += 6;
      }
    }
  }

  @override
  bool shouldRepaint(covariant WeeklyChartGridPainter oldDelegate) {
    return oldDelegate.avgY != avgY ||
        oldDelegate.showAvgLine != showAvgLine ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.avgLineColor != avgLineColor;
  }
}
