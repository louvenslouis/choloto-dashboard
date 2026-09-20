import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A calendar with weekdays on the vertical axis and weeks horizontally.
class MonthlyBingoHeatmap extends StatelessWidget {
  const MonthlyBingoHeatmap({
    super.key,
    required this.asOf,
    required this.dailyCounts,
  });

  final DateTime asOf;
  final List<double> dailyCounts;

  static const _colors = [
    Color(0xFF303941),
    Color(0xFF194F35),
    Color(0xFF267D4B),
    Color(0xFF37A862),
    Color(0xFF4AC77D),
  ];
  static const _axisStyle = TextStyle(
    color: Color(0xFF98A4AE),
    fontSize: 9,
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(asOf.year, asOf.month);
    final days = DateTime(asOf.year, asOf.month + 1, 0).day;
    final offset = firstDay.weekday - 1;
    final weeks = ((offset + days) / 7).ceil();
    final maximum = dailyCounts.fold<double>(1, math.max);

    return LayoutBuilder(builder: (context, constraints) {
      const gap = 3.0;
      const axisWidth = 27.0;
      final cell = math.min(
        14.0,
        (constraints.maxWidth - axisWidth - (weeks - 1) * gap) / weeks,
      );
      final step = cell + gap;

      return Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: axisWidth + weeks * step - gap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const SizedBox(width: axisWidth),
                for (var week = 0; week < weeks; week++)
                  SizedBox(
                    width: week == weeks - 1 ? cell : step,
                    child: Text(
                      '${math.max(1, week * 7 - offset + 1)}',
                      style: _axisStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
              ]),
              const SizedBox(height: 5),
              for (var weekday = 0; weekday < 7; weekday++)
                Padding(
                  padding: EdgeInsets.only(bottom: weekday == 6 ? 0 : gap),
                  child: Row(children: [
                    SizedBox(
                      width: axisWidth,
                      height: cell,
                      child: Text(
                        const ['Lun', '', 'Mer', '', 'Ven', '', 'Dim'][weekday],
                        style: _axisStyle,
                      ),
                    ),
                    for (var week = 0; week < weeks; week++)
                      Padding(
                        padding:
                            EdgeInsets.only(right: week == weeks - 1 ? 0 : gap),
                        child: _dayCell(
                          week * 7 + weekday - offset + 1,
                          days,
                          cell,
                          maximum,
                        ),
                      ),
                  ]),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('0', style: _axisStyle),
                  const SizedBox(width: 5),
                  for (final color in _colors)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 3),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Text('${maximum.toInt()}', style: _axisStyle),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _dayCell(int day, int days, double size, double maximum) {
    if (day < 1 || day > days) return SizedBox.square(dimension: size);
    final future = day > asOf.day;
    final count = day <= dailyCounts.length ? dailyCounts[day - 1].toInt() : 0;
    final level = count == 0 ? 0 : (count / maximum * 4).ceil().clamp(1, 4);
    final label = '${day.toString().padLeft(2, '0')}/'
        '${asOf.month.toString().padLeft(2, '0')}/${asOf.year} : '
        '${future ? 'à venir' : '$count Bingo validé${count == 1 ? '' : 's'}'}';

    return Tooltip(
      message: label,
      child: Semantics(
        label: label,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color:
                future ? _colors.first.withValues(alpha: .25) : _colors[level],
            borderRadius: BorderRadius.circular(2.5),
            border: Border.all(
              color: day == asOf.day
                  ? const Color(0xFFB8E9CB)
                  : const Color(0xFF697780)
                      .withValues(alpha: future ? .12 : .2),
              width: .7,
            ),
          ),
        ),
      ),
    );
  }
}
