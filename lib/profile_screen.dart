import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'task_engine.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Box _profileBox;
  late Box _timetableBox;
  late Box _roadmapBox;
  final _nameController = TextEditingController();
  final _branchController = TextEditingController();
  final _yearController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = true;

  // Stats
  int _completedSkills = 0;
  int _totalClasses = 0;
  int _attendedClasses = 0;
  double _overallAttendance = 100.0;
  Map<String, double> _subjectAttendance = {};

  @override
  void initState() {
    super.initState();
    _openBoxes();
  }

  Future<void> _openBoxes() async {
    _profileBox = await Hive.openBox('profile');
    _timetableBox = await Hive.openBox('timetable');
    _roadmapBox = await Hive.openBox('roadmap');
    setState(() {
      _nameController.text = _profileBox.get('name', defaultValue: '');
      _branchController.text =
          _profileBox.get('branch', defaultValue: 'AIDS');
      _yearController.text =
          _profileBox.get('year', defaultValue: 'SY B.Tech');
    });
    _calculateStats();
  }

  void _calculateStats() {
    // Completed skills
    final skills = _roadmapBox.values
        .map((s) => Map<String, dynamic>.from(s))
        .toList();
    _completedSkills =
        skills.where((s) => s['status'] == 'completed').length;

    // Attendance per subject
    final slots = _timetableBox.values.toList();
    final Map<String, List<Map>> subjectSlots = {};

    for (final slot in slots) {
      final subject = slot['subject'] as String? ?? 'Unknown';
      subjectSlots[subject] = subjectSlots[subject] ?? [];
      subjectSlots[subject]!.add(Map<String, dynamic>.from(slot));
    }

    int totalT = 0;
    int totalA = 0;
    final Map<String, double> attendance = {};

    for (final entry in subjectSlots.entries) {
      int subTotal = 0;
      int subAttended = 0;
      for (final slot in entry.value) {
        subTotal += (slot['totalClasses'] ?? 0) as int;
        subAttended += (slot['attendedClasses'] ?? 0) as int;
      }
      totalT += subTotal;
      totalA += subAttended;
      if (subTotal > 0) {
        attendance[entry.key] = (subAttended / subTotal) * 100;
      }
    }

    setState(() {
      _totalClasses = totalT;
      _attendedClasses = totalA;
      _overallAttendance =
          totalT > 0 ? (totalA / totalT) * 100 : 100.0;
      _subjectAttendance = attendance;
      _isLoading = false;
    });
  }

  void _saveProfile() async {
    await _profileBox.put('name', _nameController.text);
    await _profileBox.put('branch', _branchController.text);
    await _profileBox.put('year', _yearController.text);
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile saved!'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }

  Color _getAttendanceColor(double percent) {
    if (percent >= 85) return Colors.greenAccent;
    if (percent >= 75) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final attendanceAdvice =
        TaskEngine.getAttendanceAdvice(_overallAttendance);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
            Text('Your academic overview',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit,
                color: const Color(0xFF6C63FF)),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar + Name
                  const SizedBox(height: 10),
                  Container(
                    width: 90,
                    height: 90,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B37A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.white, size: 50),
                  ),
                  const SizedBox(height: 16),

                  // Info Fields
                  _buildInfoField('Full Name', _nameController,
                      Icons.person_outline),
                  const SizedBox(height: 10),
                  _buildInfoField(
                      'Branch', _branchController, Icons.school_outlined),
                  const SizedBox(height: 10),
                  _buildInfoField('Year', _yearController,
                      Icons.calendar_today_outlined),
                  const SizedBox(height: 20),

                  // Overall Stats Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3B37A0)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceAround,
                          children: [
                            _buildStat('$_completedSkills', 'Skills Done'),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24),
                            _buildStat(
                                '${_overallAttendance.toStringAsFixed(0)}%',
                                'Attendance'),
                            Container(
                                width: 1,
                                height: 40,
                                color: Colors.white24),
                            _buildStat('$_totalClasses', 'Total Classes'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Attendance Progress Bar
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Overall Attendance',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12)),
                                Text(
                                    '${_overallAttendance.toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _overallAttendance / 100,
                                backgroundColor: Colors.white24,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                  _overallAttendance >= 75
                                      ? Colors.greenAccent
                                      : Colors.redAccent,
                                ),
                                minHeight: 8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Attendance Advice
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _getAttendanceColor(_overallAttendance)
                              .withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _overallAttendance >= 75
                              ? Icons.check_circle
                              : Icons.warning,
                          color:
                              _getAttendanceColor(_overallAttendance),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            attendanceAdvice,
                            style: TextStyle(
                              color:
                                  _getAttendanceColor(_overallAttendance),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Subject-wise Attendance
                  if (_subjectAttendance.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: const Text('Subject-wise Attendance',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 10),
                    ..._subjectAttendance.entries.map((entry) {
                      final color = _getAttendanceColor(entry.value);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: color.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                                Text(
                                  '${entry.value.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: entry.value / 100,
                                backgroundColor: Colors.white12,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(
                                        color),
                                minHeight: 6,
                              ),
                            ),
                            if (entry.value < 75) ...[
                              const SizedBox(height: 6),
                              Text(
                                '⚠️ Below 75% — Attend immediately!',
                                style: TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoField(
      String label, TextEditingController controller, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: _isEditing
                ? TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: label,
                      labelStyle:
                          const TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        controller.text.isEmpty
                            ? 'Not set'
                            : controller.text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }
}