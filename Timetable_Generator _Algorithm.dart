
import 'dart:math';
import '../models/teacher.dart';
import '../models/subject.dart';
import '../models/class_model.dart';
import '../models/timetable.dart';
import '../models/time_slot.dart';
import '../models/timetable_config.dart';
import 'constraint_checker.dart';

class TimetableGenerator {
  final TimetableConfig config;
  final List<Teacher> teachers;
  final List<Subject> subjects;
  final List<ClassModel> classes;
  final Random random = Random();

  TimetableGenerator({
    required this.config,
    required this.teachers,
    required this.subjects,
    required this.classes,
  });

  Future<Map<String, Timetable>> generate({
    int maxAttempts = 100,
    Function(String)? onProgress,
  }) async {
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      onProgress?.call('Attempt ${attempt + 1}/$maxAttempts');
      
      try {
        final result = await _generateAttempt();
        if (result != null) {
          onProgress?.call('Generation successful!');
          return result;
        }
      } catch (e) {
        
        continue;
      }
    }

    throw Exception('Failed to generate timetable after $maxAttempts attempts');
  }

  Future<Map<String, Timetable>?> _generateAttempt() async {
   
    final timetables = <String, Timetable>{};
    for (var classModel in classes) {
      timetables[classModel.id] = Timetable(
        classId: classModel.id,
        schedule: {},
      );
    }

    final checker = ConstraintChecker(
      config: config,
      teachers: teachers,
      classes: classes,
      timetables: timetables,
    );

    
    final assignments = <_Assignment>[];
    for (var classModel in classes) {
      for (var subjectId in classModel.subjectIds) {
        final subject = subjects.firstWhere((s) => s.id == subjectId);
        final eligibleTeachers = teachers
            .where((t) => t.subjectIds.contains(subjectId))
            .toList();
        
        if (eligibleTeachers.isEmpty) {
          throw Exception('No teacher found for subject ${subject.name}');
        }

        assignments.add(_Assignment(
          classId: classModel.id,
          subjectId: subjectId,
          periodsNeeded: subject.periodsPerWeek,
          eligibleTeachers: eligibleTeachers,
        ));
      }
    }

   
    assignments.sort((a, b) => a.periodsNeeded.compareTo(b.periodsNeeded));

    
    for (var assignment in assignments) {
      final success = _assignSubjectPeriods(
        assignment: assignment,
        timetables: timetables,
        checker: checker,
      );

      if (!success) {
        return null;
      }
    }

    return timetables;
  }

  bool _assignSubjectPeriods({
    required _Assignment assignment,
    required Map<String, Timetable> timetables,
    required ConstraintChecker checker,
  }) {
    final timetable = timetables[assignment.classId]!;
    int periodsAssigned = 0;

    
    final possibleSlots = <_Slot>[];
    for (var day in config.workingDays) {
      for (var period = 1; period <= config.periodsPerDay; period++) {
        if (!config.breakPeriods.contains(period)) {
          possibleSlots.add(_Slot(day: day, period: period));
        }
      }
    }

   
    possibleSlots.shuffle(random);

    for (var slot in possibleSlots) {
      if (periodsAssigned >= assignment.periodsNeeded) {
        break;
      }

      
      final shuffledTeachers = List<Teacher>.from(assignment.eligibleTeachers)
        ..shuffle(random);

      for (var teacher in shuffledTeachers) {
        if (checker.canAssignSlot(
          classId: assignment.classId,
          day: slot.day,
          period: slot.period,
          teacherId: teacher.id,
          subjectId: assignment.subjectId,
        )) {
         
          timetable.setSlot(
            slot.day,
            slot.period,
            TimeSlot(
              day: slot.day,
              period: slot.period,
              classId: assignment.classId,
              teacherId: teacher.id,
              subjectId: assignment.subjectId,
            ),
          );

          periodsAssigned++;
          break;
        }
      }
    }

    return periodsAssigned == assignment.periodsNeeded;
  }
}

class _Assignment {
  final String classId;
  final String subjectId;
  final int periodsNeeded;
  final List<Teacher> eligibleTeachers;

  _Assignment({
    required this.classId,
    required this.subjectId,
    required this.periodsNeeded,
    required this.eligibleTeachers,
  });
}

class _Slot {
  final String day;
  final int period;

  _Slot({required this.day, required this.period});
}
