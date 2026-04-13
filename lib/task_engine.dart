class TaskRecommendation {
  final String title;
  final String category;
  final int estimatedMinutes;
  final String priority;
  final String reason;
  final String resource;

  TaskRecommendation({
    required this.title,
    required this.category,
    required this.estimatedMinutes,
    required this.priority,
    required this.reason,
    required this.resource,
  });

  String get priorityEmoji {
    switch (priority) {
      case 'high': return '🔴';
      case 'medium': return '🟡';
      case 'low': return '🟢';
      default: return '⚪';
    }
  }
}

class TaskEngine {
  // Match tasks to gap duration
  static List<TaskRecommendation> getRecommendations({
    required int gapMinutes,
    required List<Map<String, dynamic>> availableSkills,
    required List<Map<String, dynamic>> allSubjects,
    required double overallAttendance,
  }) {
    List<TaskRecommendation> recommendations = [];

    // High priority — attendance warning
    final dangerSubjects = allSubjects
        .where((s) => _getAttendance(s) < 75)
        .toList();

    if (dangerSubjects.isNotEmpty && gapMinutes >= 30) {
      for (final sub in dangerSubjects) {
        recommendations.add(TaskRecommendation(
          title: 'Revise ${sub['subject']} — Attendance Critical!',
          category: 'Academic',
          estimatedMinutes: 30,
          priority: 'high',
          reason: 'Attendance below 75% — needs attention!',
          resource: 'College notes, textbook',
        ));
      }
    }

    // Available skills from roadmap
    if (availableSkills.isNotEmpty) {
      for (final skill in availableSkills.take(3)) {
        final duration = _parseDuration(skill['duration'] ?? '1 day');
        if (gapMinutes >= 30) {
          recommendations.add(TaskRecommendation(
            title: skill['title'],
            category: skill['category'] ?? 'Skill',
            estimatedMinutes: duration.clamp(30, gapMinutes),
            priority: 'medium',
            reason: 'Available in your roadmap — prerequisites met!',
            resource: skill['resources'] ?? 'Online resources',
          ));
        }
      }
    }

    // Gap specific tasks
    if (gapMinutes >= 120) {
      recommendations.addAll([
        TaskRecommendation(
          title: 'LeetCode Practice Session',
          category: 'DSA',
          estimatedMinutes: 90,
          priority: 'medium',
          reason: 'Long gap — perfect for deep coding practice!',
          resource: 'leetcode.com',
        ),
        TaskRecommendation(
          title: 'Build a mini Flutter feature',
          category: 'Flutter',
          estimatedMinutes: 120,
          priority: 'medium',
          reason: 'Long gap — great for hands-on project work!',
          resource: 'flutter.dev',
        ),
      ]);
    } else if (gapMinutes >= 60) {
      recommendations.addAll([
        TaskRecommendation(
          title: 'Solve 5 DSA problems',
          category: 'DSA',
          estimatedMinutes: 60,
          priority: 'medium',
          reason: 'Good gap for focused practice!',
          resource: 'leetcode.com / GFG',
        ),
        TaskRecommendation(
          title: 'Watch one ML lecture',
          category: 'ML',
          estimatedMinutes: 45,
          priority: 'low',
          reason: 'Perfect duration for a video lecture',
          resource: 'Coursera / YouTube',
        ),
      ]);
    } else if (gapMinutes >= 30) {
      recommendations.addAll([
        TaskRecommendation(
          title: 'Quick concept revision',
          category: 'Academic',
          estimatedMinutes: 30,
          priority: 'low',
          reason: 'Short gap — best for revision',
          resource: 'Your notes',
        ),
        TaskRecommendation(
          title: 'Solve 2 easy LeetCode problems',
          category: 'DSA',
          estimatedMinutes: 30,
          priority: 'low',
          reason: 'Short focused practice',
          resource: 'leetcode.com',
        ),
      ]);
    } else {
      recommendations.add(TaskRecommendation(
        title: 'Quick flashcard review',
        category: 'Academic',
        estimatedMinutes: 15,
        priority: 'low',
        reason: 'Short gap — just review key points',
        resource: 'Your notes',
      ));
    }

    // Sort by priority
    recommendations.sort((a, b) {
      final order = {'high': 0, 'medium': 1, 'low': 2};
      return (order[a.priority] ?? 2).compareTo(order[b.priority] ?? 2);
    });

    return recommendations;
  }

  static double _getAttendance(Map s) {
    final total = (s['totalClasses'] ?? 0) as int;
    final attended = (s['attendedClasses'] ?? 0) as int;
    if (total == 0) return 100.0;
    return (attended / total) * 100;
  }

  static int _parseDuration(String duration) {
    try {
      final parts = duration.split(' ');
      final num = int.parse(parts[0]);
      if (duration.contains('day')) return num * 60;
      if (duration.contains('hour')) return num * 60;
      return num;
    } catch (e) {
      return 60;
    }
  }

  static String getMotivationalMessage(int totalFreeMinutes, int completedSkills) {
    if (completedSkills >= 10) return "You're crushing it! 🔥 Keep going!";
    if (totalFreeMinutes >= 180) return "Productive day ahead! 💪 Make it count!";
    if (totalFreeMinutes >= 90) return "Good gaps today! 📚 Use them wisely!";
    if (totalFreeMinutes >= 30) return "Short gaps available ⚡ Quick wins!";
    return "Busy day! 😤 Rest well and prep for tomorrow!";
  }

  static String getAttendanceAdvice(double percent) {
    if (percent >= 90) return "Excellent attendance! 🌟 Keep it up!";
    if (percent >= 85) return "Good attendance ✅ You're safe!";
    if (percent >= 75) return "Warning ⚠️ Don't miss more classes!";
    return "Danger! ❌ Attend classes immediately!";
  }
}