import 'package:flutter/material.dart';

/// Opens a modal with scroll wheels for 12-hour time, AM/PM control, presets,
/// and a confirm label showing the chosen time (e.g. Set for 8:00 AM ✓).
Future<TimeOfDay?> showTwelveHourTimePickerSheet(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _TwelveHourPickerBody(initialTime: initialTime);
    },
  );
}

class _TwelveHourPickerBody extends StatefulWidget {
  const _TwelveHourPickerBody({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_TwelveHourPickerBody> createState() => _TwelveHourPickerBodyState();
}

class _TwelveHourPickerBodyState extends State<_TwelveHourPickerBody> {
  late int _hour12;
  late int _minute;
  late bool _isPm;
  late FixedExtentScrollController _hourCtr;
  late FixedExtentScrollController _minuteCtr;

  @override
  void initState() {
    super.initState();
    final h24 = widget.initialTime.hour;
    _isPm = h24 >= 12;
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    _hour12 = h12;
    _minute = widget.initialTime.minute.clamp(0, 59);
    _hourCtr = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteCtr = FixedExtentScrollController(initialItem: _minute);
  }

  @override
  void dispose() {
    _hourCtr.dispose();
    _minuteCtr.dispose();
    super.dispose();
  }

  TimeOfDay _to24({required int h12, required int min, required bool pm}) {
    late final int h24;
    if (pm) {
      h24 = (h12 == 12) ? 12 : h12 + 12;
    } else {
      h24 = (h12 == 12) ? 0 : h12;
    }
    return TimeOfDay(hour: h24, minute: min.clamp(0, 59));
  }

  static String format12(int h12, int min, bool pm) {
    final mm = min.toString().padLeft(2, '0');
    return '$h12:$mm ${pm ? 'PM' : 'AM'}';
  }

  void _applyPreset({required int hour, required int minute, required bool pm}) {
    setState(() {
      _hour12 = hour;
      _minute = minute;
      _isPm = pm;
      _hourCtr.jumpToItem(hour - 1);
      _minuteCtr.jumpToItem(minute);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final confirmLabel = 'Set for ${format12(_hour12, _minute, _isPm)} ✓';

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PresetChip(
                  label: 'Morning (8:00 AM)',
                  onTap: () => _applyPreset(hour: 8, minute: 0, pm: false),
                ),
                _PresetChip(
                  label: 'Noon (12:00 PM)',
                  onTap: () => _applyPreset(hour: 12, minute: 0, pm: true),
                ),
                _PresetChip(
                  label: 'Evening (6:00 PM)',
                  onTap: () => _applyPreset(hour: 6, minute: 0, pm: true),
                ),
                _PresetChip(
                  label: 'Night (8:00 PM)',
                  onTap: () => _applyPreset(hour: 8, minute: 0, pm: true),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 2,
                    child: _ScrollWheel(
                      controller: _hourCtr,
                      itemCount: 12,
                      itemBuilder: (i) => '${i + 1}',
                      onSelected: (i) =>
                          setState(() => _hour12 = i + 1),
                      label: 'Hour',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _ScrollWheel(
                      controller: _minuteCtr,
                      itemCount: 60,
                      itemBuilder: (i) =>
                          i.toString().padLeft(2, '0'),
                      onSelected: (i) =>
                          setState(() => _minute = i),
                      label: 'Min',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'AM / PM',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ToggleButtons(
                          isSelected: [_isPm == false, _isPm == true],
                          borderRadius:
                              BorderRadius.circular(12),
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 44,
                          ),
                          onPressed: (index) {
                            setState(() => _isPm = index == 1);
                          },
                          children: const [
                            Text('AM', style: TextStyle(fontWeight: FontWeight.w600)),
                            Text('PM', style: TextStyle(fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selected time: ${format12(_hour12, _minute, _isPm)}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                        context,
                        _to24(
                          h12: _hour12,
                          min: _minute,
                          pm: _isPm,
                        ),
                      );
                    },
                    child: Text(confirmLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollWheel extends StatelessWidget {
  const _ScrollWheel({
    required this.controller,
    required this.itemCount,
    required this.itemBuilder,
    required this.onSelected,
    required this.label,
  });

  final FixedExtentScrollController controller;
  final int itemCount;
  final String Function(int index) itemBuilder;
  final ValueChanged<int> onSelected;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: ListWheelScrollView.useDelegate(
            controller: controller,
            itemExtent: 40,
            perspective: .005,
            diameterRatio: 1.4,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: onSelected,
            childDelegate: ListWheelChildBuilderDelegate(
              childCount: itemCount,
              builder: (context, index) => Center(
                child: Text(
                  itemBuilder(index),
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
