import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../care_team/data/services/care_team_api_service.dart';

/// Upcoming = local calendar today and future (hides past days).
enum _TimelineScope { upcoming, all }

/// Caregiver schedule: calendar + list of reminders and appointments (roster-scoped API).
class CaregiverReminderTimelineScreen extends StatefulWidget {
  /// When set (e.g. from `/caregiver/reminders-timeline?patientId=`), starts filtered to that patient.
  final String? initialPatientId;
  final String? initialReminderType;

  const CaregiverReminderTimelineScreen({
    super.key,
    this.initialPatientId,
    this.initialReminderType,
  });

  @override
  State<CaregiverReminderTimelineScreen> createState() =>
      _CaregiverReminderTimelineScreenState();
}

class _CaregiverReminderTimelineScreenState
    extends State<CaregiverReminderTimelineScreen> {
  final _api = CareTeamApiService();

  List<Map<String, dynamic>> _patients = [];
  String? _filterPatientId;
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  /// Month / week anchor for [TableCalendar].
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  /// `yyyy-MM-dd` local, or null = show all days grouped.
  String? _dayKeyFilter;

  /// Default: today and future only (planning view).
  _TimelineScope _scope = _TimelineScope.upcoming;

  /// `null` = all reminder types; otherwise matches `reminder_type` (lowercase).
  /// For [task], rows that are not [appointment] or [medication] are included.
  String? _filterReminderType;

  DateTime get _startOfTodayLocal {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  @override
  void initState() {
    super.initState();
    final q = widget.initialPatientId?.trim();
    _filterPatientId = (q != null && q.isNotEmpty) ? q : null;
    final t = widget.initialReminderType?.trim().toLowerCase();
    if (t == 'appointment' || t == 'medication' || t == 'task') {
      _filterReminderType = t;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.getMyPatients();
      if (!mounted) return;
      setState(() {
        _patients = raw;
      });
      await _loadReminders();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadReminders() async {
    setState(() => _loading = true);
    try {
      final targets = _filterPatientId == null || _filterPatientId!.isEmpty
          ? _patients
              .map((p) => p['patient_id']?.toString())
              .whereType<String>()
              .where((id) => id.isNotEmpty)
              .toList()
          : [_filterPatientId!];

      final merged = <Map<String, dynamic>>[];
      for (final pid in targets) {
        try {
          final data = await _api.getPatientReminderList(pid);
          final name = _nameForPatient(pid);
          for (final bucket in ['today', 'upcoming', 'past']) {
            final list = data[bucket];
            if (list is! List) continue;
            for (final item in list) {
              if (item is Map) {
                final m = Map<String, dynamic>.from(item);
                m['_patient_id'] = pid;
                m['_patient_name'] = name;
                m['_bucket'] = bucket;
                merged.add(m);
              }
            }
          }
        } catch (_) {}
      }

      merged.sort((a, b) {
        final ta = DateTime.tryParse(a['scheduled_time']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse(b['scheduled_time']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });

      if (!mounted) return;
      setState(() {
        _rows = merged;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _nameForPatient(String patientId) {
    for (final p in _patients) {
      if (p['patient_id']?.toString() == patientId) {
        final n = (p['full_name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) return n;
        return (p['email'] as String?)?.trim() ?? 'Patient';
      }
    }
    return 'Patient';
  }

  String _dayKey(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(DateTime(d.year, d.month, d.day));

  /// Rows after scope (upcoming vs all) and reminder-type filter — used for list, day picker, and calendar markers.
  List<Map<String, dynamic>> _rowsFilteredByScopeAndType() {
    final start = _startOfTodayLocal;
    return _rows.where((r) {
      final st = DateTime.tryParse(r['scheduled_time']?.toString() ?? '');
      if (st == null) return false;
      final local = st.toLocal();
      if (_scope == _TimelineScope.upcoming) {
        final day = DateTime(local.year, local.month, local.day);
        if (day.isBefore(start)) return false;
      }
      if (_filterReminderType != null && _filterReminderType!.isNotEmpty) {
        final t = (r['reminder_type'] ?? 'task').toString().toLowerCase();
        final want = _filterReminderType!.toLowerCase();
        if (want == 'task') {
          if (t == 'appointment' || t == 'medication') return false;
        } else if (t != want) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  int _countForDay(DateTime day) {
    final key = _dayKey(DateTime(day.year, day.month, day.day));
    return _rowsFilteredByScopeAndType().where((r) {
      final st = DateTime.tryParse(r['scheduled_time']?.toString() ?? '');
      if (st == null) return false;
      return _dayKey(st.toLocal()) == key;
    }).length;
  }

  List<Map<String, dynamic>> _visibleRows() {
    final base = _rowsFilteredByScopeAndType();
    if (_dayKeyFilter == null) return base;
    return base.where((r) {
      final st = DateTime.tryParse(r['scheduled_time']?.toString() ?? '');
      if (st == null) return false;
      return _dayKey(st.toLocal()) == _dayKeyFilter;
    }).toList();
  }

  List<Widget> _buildGroupedSliverChildren() {
    final visible = _visibleRows();
    if (_dayKeyFilter != null) {
      return visible
          .map(
            (r) => _ReminderRow(
              data: r,
              statusColor: _statusColorFor,
              statusLabel: _statusLabelFor,
            ),
          )
          .toList();
    }
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final r in visible) {
      final st = DateTime.tryParse(r['scheduled_time']?.toString() ?? '');
      if (st == null) continue;
      final k = _dayKey(st.toLocal());
      byDay.putIfAbsent(k, () => []).add(r);
    }
    final keys = byDay.keys.toList()..sort();
    final out = <Widget>[];
    for (final k in keys) {
      final parts = k.split('-');
      final d = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      out.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Text(
            DateFormat('EEEE, MMM d').format(d),
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
      for (final r in byDay[k]!) {
        out.add(
          _ReminderRow(
            data: r,
            statusColor: _statusColorFor,
            statusLabel: _statusLabelFor,
          ),
        );
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final visibleRows = _visibleRows();
    final validPatientIds = _patients
        .map((p) => p['patient_id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toSet();
    final selectedPatientValue = (_filterPatientId != null &&
            validPatientIds.contains(_filterPatientId))
        ? _filterPatientId
        : null;
    DateTime? headerDay;
    if (_dayKeyFilter != null) {
      final p = _dayKeyFilter!.split('-');
      if (p.length == 3) {
        headerDay = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.primary),
          onPressed: () => context.go('/caregiver/home'),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Support schedule',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Reminders & appointments',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.65),
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: [
            DropdownButtonFormField<String?>(
                  value: selectedPatientValue,
                  decoration: const InputDecoration(
                    labelText: 'Patient',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All patients'),
                    ),
                    ..._patients.where((p) {
                      final id = p['patient_id']?.toString() ?? '';
                      return id.isNotEmpty;
                    }).map((p) {
                      final id = p['patient_id']!.toString();
                      final label = (p['full_name'] as String?)?.trim().isNotEmpty == true
                          ? p['full_name'] as String
                          : (p['email'] as String?) ?? id;
                      return DropdownMenuItem<String?>(
                        value: id,
                        child: Text(label),
                      );
                    }),
                  ],
                  onChanged: (v) {
                    setState(() => _filterPatientId = v);
                    _loadReminders();
                  },
                ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String?>(
                    value: _filterReminderType,
                    decoration: const InputDecoration(
                      labelText: 'Reminder type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All types'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'appointment',
                        child: Text('Appointments'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'medication',
                        child: Text('Medications'),
                      ),
                      DropdownMenuItem<String?>(
                        value: 'task',
                        child: Text('Tasks & other'),
                      ),
                    ],
                    onChanged: (v) {
                      setState(() => _filterReminderType = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Time range',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      SegmentedButton<_TimelineScope>(
                        segments: const [
                          ButtonSegment<_TimelineScope>(
                            value: _TimelineScope.upcoming,
                            label: Text('Upcoming'),
                            tooltip: 'Today and future',
                          ),
                          ButtonSegment<_TimelineScope>(
                            value: _TimelineScope.all,
                            label: Text('All'),
                            tooltip: 'Includes past',
                          ),
                        ],
                        selected: {_scope},
                        onSelectionChanged: (s) {
                          if (s.isEmpty) return;
                          setState(() => _scope = s.first);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _scope == _TimelineScope.upcoming
                  ? 'Showing today and future events.'
                  : 'Showing all events including past.',
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            if (!_loading && _error == null) ...[
              const SizedBox(height: 8),
              _buildTableCalendar(),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _dayKeyFilter == null
                        ? 'All days · grouped by date'
                        : DateFormat('EEEE, MMM d').format(headerDay ?? DateTime.now()),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                if (_dayKeyFilter != null)
                  TextButton(
                    onPressed: () => setState(() => _dayKeyFilter = null),
                    child: const Text('Show all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (!_loading && _error != null)
              Center(child: Text(_error!, textAlign: TextAlign.center)),
            if (!_loading && _error == null && visibleRows.isEmpty)
              Column(
                children: [
                  const SizedBox(height: 80),
                  Icon(
                    Icons.event_available_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No events match your filters.\n'
                    'Try All time, another patient, or All types.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ],
              ),
            if (!_loading && _error == null && visibleRows.isNotEmpty)
              ..._buildGroupedSliverChildren(),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCalendar() {
    final scheme = Theme.of(context).colorScheme;
    DateTime? selectedParsed;
    if (_dayKeyFilter != null) {
      final p = _dayKeyFilter!.split('-');
      if (p.length == 3) {
        selectedParsed = DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      elevation: 0,
      color: scheme.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: SegmentedButton<CalendarFormat>(
                segments: const [
                  ButtonSegment<CalendarFormat>(
                    value: CalendarFormat.week,
                    icon: Icon(Icons.view_week, size: 18),
                    label: Text('Week'),
                  ),
                  ButtonSegment<CalendarFormat>(
                    value: CalendarFormat.month,
                    icon: Icon(Icons.calendar_month, size: 18),
                    label: Text('Month'),
                  ),
                ],
                selected: {_calendarFormat},
                onSelectionChanged: (Set<CalendarFormat> next) {
                  if (next.isEmpty) return;
                  setState(() => _calendarFormat = next.first);
                },
              ),
            ),
            TableCalendar(
              firstDay: DateTime(2020, 1, 1),
              lastDay: DateTime(2035, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  selectedParsed != null && isSameDay(selectedParsed, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _focusedDay = focused;
                  final k = _dayKey(selected);
                  _dayKeyFilter = _dayKeyFilter == k ? null : k;
                });
              },
              onPageChanged: (focused) {
                setState(() => _focusedDay = focused);
              },
              eventLoader: (day) {
                final n = _countForDay(day);
                if (n <= 0) return <Object>[];
                return List<Object>.filled(n, Object(), growable: false);
              },
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {
                CalendarFormat.week: 'Week',
                CalendarFormat.month: 'Month',
              },
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarStyle: CalendarStyle(
                outsideDaysVisible: _calendarFormat == CalendarFormat.week,
                markersMaxCount: 4,
                markerDecoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
                todayTextStyle: TextStyle(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: scheme.primary),
                rightChevronIcon:
                    Icon(Icons.chevron_right, color: scheme.primary),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle:
                    TextStyle(color: scheme.secondary, fontSize: 12),
                weekendStyle:
                    TextStyle(color: scheme.secondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColorFor(Map<String, dynamic> r) {
    final s = (r['status'] ?? 'pending').toString().toLowerCase();
    final st = DateTime.tryParse(r['scheduled_time']?.toString() ?? '');
    switch (s) {
      case 'completed':
        return Colors.green;
      case 'skipped':
        return Colors.deepOrange;
      case 'snoozed':
        return Colors.purple;
      case 'pending':
        if (st != null && st.isBefore(DateTime.now())) {
          return Colors.red;
        }
        return Colors.blue;
      default:
        return Colors.blueGrey;
    }
  }

  String _statusLabelFor(Map<String, dynamic> r) {
    final display = (r['display_status'] as String?)?.trim();
    if (display != null && display.isNotEmpty) return display;
    final s = (r['status'] ?? 'pending').toString();
    if (s.isEmpty) return 'Pending';
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

class _ReminderRow extends StatelessWidget {
  const _ReminderRow({
    required this.data,
    required this.statusColor,
    required this.statusLabel,
  });

  final Map<String, dynamic> data;
  final Color Function(Map<String, dynamic>) statusColor;
  final String Function(Map<String, dynamic>) statusLabel;

  @override
  Widget build(BuildContext context) {
    final title = (data['title'] as String?)?.trim().isNotEmpty == true
        ? data['title'] as String
        : 'Reminder';
    final patient = (data['_patient_name'] as String?) ?? 'Patient';
    final st =
        DateTime.tryParse(data['scheduled_time']?.toString() ?? '') ?? DateTime.now();
    final type = (data['reminder_type'] ?? 'task').toString();
    final sc = statusColor(data);
    final label = statusLabel(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(
          type == 'appointment'
              ? Icons.calendar_today
              : type == 'medication'
                  ? Icons.medication
                  : Icons.task_alt,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('$patient · $type'),
            Text(
              DateFormat('h:mm a').format(st.toLocal()),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white),
          ),
          backgroundColor: sc,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onTap: () {
          final pid = data['_patient_id']?.toString();
          if (pid != null && pid.isNotEmpty) {
            context.go('/caregiver/patient-overview?patientId=$pid');
          }
        },
      ),
    );
  }
}
