
class Teacher {
  final String id;
  final String name;
  final List<String> subjectIds;
  final Map<String, List<int>> unavailableSlots; 

  Teacher({
    required this.id,
    required this.name,
    required this.subjectIds,
    this.unavailableSlots = const {},
  });

  Teacher copyWith({
    String? id,
    String? name,
    List<String>? subjectIds,
    Map<String, List<int>>? unavailableSlots,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectIds: subjectIds ?? this.subjectIds,
      unavailableSlots: unavailableSlots ?? this.unavailableSlots,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subjectIds': subjectIds,
      'unavailableSlots': unavailableSlots,
    };
  }

  factory Teacher.fromJson(Map<String, dynamic> json) {
    return Teacher(
      id: json['id'],
      name: json['name'],
      subjectIds: List<String>.from(json['subjectIds']),
      unavailableSlots: Map<String, List<int>>.from(
        (json['unavailableSlots'] as Map).map(
          (key, value) => MapEntry(key, List<int>.from(value)),
        ),
      ),
    );
  }
}


class Subject {
  final String id;
  final String name;
  final String code;
  final int periodsPerWeek;

  Subject({
    required this.id,
    required this.name,
    required this.code,
    required this.periodsPerWeek,
  });

  Subject copyWith({
    String? id,
    String? name,
    String? code,
    int? periodsPerWeek,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      periodsPerWeek: periodsPerWeek ?? this.periodsPerWeek,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'periodsPerWeek': periodsPerWeek,
    };
  }

  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'],
      name: json['name'],
      code: json['code'],
      periodsPerWeek: json['periodsPerWeek'],
    );
  }
}

class ClassModel {
  final String id;
  final String name;
  final List<String> subjectIds;

  ClassModel({
    required this.id,
    required this.name,
    required this.subjectIds,
  });

  ClassModel copyWith({
    String? id,
    String? name,
    List<String>? subjectIds,
  }) {
    return ClassModel(
      id: id ?? this.id,
      name: name ?? this.name,
      subjectIds: subjectIds ?? this.subjectIds,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'subjectIds': subjectIds,
    };
  }

  factory ClassModel.fromJson(Map<String, dynamic> json) {
    return ClassModel(
      id: json['id'],
      name: json['name'],
      subjectIds: List<String>.from(json['subjectIds']),
    );
  }
}

class TimeSlot {
  final String day;
  final int period;
  final String? teacherId;
  final String? subjectId;
  final String? classId;

  TimeSlot({
    required this.day,
    required this.period,
    this.teacherId,
    this.subjectId,
    this.classId,
  });

  bool get isEmpty => teacherId == null && subjectId == null;

  TimeSlot copyWith({
    String? day,
    int? period,
    String? teacherId,
    String? subjectId,
    String? classId,
  }) {
    return TimeSlot(
      day: day ?? this.day,
      period: period ?? this.period,
      teacherId: teacherId ?? this.teacherId,
      subjectId: subjectId ?? this.subjectId,
      classId: classId ?? this.classId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': day,
      'period': period,
      'teacherId': teacherId,
      'subjectId': subjectId,
      'classId': classId,
    };
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      day: json['day'],
      period: json['period'],
      teacherId: json['teacherId'],
      subjectId: json['subjectId'],
      classId: json['classId'],
    );
  }
}

class Timetable {
  final String classId;
  final Map<String, Map<int, TimeSlot>> schedule; 

  Timetable({
    required this.classId,
    required this.schedule,
  });

  TimeSlot? getSlot(String day, int period) {
    return schedule[day]?[period];
  }

  void setSlot(String day, int period, TimeSlot slot) {
    if (!schedule.containsKey(day)) {
      schedule[day] = {};
    }
    schedule[day]![period] = slot;
  }

  Map<String, dynamic> toJson() {
    return {
      'classId': classId,
      'schedule': schedule.map(
        (day, periods) => MapEntry(
          day,
          periods.map(
            (period, slot) => MapEntry(period.toString(), slot.toJson()),
          ),
        ),
      ),
    };
  }

  factory Timetable.fromJson(Map<String, dynamic> json) {
    return Timetable(
      classId: json['classId'],
      schedule: (json['schedule'] as Map<String, dynamic>).map(
        (day, periods) => MapEntry(
          day,
          (periods as Map<String, dynamic>).map(
            (period, slot) => MapEntry(
              int.parse(period),
              TimeSlot.fromJson(slot),
            ),
          ),
        ),
      ),
    );
  }
}