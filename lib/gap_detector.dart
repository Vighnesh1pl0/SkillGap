enum GapQuality { excellent, good, short, tooShort }

class TimeSlot {
  final String subject;
  final String day;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isCancelled;

  TimeSlot({
    required this.subject,
    required this.day,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isCancelled = false,
  });
}

class FreeGap {
  final String startTime;
  final String endTime;
  final int durationMinutes;
  final GapQuality quality;
  final List<String> suggestedTasks;

  FreeGap({
    required this.startTime,
    required this.endTime,
    required this.durationMinutes,
    required this.quality,
    required this.suggestedTasks,
  });

  String get durationText {
    if (durationMinutes >= 60) {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      if (minutes == 0) return '$hours hr${hours > 1 ? 's' : ''}';
      return '$hours hr $minutes mins';
    }
    return '$durationMinutes mins';
  }

  String get qualityLabel {
    switch (quality) {
      case GapQuality.excellent:
        return 'Excellent Gap 🔥';
      case GapQuality.good:
        return 'Good Gap ✅';
      case GapQuality.short:
        return 'Short Gap ⚡';
      case GapQuality.tooShort:
        return 'Too Short 😴';
    }
  }
}

class GapDetector {
  static const int collegeDayStart = 9 * 60;
  static const int collegeDayEnd = 17 * 60;

  static List<FreeGap> detectGaps(List<TimeSlot> slots) {
    if (slots.isEmpty) {
      return [
        FreeGap(
          startTime: '9:00 AM',
          endTime: '5:00 PM',
          durationMinutes: 480,
          quality: GapQuality.excellent,
          suggestedTasks: _getTasksForDuration(480),
        )
      ];
    }

    final activeSlots = slots.where((s) => !s.isCancelled).toList()
      ..sort((a, b) =>
          (a.startHour * 60 + a.startMinute)
              .compareTo(b.startHour * 60 + b.startMinute));

    if (activeSlots.isEmpty) {
      return [
        FreeGap(
          startTime: '9:00 AM',
          endTime: '5:00 PM',
          durationMinutes: 480,
          quality: GapQuality.excellent,
          suggestedTasks: _getTasksForDuration(480),
        )
      ];
    }

    List<FreeGap> gaps = [];

    final firstStart =
        activeSlots.first.startHour * 60 + activeSlots.first.startMinute;
    if (firstStart > collegeDayStart) {
      final duration = firstStart - collegeDayStart;
      gaps.add(FreeGap(
        startTime: _minutesToTime(collegeDayStart),
        endTime: _minutesToTime(firstStart),
        durationMinutes: duration,
        quality: _getQuality(duration),
        suggestedTasks: _getTasksForDuration(duration),
      ));
    }

    for (int i = 0; i < activeSlots.length - 1; i++) {
      final currentEnd =
          activeSlots[i].endHour * 60 + activeSlots[i].endMinute;
      final nextStart =
          activeSlots[i + 1].startHour * 60 + activeSlots[i + 1].startMinute;
      final duration = nextStart - currentEnd;

      if (duration >= 15) {
        gaps.add(FreeGap(
          startTime: _minutesToTime(currentEnd),
          endTime: _minutesToTime(nextStart),
          durationMinutes: duration,
          quality: _getQuality(duration),
          suggestedTasks: _getTasksForDuration(duration),
        ));
      }
    }

    final lastEnd =
        activeSlots.last.endHour * 60 + activeSlots.last.endMinute;
    if (lastEnd < collegeDayEnd) {
      final duration = collegeDayEnd - lastEnd;
      gaps.add(FreeGap(
        startTime: _minutesToTime(lastEnd),
        endTime: _minutesToTime(collegeDayEnd),
        durationMinutes: duration,
        quality: _getQuality(duration),
        suggestedTasks: _getTasksForDuration(duration),
      ));
    }

    return gaps;
  }

  static GapQuality _getQuality(int minutes) {
    if (minutes >= 90) return GapQuality.excellent;
    if (minutes >= 45) return GapQuality.good;
    if (minutes >= 20) return GapQuality.short;
    return GapQuality.tooShort;
  }

  static List<String> _getTasksForDuration(int minutes) {
    if (minutes >= 120) {
      return [
        'Complete a full DSA topic',
        'Work on project module',
        'Watch 2-3 lecture videos',
        'Practice coding problems',
      ];
    } else if (minutes >= 60) {
      return [
        'Solve 3-5 coding problems',
        'Watch 1-2 lecture videos',
        'Review notes from last class',
      ];
    } else if (minutes >= 30) {
      return [
        'Quick revision of formulas',
        'Solve 1-2 problems',
        'Read one topic summary',
      ];
    } else {
      return [
        'Quick 5-min revision',
        'Review key concepts',
        'Mental break & stretching',
      ];
    }
  }

  static String _minutesToTime(int minutes) {
    final hour = minutes ~/ 60;
    final minute = minutes % 60;
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour =
        hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  static String getDayRating(List<FreeGap> gaps) {
    final totalFreeMinutes =
        gaps.fold(0, (sum, gap) => sum + gap.durationMinutes);
    if (totalFreeMinutes >= 180) return 'Productive Day 🔥';
    if (totalFreeMinutes >= 90) return 'Decent Day ✅';
    if (totalFreeMinutes >= 30) return 'Busy Day ⚡';
    return 'Packed Day 😤';
  }
}