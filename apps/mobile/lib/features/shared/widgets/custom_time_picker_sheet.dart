import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';

class CustomTimePickerSheet {
  static Future<TimeOfDay?> show(
    BuildContext context, {
    required TimeOfDay initialTime,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    final presets = <String, TimeOfDay>{
      l10n.presetMorning: const TimeOfDay(hour: 8, minute: 0),
      l10n.presetNoon: const TimeOfDay(hour: 12, minute: 0),
      l10n.presetEvening: const TimeOfDay(hour: 18, minute: 0),
      l10n.presetNight: const TimeOfDay(hour: 20, minute: 0),
    };

    int hour12 = initialTime.hourOfPeriod == 0 ? 12 : initialTime.hourOfPeriod;
    int minute = initialTime.minute;
    bool isPm = initialTime.period == DayPeriod.pm;
    final hourCtrl = FixedExtentScrollController(initialItem: hour12 - 1);
    final minuteCtrl = FixedExtentScrollController(initialItem: minute);

    String formatPickedTime(int hour24, int min) {
      final dt = DateTime(2000, 1, 1, hour24, min);
      return DateFormat.jm(locale).format(dt);
    }

    final selected = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPicker) {
          Future<void> applyPreset(TimeOfDay t) async {
            final pHour12 = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
            setPicker(() {
              hour12 = pHour12;
              minute = t.minute;
              isPm = t.period == DayPeriod.pm;
            });
            hourCtrl.jumpToItem(pHour12 - 1);
            minuteCtrl.jumpToItem(t.minute);
          }

          final picked24 = (hour12 % 12) + (isPm ? 12 : 0);
          final picked = TimeOfDay(hour: picked24, minute: minute);
          final pickedTimeLabel = formatPickedTime(picked24, minute);
          final numberFormat = NumberFormat.decimalPattern(locale);
          final twoDigitFormat = NumberFormat('00', locale);

          return SafeArea(
            top: false,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F5F6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectTime,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A3A5C),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final buttonWidth = (constraints.maxWidth - 12) / 2;
                      return Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        children: presets.entries.map((entry) {
                          final eHour12 = entry.value.hourOfPeriod == 0
                              ? 12
                              : entry.value.hourOfPeriod;
                          final selectedPreset = hour12 == eHour12 &&
                              minute == entry.value.minute &&
                              isPm == (entry.value.period == DayPeriod.pm);
                          return SizedBox(
                            width: buttonWidth,
                            child: _presetTimeButton(
                              label: entry.key,
                              selected: selectedPreset,
                              onTap: () => applyPreset(entry.value),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.hourLabel,
                            style: const TextStyle(
                              color: Color(0xFF1A3A5C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.minuteLabel,
                            style: const TextStyle(
                              color: Color(0xFF1A3A5C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            l10n.amPmLabel,
                            style: const TextStyle(
                              color: Color(0xFF1A3A5C),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  SizedBox(
                    height: 184,
                    child: Row(
                      children: [
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: hourCtrl,
                            itemExtent: 42,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) =>
                                setPicker(() => hour12 = index + 1),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 12,
                              builder: (_, index) => Center(
                                child: Text(
                                  numberFormat.format(index + 1),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A3A5C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: ListWheelScrollView.useDelegate(
                            controller: minuteCtrl,
                            itemExtent: 42,
                            physics: const FixedExtentScrollPhysics(),
                            onSelectedItemChanged: (index) =>
                                setPicker(() => minute = index),
                            childDelegate: ListWheelChildBuilderDelegate(
                              childCount: 60,
                              builder: (_, index) => Center(
                                child: Text(
                                  twoDigitFormat.format(index),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1A3A5C),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: LayoutBuilder(
                              builder: (context, c) {
                                final maxW = c.maxWidth.clamp(100.0, 148.0);
                                return SizedBox(
                                  width: maxW,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDDE5EA),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        Expanded(
                                          child: _ampmToggleButton(
                                            label: l10n.amLabel,
                                            selected: !isPm,
                                            onTap: () =>
                                                setPicker(() => isPm = false),
                                          ),
                                        ),
                                        Expanded(
                                          child: _ampmToggleButton(
                                            label: l10n.pmLabel,
                                            selected: isPm,
                                            onTap: () =>
                                                setPicker(() => isPm = true),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      l10n.selectedTimeLabel(pickedTimeLabel),
                      style: const TextStyle(
                        color: Color(0xFF1A3A5C),
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF1A3A5C),
                            side: const BorderSide(
                              color: Color(0xFF222222),
                              width: 1.2,
                            ),
                            backgroundColor: const Color(0xFFF7F7F5),
                            minimumSize: const Size.fromHeight(56),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            l10n.cancel,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(picked),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A3A5C),
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Text(
                            l10n.setForTime(pickedTimeLabel),
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    hourCtrl.dispose();
    minuteCtrl.dispose();
    return selected;
  }
}

class _AmPmToggleButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AmPmToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFC8D3DA) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 18,
            color: const Color(0xFF1A3A5C),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

Widget _ampmToggleButton({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return _AmPmToggleButton(label: label, selected: selected, onTap: onTap);
}

Widget _presetTimeButton({
  required String label,
  required bool selected,
  required VoidCallback onTap,
}) {
  return OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: const BorderSide(color: Color(0xFF222222), width: 1.3),
      foregroundColor: const Color(0xFF1A3A5C),
      backgroundColor:
          selected ? const Color(0xFFE6F0FA) : const Color(0xFFF8F7ED),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
    ),
    onPressed: onTap,
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
    ),
  );
}
