import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  late Box _roadmapBox;
  List<Map<String, dynamic>> _skills = [];
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'DSA', 'ML', 'Flutter', 'Maths'];

  final List<Map<String, dynamic>> _defaultSkills = [
    // DSA Track
    {
      'title': 'Arrays & Strings',
      'category': 'DSA',
      'status': 'completed',
      'duration': '3 days',
      'prerequisites': [],
      'description': 'Basic array operations, string manipulation',
      'resources': 'GFG, LeetCode Easy',
    },
    {
      'title': 'Linked Lists',
      'category': 'DSA',
      'status': 'completed',
      'duration': '3 days',
      'prerequisites': ['Arrays & Strings'],
      'description': 'Singly, doubly linked lists',
      'resources': 'GFG, Striver Sheet',
    },
    {
      'title': 'Stacks & Queues',
      'category': 'DSA',
      'status': 'available',
      'duration': '2 days',
      'prerequisites': ['Linked Lists'],
      'description': 'Stack, queue implementations',
      'resources': 'GFG, LeetCode Medium',
    },
    {
      'title': 'Trees & Graphs',
      'category': 'DSA',
      'status': 'locked',
      'duration': '5 days',
      'prerequisites': ['Stacks & Queues'],
      'description': 'Binary trees, BST, BFS, DFS',
      'resources': 'Striver Sheet, GFG',
    },
    {
      'title': 'Dynamic Programming',
      'category': 'DSA',
      'status': 'locked',
      'duration': '7 days',
      'prerequisites': ['Trees & Graphs'],
      'description': 'Memoization, tabulation',
      'resources': 'Aditya Verma DP Playlist',
    },

    // ML Track
    {
      'title': 'Python Basics',
      'category': 'ML',
      'status': 'completed',
      'duration': '2 days',
      'prerequisites': [],
      'description': 'Python for data science',
      'resources': 'Code with Harry',
    },
    {
      'title': 'Numpy & Pandas',
      'category': 'ML',
      'status': 'available',
      'duration': '3 days',
      'prerequisites': ['Python Basics'],
      'description': 'Data manipulation libraries',
      'resources': 'Kaggle Learn',
    },
    {
      'title': 'ML Algorithms',
      'category': 'ML',
      'status': 'locked',
      'duration': '5 days',
      'prerequisites': ['Numpy & Pandas'],
      'description': 'Linear regression, SVM, KNN',
      'resources': 'Coursera Andrew Ng',
    },
    {
      'title': 'Neural Networks',
      'category': 'ML',
      'status': 'locked',
      'duration': '5 days',
      'prerequisites': ['ML Algorithms'],
      'description': 'Deep learning basics',
      'resources': 'Fast.ai, deeplearning.ai',
    },

    // Flutter Track
    {
      'title': 'Dart Basics',
      'category': 'Flutter',
      'status': 'completed',
      'duration': '2 days',
      'prerequisites': [],
      'description': 'Dart language fundamentals',
      'resources': 'Flutter docs',
    },
    {
      'title': 'Flutter Widgets',
      'category': 'Flutter',
      'status': 'completed',
      'duration': '3 days',
      'prerequisites': ['Dart Basics'],
      'description': 'Stateless, stateful widgets',
      'resources': 'Flutter docs, YouTube',
    },
    {
      'title': 'State Management',
      'category': 'Flutter',
      'status': 'available',
      'duration': '4 days',
      'prerequisites': ['Flutter Widgets'],
      'description': 'Provider, Riverpod basics',
      'resources': 'Flutter docs',
    },
    {
      'title': 'Flutter + API',
      'category': 'Flutter',
      'status': 'locked',
      'duration': '3 days',
      'prerequisites': ['State Management'],
      'description': 'REST API integration',
      'resources': 'YouTube tutorials',
    },

    // Maths Track
    {
      'title': 'Linear Algebra',
      'category': 'Maths',
      'status': 'completed',
      'duration': '4 days',
      'prerequisites': [],
      'description': 'Matrices, vectors, eigenvalues',
      'resources': 'MIT OCW',
    },
    {
      'title': 'Probability & Stats',
      'category': 'Maths',
      'status': 'available',
      'duration': '4 days',
      'prerequisites': ['Linear Algebra'],
      'description': 'Distributions, hypothesis testing',
      'resources': 'Khan Academy',
    },
    {
      'title': 'Calculus for ML',
      'category': 'Maths',
      'status': 'locked',
      'duration': '3 days',
      'prerequisites': ['Probability & Stats'],
      'description': 'Gradients, backpropagation math',
      'resources': '3Blue1Brown',
    },
  ];

  @override
  void initState() {
    super.initState();
    _openBox();
  }

  Future<void> _openBox() async {
    _roadmapBox = await Hive.openBox('roadmap');
    if (_roadmapBox.isEmpty) {
      for (var skill in _defaultSkills) {
        await _roadmapBox.add(skill);
      }
    }
    _loadSkills();
  }

  void _loadSkills() {
    setState(() {
      _skills = _roadmapBox.values
          .map((s) => Map<String, dynamic>.from(s))
          .toList();
    });
  }

  bool _arePrerequisitesMet(Map<String, dynamic> skill) {
    final prereqs = List<String>.from(skill['prerequisites'] ?? []);
    if (prereqs.isEmpty) return true;
    for (final prereq in prereqs) {
      final found = _skills
          .any((s) => s['title'] == prereq && s['status'] == 'completed');
      if (!found) return false;
    }
    return true;
  }

  void _markComplete(Map<String, dynamic> skill) async {
    final keys = _roadmapBox.keys.toList();
    for (var key in keys) {
      final val = _roadmapBox.get(key);
      if (val != null && val['title'] == skill['title']) {
        await _roadmapBox.put(key, {
          ...Map<String, dynamic>.from(val),
          'status': 'completed',
        });
        break;
      }
    }
    _loadSkills();
    _unlockNextSkills();
  }

  void _unlockNextSkills() async {
    final keys = _roadmapBox.keys.toList();
    for (var key in keys) {
      final val = _roadmapBox.get(key);
      if (val != null && val['status'] == 'locked') {
        final skill = Map<String, dynamic>.from(val);
        if (_arePrerequisitesMet(skill)) {
          await _roadmapBox.put(key, {...skill, 'status': 'available'});
        }
      }
    }
    _loadSkills();
  }

  void _resetRoadmap() async {
    await _roadmapBox.clear();
    for (var skill in _defaultSkills) {
      await _roadmapBox.add(skill);
    }
    _loadSkills();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Roadmap reset to default!'),
        backgroundColor: Color(0xFF6C63FF),
      ),
    );
  }

  void _showSkillDetail(Map<String, dynamic> skill) {
    final status = skill['status'] as String;
    final isAvailable = status == 'available';
    final color = _getStatusColor(status);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(skill['title'],
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(skill['description'] ?? '',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 14)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Text('Duration: ${skill['duration']}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.book, color: Colors.white38, size: 16),
                const SizedBox(width: 6),
                Text('Resources: ${skill['resources'] ?? ""}',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 16),
            if (isAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    _markComplete(skill);
                  },
                  child: const Text('Mark as Complete ✅',
                      style:
                          TextStyle(color: Colors.white, fontSize: 15)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredSkills {
    if (_selectedCategory == 'All') return _skills;
    return _skills
        .where((s) => s['category'] == _selectedCategory)
        .toList();
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.greenAccent;
      case 'available':
        return const Color(0xFF6C63FF);
      case 'locked':
        return Colors.white24;
      default:
        return Colors.white24;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'available':
        return Icons.play_circle;
      case 'locked':
        return Icons.lock;
      default:
        return Icons.lock;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'DSA':
        return Colors.orangeAccent;
      case 'ML':
        return Colors.purpleAccent;
      case 'Flutter':
        return Colors.blueAccent;
      case 'Maths':
        return Colors.tealAccent;
      default:
        return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed =
        _skills.where((s) => s['status'] == 'completed').length;
    final available =
        _skills.where((s) => s['status'] == 'available').length;
    final locked = _skills.where((s) => s['status'] == 'locked').length;
    final total = _skills.length;
    final progress = total > 0 ? completed / total : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0F1A),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Skill Roadmap',
                style: TextStyle(
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
            Text('AIDS Branch Learning Path',
                style: TextStyle(color: Colors.white54, fontSize: 12)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF6C63FF)),
            onPressed: _resetRoadmap,
            tooltip: 'Reset Roadmap',
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress Card
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
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('$completed', 'Completed'),
                    Container(
                        width: 1, height: 40, color: Colors.white24),
                    _buildStat('$available', 'Available'),
                    Container(
                        width: 1, height: 40, color: Colors.white24),
                    _buildStat('$locked', 'Locked'),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Overall Progress',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 12)),
                        Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
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
                        value: progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent),
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Category Filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getCategoryColor(cat).withOpacity(0.3)
                          : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? _getCategoryColor(cat)
                            : Colors.white24,
                      ),
                    ),
                    child: Text(cat,
                        style: TextStyle(
                          color: isSelected
                              ? _getCategoryColor(cat)
                              : Colors.white54,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Skills List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredSkills.length,
              itemBuilder: (context, index) {
                final skill = _filteredSkills[index];
                final status = skill['status'] as String;
                final color = _getStatusColor(status);
                final isLocked = status == 'locked';
                final category = skill['category'] as String;
                final catColor = _getCategoryColor(category);

                return GestureDetector(
                  onTap: () => _showSkillDetail(skill),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Icon(_getStatusIcon(status),
                              color: color, size: 28),
                          if (index < _filteredSkills.length - 1)
                            Container(
                              width: 2,
                              height: 90,
                              color: color.withOpacity(0.3),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A2E),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: color.withOpacity(0.4)),
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      skill['title'],
                                      style: TextStyle(
                                        color: isLocked
                                            ? Colors.white38
                                            : Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3),
                                        decoration: BoxDecoration(
                                          color: catColor
                                              .withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(category,
                                            style: TextStyle(
                                                color: catColor,
                                                fontSize: 10,
                                                fontWeight:
                                                    FontWeight.w600)),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3),
                                        decoration: BoxDecoration(
                                          color:
                                              color.withOpacity(0.15),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          status[0].toUpperCase() +
                                              status.substring(1),
                                          style: TextStyle(
                                              color: color,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                skill['description'] ?? '',
                                style: TextStyle(
                                    color: isLocked
                                        ? Colors.white24
                                        : Colors.white54,
                                    fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '⏱ ${skill['duration']}',
                                    style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 11),
                                  ),
                                  if (!isLocked)
                                    const Text('Tap for details →',
                                        style: TextStyle(
                                            color: Color(0xFF6C63FF),
                                            fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                fontSize: 22,
                fontWeight: FontWeight.bold)),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}