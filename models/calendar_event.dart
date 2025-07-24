// lib/models/calendar_event.dart
import 'dart:convert';

enum EventType {
  workout,
  assessment,
  practice,
  game,
  custom
}

enum RecurrenceType {
  none,
  daily,
  weekly,
  monthly
}

enum AssessmentType {
  shooting,
  skating,
  combined
}

class CalendarEvent {
  final int? id;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final EventType eventType;
  final int? createdById;
  final String? createdByName;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Optional fields based on event type
  final int? trainingProgramId;
  final String? trainingProgramName;
  final int? playerId;
  final String? playerName;
  final int? teamId;
  final String? teamName;
  final int? coachId;
  final String? coachName;
  final AssessmentType? assessmentType;
  
  // Recurrence
  final RecurrenceType recurrenceType;
  final int? recurrenceInterval;
  final DateTime? recurrenceEndDate;
  final int? parentEventId;
  
  // Additional metadata
  final String? location;
  final String? notes;
  final bool isCompleted;
  final List<String> participantIds;
  final Map<String, dynamic>? metadata;

  const CalendarEvent({
    this.id,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    required this.eventType,
    this.createdById,
    this.createdByName,
    required this.createdAt,
    required this.updatedAt,
    this.trainingProgramId,
    this.trainingProgramName,
    this.playerId,
    this.playerName,
    this.teamId,
    this.teamName,
    this.coachId,
    this.coachName,
    this.assessmentType,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.parentEventId,
    this.location,
    this.notes,
    this.isCompleted = false,
    this.participantIds = const [],
    this.metadata,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    return CalendarEvent(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      eventType: EventType.values.firstWhere(
        (e) => e.toString().split('.').last == json['event_type'],
        orElse: () => EventType.custom,
      ),
      createdById: json['created_by_id'],
      createdByName: json['created_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      trainingProgramId: json['training_program_id'],
      trainingProgramName: json['training_program_name'],
      playerId: json['player_id'],
      playerName: json['player_name'],
      teamId: json['team_id'],
      teamName: json['team_name'],
      coachId: json['coach_id'],
      coachName: json['coach_name'],
      assessmentType: json['assessment_type'] != null
          ? AssessmentType.values.firstWhere(
              (e) => e.toString().split('.').last == json['assessment_type'],
              orElse: () => AssessmentType.shooting,
            )
          : null,
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString().split('.').last == (json['recurrence_type'] ?? 'none'),
        orElse: () => RecurrenceType.none,
      ),
      recurrenceInterval: json['recurrence_interval'],
      recurrenceEndDate: json['recurrence_end_date'] != null
          ? DateTime.parse(json['recurrence_end_date'])
          : null,
      parentEventId: json['parent_event_id'],
      location: json['location'],
      notes: json['notes'],
      isCompleted: json['is_completed'] ?? false,
      participantIds: json['participant_ids'] != null
          ? List<String>.from(json['participant_ids'])
          : [],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'event_type': eventType.toString().split('.').last,
      'created_by_id': createdById,
      'created_by_name': createdByName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'training_program_id': trainingProgramId,
      'training_program_name': trainingProgramName,
      'player_id': playerId,
      'player_name': playerName,
      'team_id': teamId,
      'team_name': teamName,
      'coach_id': coachId,
      'coach_name': coachName,
      'assessment_type': assessmentType?.toString().split('.').last,
      'recurrence_type': recurrenceType.toString().split('.').last,
      'recurrence_interval': recurrenceInterval,
      'recurrence_end_date': recurrenceEndDate?.toIso8601String(),
      'parent_event_id': parentEventId,
      'location': location,
      'notes': notes,
      'is_completed': isCompleted,
      'participant_ids': participantIds,
      'metadata': metadata,
    };
  }

  CalendarEvent copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    EventType? eventType,
    int? createdById,
    String? createdByName,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? trainingProgramId,
    String? trainingProgramName,
    int? playerId,
    String? playerName,
    int? teamId,
    String? teamName,
    int? coachId,
    String? coachName,
    AssessmentType? assessmentType,
    RecurrenceType? recurrenceType,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    int? parentEventId,
    String? location,
    String? notes,
    bool? isCompleted,
    List<String>? participantIds,
    Map<String, dynamic>? metadata,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      eventType: eventType ?? this.eventType,
      createdById: createdById ?? this.createdById,
      createdByName: createdByName ?? this.createdByName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      trainingProgramId: trainingProgramId ?? this.trainingProgramId,
      trainingProgramName: trainingProgramName ?? this.trainingProgramName,
      playerId: playerId ?? this.playerId,
      playerName: playerName ?? this.playerName,
      teamId: teamId ?? this.teamId,
      teamName: teamName ?? this.teamName,
      coachId: coachId ?? this.coachId,
      coachName: coachName ?? this.coachName,
      assessmentType: assessmentType ?? this.assessmentType,
      recurrenceType: recurrenceType ?? this.recurrenceType,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentEventId: parentEventId ?? this.parentEventId,
      location: location ?? this.location,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      participantIds: participantIds ?? this.participantIds,
      metadata: metadata ?? this.metadata,
    );
  }

  String get eventTypeDisplayName {
    switch (eventType) {
      case EventType.workout:
        return 'Workout';
      case EventType.assessment:
        return 'Assessment';
      case EventType.practice:
        return 'Practice';
      case EventType.game:
        return 'Game';
      case EventType.custom:
        return 'Event';
    }
  }

  String get assessmentTypeDisplayName {
    switch (assessmentType) {
      case AssessmentType.shooting:
        return 'Shooting Assessment';
      case AssessmentType.skating:
        return 'Skating Assessment';
      case AssessmentType.combined:
        return 'Combined Assessment';
      case null:
        return '';
    }
  }

  Duration get duration => endTime.difference(startTime);

  bool get isRecurring => recurrenceType != RecurrenceType.none;

  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(startTime.year, startTime.month, startTime.day);
    return eventDate == today;
  }

  bool get isPast => endTime.isBefore(DateTime.now());

  bool get isUpcoming => startTime.isAfter(DateTime.now());

  bool get isActive {
    final now = DateTime.now();
    return startTime.isBefore(now) && endTime.isAfter(now);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CalendarEvent{id: $id, title: $title, startTime: $startTime, eventType: $eventType}';
  }
}