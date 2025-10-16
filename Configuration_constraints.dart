
class TimetableConfig {
  final List<String> workingDays;
  final int periodsPerDay;
  final int maxConsecutivePeriodsPerTeacher;
  final int maxPeriodsPerDayPerTeacher;
  final bool allowDoublePeriodsForSameSubject;
  final List<int> breakPeriods; 
  
  TimetableConfig({
    this.workingDays = const ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
    this.periodsPerDay = 8,
    this.maxConsecutivePeriodsPerTeacher = 4,
    this.maxPeriodsPerDayPerTeacher = 6,
    this.allowDoublePeriodsForSameSubject = true,
    this.breakPeriods = const [],
  });

  TimetableConfig copyWith({
    List<String>? workingDays,
    int? periodsPerDay,
    int? maxConsecutivePeriodsPerTeacher,
    int? maxPeriodsPerDayPerTeacher,
    bool? allowDoublePeriodsForSameSubject,
    List<int>? breakPeriods,
  }) {
    return TimetableConfig(
      workingDays: workingDays ?? this.workingDays,
      periodsPerDay: periodsPerDay ?? this.periodsPerDay,
      maxConsecutivePeriodsPerTeacher: maxConsecutivePeriodsPerTeacher ?? this.maxConsecutivePeriodsPerTeacher,
      maxPeriodsPerDayPerTeacher: maxPeriodsPerDayPerTeacher ?? this.maxPeriodsPerDayPerTeacher,
      allowDoublePeriodsForSameSubject: allowDoublePeriodsForSameSubject ?? this.allowDoublePeriodsForSameSubject,
      breakPeriods: breakPeriods ?? this.breakPeriods,
    );
  }
}

import '../models/teacher.dart';
import '../models/class_model.dart';
import '../models/timetable.dart';
import '../models/time_slot.dart';
import '../models/timetable_config.dart';

class ConstraintChecker {
  final TimetableConfig config;
  final List<Teacher> teachers;
  final List<ClassModel> classes;
  final Map<String, Timetable> timetables; 

  ConstraintChecker({
    required this.config,
    required this.teachers,
    required this.classes,
    required this.timetables,
  });

  bool canAssignSlot({
    required String classId,
    required String day,
    required int period,
    required String teacherId,
    required String subjectId,
  }) {
    if (config.breakPeriods.contains(period)) {
      return false;
    }

    final teacher = teachers.firstWhere((t) => t.id == teacherId);
    if (teacher.unavailableSlots[day]?.contains(period) ?? false) {
      return false;
    }

    if (timetables[classId]?.getSlot(day, period) != null) {
      return false;
    }

    if (isTeacherBusy(teacherId, day, period, excludeClassId: classId)) {
      return false;
    }

    if (!checkTeacherDailyLoad(teacherId, day, period)) {
      return false;
    }

    if (!checkConsecutivePeriods(teacherId, day, period)) {
      return false;
    }

    return true;
  }

  bool isTeacherBusy(String teacherId, String day, int period, {String? excludeClassId}) {
    for (var entry in timetables.entries) {
      if (entry.key == excludeClassId) continue;
      
      final slot = entry.value.getSlot(day, period);
      if (slot?.teacherId == teacherId) {
        return true;
      }
    }
    return false;
  }

  bool checkTeacherDailyLoad(String teacherId, String day, int period) {
    int periodsCount = 0;
    
    for (var timetable in timetables.values) {
      for (var p = 1; p <= config.periodsPerDay; p++) {
        final slot = timetable.getSlot(day, p);
        if (slot?.teacherId == teacherId) {
          periodsCount++;
        }
      }
    }

    return periodsCount < config.maxPeriodsPerDayPerTeacher;
  }

  bool checkConsecutivePeriods(String teacherId, String day, int period) {
    int consecutiveCount = 1;

    // Check backwards
    for (int p = period - 1; p >= 1; p--) {
      if (config.breakPeriods.contains(p)) break;
      
      bool foundTeacher = false;
      for (var timetable in timetables.values) {
        final slot = timetable.getSlot(day, p);
        if (slot?.teacherId == teacherId) {
          consecutiveCount++;
          foundTeacher = true;
          break;
        }
      }
      if (!foundTeacher) break;
    }

    for (int p = period + 1; p <= config.periodsPerDay; p++) {
      if (config.breakPeriods.contains(p)) break;
      
      bool foundTeacher = false;
      for (var timetable in timetables.values) {
        final slot = timetable.getSlot(day, p);
        if (slot?.teacherId == teacherId) {
          consecutiveCount++;
          foundTeacher = true;
          break;
        }
      }
      if (!foundTeacher) break;
    }

    return consecutiveCount <= config.maxConsecutivePeriodsPerTeacher;
  }

  int getSubjectPeriodsAssigned(String classId, String subjectId) {
    int count = 0;
    final timetable = timetables[classId];
    if (timetable == null) return 0;

    for (var day in config.workingDays) {
      for (var period = 1; period <= config.periodsPerDay; period++) {
        final slot = timetable.getSlot(day, period);
        if (slot?.subjectId == subjectId) {
          count++;
        }
      }
    }

    return count;
  }
}
