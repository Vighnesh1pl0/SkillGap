import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  late Box _timetableBox;
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  String _selectedDay = 'Mon';

  // 🔥 AIDS Branch Default Timetable
  final List<Map<String, String>> _defaultTimetable = [
    // Monday
    {'day': 'Mon', 'subject': 'Mobile App Dev', 'start': '9:00 AM', 'end': '10:00 AM'},
    {'day': 'Mon', 'subject': 'Machine Learning', 'start': '10:00 AM', 'end': '11:00 AM'},
    {'day': 'Mon', 'subject': 'Data Structures', 'start': '11:30 AM', 'end': '12:30 PM'},
    {'day': 'Mon', 'subject': 'Deep Learning', 'start': '2:00 PM', 'end': '3:00 PM'},
    // Tuesday
    {'day': 'Tue', 'subject': 'Data Structures', 'start': '9:00 AM', 'end': '10:00 AM'},
    {'day': 'Tue', 'subject': 'Mobile App Dev Lab', 'start': '10:00 AM', 'end': '12:00 PM'},
    {'day': 'Tue', 'subject': 'Engineering Maths', 'start': '2:00 PM', 'end': '3:00 PM'},
    // Wednesday
    {'day': 'Wed', 'subject': 'Machine Learning', 'start': '9:00 AM', 'end': '10:00 AM'},
    {'day': 'Wed', 'subject': 'Deep Learning Lab', 'start': '10:00 AM', 'end': '12:00 PM'},
    {'day': 'Wed', 'subject': 'Data Structures', 'start': '2:00 PM', 'end': '3:00 PM'},
    // Thursday
    {'day': 'Thu', 'subject': 'Engineering Maths', 'start': '9:00 AM', 'end': '10:00 AM'},
    {'day': 'Thu', 'subject': 'Mobile App Dev', 'start': '10:00 AM', 'end': '11:00 AM'},
    {'day': 'Thu', 'subject': 'ML Lab', 'start': '11:30 AM', 'end': '1:30 PM'},
    // Friday
    {'day': 'Fri', 'subject': 'Deep Learning', 'start': '9:00 AM', 'end': '10:00 AM'},
    {'day': 'Fri', 'subject': 'Engineering Maths', 'start': '10:00 AM', 'end': '11:00 AM'},
    {'day': 'Fri', 'subject': 'Mobile App Dev', 'start': '11:30 AM', 'end': '12:30 PM'},
    {'day': 'Fri', 'subject': 'Project Work', 'start': '2:00 PM', 'end': '4:00 PM'},
    // Saturday
    {'day': 'Sat', 'subject': 'Data Structures Lab', 'start': '9:00 AM', 'end': '11:00 AM'},
    {'day': 'Sat', 'subject': 'Engineering Maths', 'start': '11:30 AM', 'end': '12:30 PM'},
  ];

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _timetableBox = await Hive.openBox('timetable');
    setState(() {});
  }

  List<Map> _getSlotsForDay(String day) {
    final allSlots = _timetableBox.values.toList();
    return allSlots.where((s) => s['day'] == day).cast<Map>().toList();
  }

  void _addSlot(String subject, String start, String end) async {
    await _timetableBox.add({
      'day': _selectedDay,
      'subject': subject,
      'start': start,
      'end': end,
      'cancelled': false,
      'attended': false,
      'totalClasses': 0,
      'attendedClasses': 0,
    });
    setState(() {});
  }

  void _loadDefaultTimetable() async {
    await _timetableBox.clear();
    for (var slot in _defaultTimetable) {
      await _timetableBox.add({
        'day': slot['day'],
        'subject': slot['subject'],
        'start': slot['start'],
        'end': slot['end'],
        'cancelled': false,
        'attended': false,
        'totalClasses': 0,
        'attendedClasses': 0,
      });
    }
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ AIDS Timetable loaded successfully!'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }

  void _clearTimetable() async {
    await _timetableBox.clear();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🗑️ Timetable cleared!'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  void _showLoadTemplateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Load Template',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will load the default AIDS branch timetable.\n\nExisting timetable will be cleared!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () {
              Navigator.pop(context);
              _loadDefaultTimetable();
            },
            child: const Text('Load', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteSlot(int index) async {
    final keys = _timetableBox.keys.toList();
    final daySlots = _getSlotsForDay(_selectedDay);
    if (index < daySlots.length) {
      final slotToDelete = daySlots[index];
      for (var key in keys) {
        final val = _timetableBox.get(key);
        if (val != null &&
            val['day'] == slotToDelete['day'] &&
            val['subject'] == slotToDelete['subject'] &&
            val['start'] == slotToDelete['start']) {
          await _timetableBox.delete(key);
          break;
        }
      }
      setState(() {});
    }
  }

  void _toggleCancel(Map slot) async {
    final keys = _timetableBox.keys.toList();
    for (var key in keys) {
      final val = _timetableBox.get(key);
      if (val != null &&
          val['day'] == slot['day'] &&
          val['subject'] == slot['subject'] &&
          val['start'] == slot['start']) {
        final isCancelled = !(val['cancelled'] ?? false);
        await _timetableBox.put(key, {
          ...Map<String, dynamic>.from(val),
          'cancelled': isCancelled,
        });
        break;
      }
    }
    setState(() {});
  }

  void _toggleAttendance(Map slot) async {
    if (slot['cancelled'] == true) return;
    final keys = _timetableBox.keys.toList();
    for (var key in keys) {
      final val = _timetableBox.get(key);
      if (val != null &&
          val['day'] == slot['day'] &&
          val['subject'] == slot['subject'] &&
          val['start'] == slot['start']) {
        final wasAttended = val['attended'] ?? false;
        final isAttended = !wasAttended;
        int total = (val['totalClasses'] ?? 0) as int;
        int attended = (val['attendedClasses'] ?? 0) as int;
        if (!wasAttended) {
          total += 1;
          attended += 1;
        } else {
          attended = (attended - 1).clamp(0, 999);
        }
        await _timetableBox.put(key, {
          ...Map<String, dynamic>.from(val),
          'attended': isAttended,
          'totalClasses': total,
          'attendedClasses': attended,
        });
        break;
      }
    }
    setState(() {});
  }

  double _getAttendancePercent(Map slot) {
    final total = (slot['totalClasses'] ?? 0) as int;
    final attended = (slot['attendedClasses'] ?? 0) as int;
    if (total == 0) return 100.0;
    return (attended / total) * 100;
  }

  Color _getAttendanceColor(double percent) {
    if (percent >= 85) return Colors.greenAccent;
    if (percent >= 75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  void _showAddSlotDialog() {
    final subjectController = TextEditingController();
    final startController = TextEditingController();
    final endController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Add Class',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Subject',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: startController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Start Time (e.g. 9:00 AM)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: endController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'End Time (e.g. 10:00 AM)',
                labelStyle: TextStyle(color: Colors.white54),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: Color(0xFF6C63FF)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel',
                style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF)),
            onPressed: () {
              if (subjectController.text.isNotEmpty &&
                  startController.text.isNotEmpty &&
                  endController.text.isNotEmpty) {
                _addSlot(
                  subjectController.text,
                  startController.text,
                  endController.text,
                );
                Navigator.pop(context);
              }
            },
            child:
                const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daySlots =
        _timetableBox.isOpen ? _getSlotsForDay(_selectedDay) : [];
    final totalSlots = _timetableBox.isOpen ? _timetableBox.length : 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Timetable',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
            Text('Manage your schedule',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: _clearTimetable,
            tooltip: 'Clear All',
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔥 Load Template Banner
          if (totalSlots == 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3B37A0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome,
                      color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No timetable yet!',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                        Text('Load AIDS branch template instantly',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _showLoadTemplateDialog,
                    child: const Text('Load',
                        style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$totalSlots classes loaded',
                      style: const TextStyle(
                          color: Colors.white54, fontSize: 12)),
                  GestureDetector(
                    onTap: _showLoadTemplateDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6C63FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF6C63FF).withOpacity(0.4)),
                      ),
                      child: const Text('Reload Template',
                          style: TextStyle(
                              color: Color(0xFF6C63FF),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),

          // Day Selector
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = day == _selectedDay;
                final dayCount = _getSlotsForDay(day).length;
                return GestureDetector(
                  onTap: () => setState(() => _selectedDay = day),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF6C63FF)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF6C63FF)
                            : Colors.white24,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(day,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white54,
                              fontWeight: FontWeight.w600,
                            )),
                        if (dayCount > 0) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.3)
                                  : const Color(0xFF6C63FF)
                                      .withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Text('$dayCount',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 9)),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Slots List
          Expanded(
            child: daySlots.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.event_busy,
                            color: Colors.white24, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'No classes on this day!',
                          style: TextStyle(
                              color: Colors.white38, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _showAddSlotDialog,
                          child: const Text('+ Add a class',
                              style: TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 13)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: daySlots.length,
                    itemBuilder: (context, index) {
                      final slot = daySlots[index];
                      final isCancelled = slot['cancelled'] ?? false;
                      final isAttended = slot['attended'] ?? false;
                      final attendPercent =
                          _getAttendancePercent(slot);
                      final attendColor =
                          _getAttendanceColor(attendPercent);

                      return Dismissible(
                        key: UniqueKey(),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteSlot(index),
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child:
                              const Icon(Icons.delete, color: Colors.red),
                        ),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? Colors.red.withOpacity(0.08)
                                : const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCancelled
                                  ? Colors.red.withOpacity(0.4)
                                  : const Color(0xFF6C63FF)
                                      .withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    isCancelled
                                        ? Icons.cancel
                                        : Icons.book,
                                    color: isCancelled
                                        ? Colors.redAccent
                                        : const Color(0xFF6C63FF),
                                    size: 28,
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          slot['subject'],
                                          style: TextStyle(
                                            color: isCancelled
                                                ? Colors.white38
                                                : Colors.white,
                                            fontWeight: FontWeight.w600,
                                            decoration: isCancelled
                                                ? TextDecoration
                                                    .lineThrough
                                                : null,
                                          ),
                                        ),
                                        Text(
                                          '${slot['start']} - ${slot['end']}',
                                          style: const TextStyle(
                                            color: Colors.white54,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _toggleCancel(slot),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isCancelled
                                            ? Colors.red.withOpacity(0.2)
                                            : Colors.orange
                                                .withOpacity(0.2),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isCancelled
                                            ? 'Cancelled'
                                            : 'Cancel?',
                                        style: TextStyle(
                                          color: isCancelled
                                              ? Colors.redAccent
                                              : Colors.orangeAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.school,
                                          color: attendColor, size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Attendance: ${attendPercent.toStringAsFixed(0)}%',
                                        style: TextStyle(
                                            color: attendColor,
                                            fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: () =>
                                        _toggleAttendance(slot),
                                    child: Container(
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isAttended
                                            ? Colors.green
                                                .withOpacity(0.2)
                                            : Colors.white
                                                .withOpacity(0.05),
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        isAttended
                                            ? '✅ Attended'
                                            : 'Mark Attended',
                                        style: TextStyle(
                                          color: isAttended
                                              ? Colors.greenAccent
                                              : Colors.white38,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF6C63FF),
        onPressed: _showAddSlotDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}