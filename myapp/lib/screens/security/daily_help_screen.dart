import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:myapp/models/user_model.dart';
import 'package:myapp/models/daily_help_model.dart';
import 'package:myapp/providers/app_mode_provider.dart';
import 'package:myapp/providers/theme_provider.dart';
import 'package:myapp/services/visitor_service.dart';

/// Screen for residents to manage their daily help staff
/// and mark/view attendance.
class DailyHelpScreen extends StatefulWidget {
  const DailyHelpScreen({super.key});

  @override
  State<DailyHelpScreen> createState() => _DailyHelpScreenState();
}

class _DailyHelpScreenState extends State<DailyHelpScreen> {
  String _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final appMode = Provider.of<AppModeProvider>(context);
    final visitorService = Provider.of<VisitorService>(context, listen: false);

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Use unitId from membership in society mode — using uid as placeholder
    final stream = visitorService.getDailyHelpByUnit(user.uid);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Daily Help',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
        actions: [
          // Month selector
          TextButton.icon(
            onPressed: _pickMonth,
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: Text(
              DateFormat('MMM yyyy').format(DateFormat('yyyy-MM').parse(_selectedMonth)),
              style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddStaffSheet(context, user, appMode),
        backgroundColor: ThemeProvider.accentBlue,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: Text('Add Staff',
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<DailyHelpModel>>(
        stream: stream,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final staff = snap.data ?? [];
          if (staff.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded,
                      size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('No staff registered',
                      style: GoogleFonts.outfit(
                          fontSize: 16, color: Colors.grey.shade400)),
                  const SizedBox(height: 8),
                  Text('Add your daily help to track attendance',
                      style: GoogleFonts.inter(
                          fontSize: 13, color: Colors.grey.shade300)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: staff.length,
            itemBuilder: (ctx, i) => _StaffCard(
              staff: staff[i],
              month: _selectedMonth,
              onMarkAttendance: (dateKey, status) {
                context.read<VisitorService>().markAttendance(
                      helpId: staff[i].id,
                      dateKey: dateKey,
                      status: status,
                    );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('yyyy-MM').parse(_selectedMonth),
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() =>
          _selectedMonth = DateFormat('yyyy-MM').format(picked));
    }
  }

  void _showAddStaffSheet(BuildContext context, UserModel user, AppModeProvider appMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddStaffSheet(
        unitId: user.uid,
        societyId: appMode.activeSociety?.id ?? '',
        residentId: user.uid,
        unitNumber: 'My Unit',
      ),
    );
  }
}

class _StaffCard extends StatefulWidget {
  final DailyHelpModel staff;
  final String month;
  final void Function(String dateKey, AttendanceStatus status) onMarkAttendance;

  const _StaffCard({
    required this.staff,
    required this.month,
    required this.onMarkAttendance,
  });

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final staff = widget.staff;
    final presentDays = staff.presentDaysInMonth(widget.month);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayRecord = staff.attendance[today];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: ThemeProvider.accentBlue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: staff.photoUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(staff.photoUrl!, fit: BoxFit.cover),
                          )
                        : Center(
                            child: Text(staff.category.icon,
                                style: const TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(staff.name,
                            style: GoogleFonts.outfit(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: ThemeProvider.primaryNavy)),
                        Text(staff.category.label,
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey.shade500)),
                        Text('$presentDays days present this month',
                            style: GoogleFonts.inter(
                                fontSize: 11, color: ThemeProvider.accentBlue)),
                      ],
                    ),
                  ),
                  // Today's attendance quick-mark
                  _TodayBadge(
                    record: todayRecord,
                    onMark: (status) => widget.onMarkAttendance(today, status),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
          // Calendar grid
          if (_expanded) ...[
            Divider(height: 1, color: Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.all(16),
              child: _AttendanceCalendar(
                staff: staff,
                month: widget.month,
                onMark: widget.onMarkAttendance,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TodayBadge extends StatelessWidget {
  final AttendanceRecord? record;
  final void Function(AttendanceStatus) onMark;

  const _TodayBadge({this.record, required this.onMark});

  @override
  Widget build(BuildContext context) {
    if (record != null) {
      final colors = {
        AttendanceStatus.present: Colors.green,
        AttendanceStatus.absent: Colors.red,
        AttendanceStatus.half_day: Colors.orange,
        AttendanceStatus.holiday: Colors.blue,
      };
      final labels = {
        AttendanceStatus.present: 'P',
        AttendanceStatus.absent: 'A',
        AttendanceStatus.half_day: '½',
        AttendanceStatus.holiday: 'H',
      };
      return Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: (colors[record!.status] ?? Colors.grey).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: colors[record!.status] ?? Colors.grey,
              width: 1.5),
        ),
        child: Center(
          child: Text(
            labels[record!.status] ?? '?',
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                color: colors[record!.status] ?? Colors.grey),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showMarkSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: ThemeProvider.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text('Mark Today',
            style: GoogleFonts.outfit(
                fontSize: 11,
                color: ThemeProvider.accentBlue,
                fontWeight: FontWeight.w600)),
      ),
    );
  }

  void _showMarkSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Today's Attendance",
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            for (final s in AttendanceStatus.values)
              ListTile(
                leading: _AttendanceDot(status: s, size: 30),
                title: Text(_statusLabel(s),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                onTap: () {
                  onMark(s);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:  return 'Present';
      case AttendanceStatus.absent:   return 'Absent';
      case AttendanceStatus.half_day: return 'Half Day';
      case AttendanceStatus.holiday:  return 'Holiday';
    }
  }
}

class _AttendanceCalendar extends StatelessWidget {
  final DailyHelpModel staff;
  final String month;
  final void Function(String dateKey, AttendanceStatus status) onMark;

  const _AttendanceCalendar({
    required this.staff,
    required this.month,
    required this.onMark,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('yyyy-MM').parse(month);
    final daysInMonth = DateUtils.getDaysInMonth(date.year, date.month);
    final today = DateTime.now();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(DateFormat('MMMM yyyy').format(date),
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                color: ThemeProvider.primaryNavy)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: List.generate(daysInMonth, (i) {
            final day = i + 1;
            final dayDate = DateTime(date.year, date.month, day);
            final isFuture = dayDate.isAfter(today);
            final dateKey =
                DateFormat('yyyy-MM-dd').format(dayDate);
            final record = staff.attendance[dateKey];
            return GestureDetector(
              onTap: isFuture
                  ? null
                  : () => _showDayMarkSheet(context, dateKey, day, record),
              child: _AttendanceDot(
                status: record?.status,
                label: '$day',
                size: 36,
                isFuture: isFuture,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        // Legend
        Row(
          children: [
            _LegendItem(color: Colors.green, label: 'Present'),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.red, label: 'Absent'),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.orange, label: 'Half'),
            const SizedBox(width: 16),
            _LegendItem(color: Colors.blue, label: 'Holiday'),
          ],
        ),
      ],
    );
  }

  void _showDayMarkSheet(
      BuildContext context, String dateKey, int day, AttendanceRecord? current) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day $day — Mark Attendance',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            for (final s in AttendanceStatus.values)
              ListTile(
                leading: _AttendanceDot(status: s, size: 30),
                title: Text(_statusLabel(s),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w500)),
                trailing: current?.status == s
                    ? const Icon(Icons.check_rounded, color: Colors.green)
                    : null,
                onTap: () {
                  onMark(dateKey, s);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present:  return 'Present';
      case AttendanceStatus.absent:   return 'Absent';
      case AttendanceStatus.half_day: return 'Half Day';
      case AttendanceStatus.holiday:  return 'Holiday';
    }
  }
}

class _AttendanceDot extends StatelessWidget {
  final AttendanceStatus? status;
  final String? label;
  final double size;
  final bool isFuture;

  const _AttendanceDot({
    this.status,
    this.label,
    required this.size,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = {
      AttendanceStatus.present:  Colors.green,
      AttendanceStatus.absent:   Colors.red,
      AttendanceStatus.half_day: Colors.orange,
      AttendanceStatus.holiday:  Colors.blue,
    };
    final bg = isFuture
        ? Colors.grey.shade100
        : status != null
            ? colors[status]!.withValues(alpha: 0.15)
            : Colors.grey.shade100;
    final fg = isFuture
        ? Colors.grey.shade300
        : status != null
            ? colors[status]!
            : Colors.grey.shade400;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: status != null && !isFuture
            ? Border.all(color: fg, width: 1.5)
            : null,
      ),
      child: Center(
        child: Text(
          label ?? (status == AttendanceStatus.present
              ? 'P'
              : status == AttendanceStatus.absent
                  ? 'A'
                  : status == AttendanceStatus.half_day
                      ? '½'
                      : 'H'),
          style: GoogleFonts.outfit(
              fontSize: size * 0.33,
              fontWeight: FontWeight.w600,
              color: fg),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Add Staff Bottom Sheet
// ──────────────────────────────────────────────
class _AddStaffSheet extends StatefulWidget {
  final String unitId;
  final String societyId;
  final String residentId;
  final String unitNumber;

  const _AddStaffSheet({
    required this.unitId,
    required this.societyId,
    required this.residentId,
    required this.unitNumber,
  });

  @override
  State<_AddStaffSheet> createState() => _AddStaffSheetState();
}

class _AddStaffSheetState extends State<_AddStaffSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  DailyHelpCategory _category = DailyHelpCategory.maid;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final visitorService = context.read<VisitorService>();
    try {
      await visitorService.registerDailyHelp(DailyHelpModel(
        id: '',
        societyId: widget.societyId,
        unitId: widget.unitId,
        residentId: widget.residentId,
        unitNumber: widget.unitNumber,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        category: _category,
        registeredAt: DateTime.now(),
      ));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Register Staff',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ThemeProvider.primaryNavy)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: DailyHelpCategory.values.map((cat) {
                final sel = _category == cat;
                return GestureDetector(
                  onTap: () => setState(() => _category = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: sel
                          ? ThemeProvider.accentBlue
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${cat.icon} ${cat.label}',
                      style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: sel ? Colors.white : Colors.grey.shade700),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ThemeProvider.accentBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('Register',
                        style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
