import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '/utils/theme.dart';

/// Month + year only (no day). Returns `MMMM yyyy` (e.g. `March 2024`).
Future<String?> showMonthYearPicker(
  BuildContext context, {
  DateTime? initial,
  DateTime? firstDate,
  DateTime? lastDate,
  String helpText = 'Select month and year',
}) async {
  final now = DateTime.now();
  final first = firstDate ?? DateTime(2000);
  final last = lastDate ?? now;
  var selected = initial ?? DateTime(now.year, now.month);

  if (selected.isBefore(first)) selected = first;
  if (selected.isAfter(last)) selected = last;

  final years = [
    for (var y = last.year; y >= first.year; y--) y,
  ];
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  return showDialog<String>(
    context: context,
    builder: (ctx) {
      var month = selected.month;
      var year = selected.year;
      return StatefulBuilder(
        builder: (ctx, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(helpText),
            content: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: month,
                    decoration: const InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: [
                      for (var i = 1; i <= 12; i++)
                        DropdownMenuItem(value: i, child: Text(months[i - 1])),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => month = v);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<int>(
                    initialValue: year,
                    decoration: const InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: years
                        .map(
                          (y) => DropdownMenuItem(value: y, child: Text('$y')),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => year = v);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryMid,
                  foregroundColor: AppTheme.bgLight,
                ),
                onPressed: () {
                  final picked = DateTime(year, month);
                  if (picked.isBefore(DateTime(first.year, first.month)) ||
                      picked.isAfter(DateTime(last.year, last.month))) {
                    return;
                  }
                  Navigator.pop(
                    ctx,
                    DateFormat('MMMM yyyy').format(picked),
                  );
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    },
  );
}
