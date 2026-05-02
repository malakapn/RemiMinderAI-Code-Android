import 'package:flutter/material.dart';

/// 12-hour time picker with AM/PM and quick presets (Morning, Noon, Evening, Night).
Future<TimeOfDay?> showTwelveHourTimePickerSheet(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  final h24 = initialTime.hour;
  var isPm = h24 >= 12;
  var hour12 = h24 % 12;
  if (hour12 == 0) hour12 = 12;
  var minute = initialTime.minute.clamp(0, 59);

  TimeOfDay to24({required int h12, required int min, required bool pm}) {
    late final int h24;
    if (pm) {
      h24 = (h12 == 12) ? 12 : h12 + 12;
    } else {
      h24 = (h12 == 12) ? 0 : h12;
    }
    return TimeOfDay(hour: h24, minute: min.clamp(0, 59));
  }

  return showModalBottomSheet<TimeOfDay>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (ctx, setModal) {
          final bottomInset = MediaQuery.paddingOf(ctx).bottom;
          return Container(
            margin: EdgeInsets.only(bottom: bottomInset),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select time',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PresetChip(
                        label: 'Morning (8 AM)',
                        onTap: () => setModal(() {
                          hour12 = 8;
                          minute = 0;
                          isPm = false;
                        }),
                      ),
                      _PresetChip(
                        label: 'Noon (12 PM)',
                        onTap: () => setModal(() {
                          hour12 = 12;
                          minute = 0;
                          isPm = true;
                        }),
                      ),
                      _PresetChip(
                        label: 'Evening (6 PM)',
                        onTap: () => setModal(() {
                          hour12 = 6;
                          minute = 0;
                          isPm = true;
                        }),
                      ),
                      _PresetChip(
                        label: 'Night (8 PM)',
                        onTap: () => setModal(() {
                          hour12 = 8;
                          minute = 0;
                          isPm = true;
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: hour12,
                          decoration: const InputDecoration(
                            labelText: 'Hour',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (var h = 1; h <= 12; h++)
                              DropdownMenuItem(value: h, child: Text('$h')),
                          ],
                          onChanged: (v) {
                            if (v != null) setModal(() => hour12 = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: minute,
                          decoration: const InputDecoration(
                            labelText: 'Minute',
                            border: OutlineInputBorder(),
                          ),
                          items: [
                            for (var m = 0; m < 60; m++)
                              DropdownMenuItem(
                                value: m,
                                child: Text(m.toString().padLeft(2, '0')),
                              ),
                          ],
                          onChanged: (v) {
                            if (v != null) setModal(() => minute = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: isPm ? 'PM' : 'AM',
                          decoration: const InputDecoration(
                            labelText: '',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'AM', child: Text('AM')),
                            DropdownMenuItem(value: 'PM', child: Text('PM')),
                          ],
                          onChanged: (v) {
                            if (v != null)
                              setModal(() => isPm = v == 'PM');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(
                            ctx,
                            to24(h12: hour12, min: minute, pm: isPm),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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
