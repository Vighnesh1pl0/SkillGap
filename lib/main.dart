import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'timetable_screen.dart';
import 'roadmap_screen.dart';
import 'profile_screen.dart';
import 'gap_detector.dart';
import 'task_engine.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const SkillGapApp());
}

class SkillGapApp extends StatelessWidget {
  const SkillGapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillGap',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeBody(),
    const TimetableScreen(),
    const RoadmapScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: _screens[_currentIndex < 4 ? _currentIndex : 0],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex < 4 ? _currentIndex : 0,
        backgroundColor: const Color(0xFF1A1A2E),
        selectedItemColor: const Color(0xFF6C63FF),
        unselectedItemColor: Colors.white38,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'Timetable'),
          BottomNavigationBarItem(
              icon: Icon(Icons.map), label: 'Roadmap'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class HomeBody extends StatefulWidget {
  const HomeBody({super.key});

  @override
  State<HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends State<HomeBody> {
  late Box _timetableBox;
  late Box _roadmapBox;
  List<FreeGap> _gaps = [];
  List<Map<String, dynamic>> _availableSkills = [];
  List<TaskRecommendation> _recommendations = [];
  String _dayRating = '';
  bool _isLoading = true;
  String _selectedDay = '';

  @override
  void initState() {
    super.initState();
    _selectedDay = _getCurrentDay();
    _loadData();
  }

  String _getCurrentDay() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[DateTime.now().weekday - 1];
  }

  Future<void> _loadData() async {
    _timetableBox = await Hive.openBox('timetable');
    _roadmapBox = await Hive.openBox('roadmap');
    _calculateGaps();
    _loadAvailableSkills();
  }

  void _loadAvailableSkills() {
    final skills = _roadmapBox.values
        .map((s) => Map<String, dynamic>.from(s))
        .where((s) => s['status'] == 'available')
        .toList();
    setState(() => _availableSkills = skills);
  }

  void _calculateGaps() {
    final allSlots = _timetableBox.values.toList();
    final todaySlots = allSlots
        .where((s) => s['day'] == _selectedDay)
        .map((s) => TimeSlot(
              subject: s['subject'] ?? '',
              day: s['day'] ?? '',
              startHour: _parseHour(s['start'] ?? '9:00 AM'),
              startMinute: _parseMinute(s['start'] ?? '9:00 AM'),
              endHour: _parseHour(s['end'] ?? '10:00 AM'),
              endMinute: _parseMinute(s['end'] ?? '10:00 AM'),
              isCancelled: s['cancelled'] ?? false,
            ))
        .toList();

    final gaps = GapDetector.detectGaps(todaySlots);

    List<TaskRecommendation> recs = [];
    if (gaps.isNotEmpty) {
      final bestGap = gaps
          .reduce((a, b) => a.durationMinutes > b.durationMinutes ? a : b);
      final allSubjects = _timetableBox.values
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
      final overallAttendance =
          _calculateOverallAttendance(allSubjects);
      recs = TaskEngine.getRecommendations(
        gapMinutes: bestGap.durationMinutes,
        availableSkills: _availableSkills,
        allSubjects: allSubjects,
        overallAttendance: overallAttendance,
      );
    }

    setState(() {
      _gaps = gaps;
      _dayRating = GapDetector.getDayRating(gaps);
      _recommendations = recs;
      _isLoading = false;
    });
  }

  double _calculateOverallAttendance(
      List<Map<String, dynamic>> slots) {
    int total = 0;
    int attended = 0;
    for (final slot in slots) {
      total += (slot['totalClasses'] ?? 0) as int;
      attended += (slot['attendedClasses'] ?? 0) as int;
    }
    if (total == 0) return 100.0;
    return (attended / total) * 100;
  }

  int _parseHour(String time) {
    try {
      final parts = time.split(':');
      int hour = int.parse(parts[0].trim());
      final rest = parts[1].trim().toUpperCase();
      if (rest.contains('PM') && hour != 12) hour += 12;
      if (rest.contains('AM') && hour == 12) hour = 0;
      return hour;
    } catch (e) {
      return 9;
    }
  }

  int _parseMinute(String time) {
    try {
      final parts = time.split(':');
      final rest = parts[1].trim();
      final digits = rest.replaceAll(RegExp(r'[^0-9]'), '');
      return int.parse(digits.substring(0, 2));
    } catch (e) {
      return 0;
    }
  }

  Color _getGapColor(GapQuality quality) {
    switch (quality) {
      case GapQuality.excellent: return Colors.greenAccent;
      case GapQuality.good: return const Color(0xFF6C63FF);
      case GapQuality.short: return Colors.orangeAccent;
      case GapQuality.tooShort: return Colors.white38;
    }
  }

  IconData _getGapIcon(GapQuality quality) {
    switch (quality) {
      case GapQuality.excellent: return Icons.star;
      case GapQuality.good: return Icons.thumb_up;
      case GapQuality.short: return Icons.bolt;
      case GapQuality.tooShort: return Icons.hourglass_empty;
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final totalFreeTime =
        _gaps.fold(0, (sum, gap) => sum + gap.durationMinutes);
    final completedSkills = _roadmapBox.values
        .where((s) => s['status'] == 'completed')
        .length;
    final motivationalMsg = TaskEngine.getMotivationalMessage(
        totalFreeTime, completedSkills);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('SkillGap',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
            Text('Your Skill Optimizer',
                style:
                    TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon:
                const Icon(Icons.refresh, color: Color(0xFF6C63FF)),
            onPressed: () {
              _loadAvailableSkills();
              _calculateGaps();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWelcomeCard(totalFreeTime, motivationalMsg),
                  const SizedBox(height: 16),
                  _buildStatsRow(),
                  const SizedBox(height: 16),
                  _buildDayRatingCard(),
                  const SizedBox(height: 16),
                  _buildSectionTitle(
                      '⏰ Today\'s Free Gaps ($_selectedDay)'),
                  const SizedBox(height: 8),
                  _gaps.isEmpty
                      ? _buildNoGapsCard()
                      : Column(
                          children: _gaps
                              .map((gap) => _buildGapCard(gap))
                              .toList(),
                        ),
                  const SizedBox(height: 16),
                  if (_recommendations.isNotEmpty) ...[
                    _buildSectionTitle(
                        '🎯 Smart Task Recommendations'),
                    const SizedBox(height: 8),
                    ..._recommendations
                        .take(4)
                        .map((rec) => _buildRecommendationCard(rec))
                        .toList(),
                    const SizedBox(height: 16),
                  ],
                  if (_availableSkills.isNotEmpty) ...[
                    _buildSectionTitle('📌 Skills Ready to Learn'),
                    const SizedBox(height: 8),
                    _buildAvailableSkillsCard(),
                    const SizedBox(height: 20),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildWelcomeCard(
      int totalFreeTime, String motivationalMsg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF3B37A0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${_getGreeting()}, Vighnesh! 👋',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(motivationalMsg,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildChip(
                  '${_gaps.length} gaps', Icons.access_time),
              const SizedBox(width: 8),
              _buildChip(
                  '$totalFreeTime mins free', Icons.timer),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildStatsRow() {
    final cancelledToday = _timetableBox.values
        .where((s) =>
            s['day'] == _selectedDay &&
            (s['cancelled'] ?? false))
        .length;
    final totalToday = _timetableBox.values
        .where((s) => s['day'] == _selectedDay)
        .length;

    return Row(
      children: [
        Expanded(
            child: _buildStatCard(
                '$totalToday', 'Classes', Colors.blueAccent)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard(
                '$cancelledToday', 'Cancelled', Colors.redAccent)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard('${_gaps.length}', 'Free Gaps',
                Colors.greenAccent)),
        const SizedBox(width: 10),
        Expanded(
            child: _buildStatCard('${_availableSkills.length}',
                'Skills', const Color(0xFF6C63FF))),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildDayRatingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.orangeAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.insights,
              color: Colors.orangeAccent, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Day Rating',
                  style: TextStyle(
                      color: Colors.white54, fontSize: 12)),
              Text(_dayRating,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold));
  }

  Widget _buildNoGapsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No gaps detected today!\nLoad your timetable first.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white38),
      ),
    );
  }

  Widget _buildGapCard(FreeGap gap) {
    final color = _getGapColor(gap.quality);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(_getGapIcon(gap.quality),
                      color: color, size: 24),
                  const SizedBox(width: 10),
                  Text(
                    '${gap.startTime} - ${gap.endTime}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(gap.durationText,
                    style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(gap.qualityLabel,
              style: const TextStyle(
                  color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 4),
          Text('💡 ${gap.suggestedTasks.first}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(TaskRecommendation rec) {
    final priorityColors = {
      'high': Colors.redAccent,
      'medium': Colors.orangeAccent,
      'low': Colors.greenAccent,
    };
    final color = priorityColors[rec.priority] ?? Colors.white38;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.priorityEmoji,
              style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 4),
                Text(rec.reason,
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 11)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(rec.category,
                          style: TextStyle(
                              color: color,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 8),
                    Text('⏱ ${rec.estimatedMinutes} mins',
                        style: const TextStyle(
                            color: Colors.white38, fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableSkillsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: const Color(0xFF6C63FF).withOpacity(0.3)),
      ),
      child: Column(
        children: _availableSkills.take(3).map((skill) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                const Icon(Icons.play_circle,
                    color: Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skill['title'],
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                      Text(skill['category'] ?? '',
                          style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(skill['duration'],
                      style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 11)),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}