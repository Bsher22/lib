// lib/models/assessment_config.dart

class AssessmentTemplate {
  final String id;
  final String title;
  final String description;
  final String category; // 'comprehensive', 'focused', 'quick', 'mini'
  final int estimatedDurationMinutes;
  final int totalShots; // For shot assessments
  final int totalTests; // For skating assessments
  final List<AssessmentGroup> groups;
  final Map<String, dynamic> metadata;
  final DateTime? lastModified;
  final String version;
  final String type; // 'shot' or 'skating'

  AssessmentTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.estimatedDurationMinutes,
    this.totalShots = 0,
    this.totalTests = 0,
    required this.groups,
    this.metadata = const {},
    this.lastModified,
    this.version = '1.0.0',
    required this.type,
  });

  factory AssessmentTemplate.fromJson(Map<String, dynamic> json, String assessmentType) {
    final groups = (json['groups'] as List<dynamic>)
        .map((g) => AssessmentGroup.fromJson(g as Map<String, dynamic>, assessmentType))
        .toList();
    
    // Calculate totals if not provided
    int calculatedShots = 0;
    int calculatedTests = 0;
    
    if (assessmentType == 'shot') {
      calculatedShots = groups.fold(0, (sum, group) => sum + (group.shots ?? 0));
    } else {
      calculatedTests = groups.fold(0, (sum, group) => sum + (group.tests?.length ?? 0));
    }
    
    return AssessmentTemplate(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'comprehensive',
      estimatedDurationMinutes: json['estimatedDurationMinutes'] as int? ?? 15,
      totalShots: json['totalShots'] as int? ?? calculatedShots,
      totalTests: json['totalTests'] as int? ?? calculatedTests,
      groups: groups,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      lastModified: json['lastModified'] != null 
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      version: json['version'] as String? ?? '1.0.0',
      type: assessmentType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'estimatedDurationMinutes': estimatedDurationMinutes,
      if (type == 'shot') 'totalShots': totalShots,
      if (type == 'skating') 'totalTests': totalTests,
      'groups': groups.map((g) => g.toJson()).toList(),
      'metadata': metadata,
      'lastModified': lastModified?.toIso8601String(),
      'version': version,
      'type': type,
    };
  }

  String get displayTitle => '$title ($estimatedDurationMinutes min)';
  String get displayDescription {
    if (type == 'shot') {
      return '$description ($totalShots shots)';
    } else {
      return '$description ($totalTests tests)';
    }
  }
  
  // Helper methods
  bool get isComprehensive => category == 'comprehensive';
  bool get isQuick => category == 'quick';
  bool get isFocused => category == 'focused';
  bool get isMini => category == 'mini';
  bool get isShotAssessment => type == 'shot';
  bool get isSkatingAssessment => type == 'skating';
  
  String get difficultyLevel => metadata['difficulty'] as String? ?? 'intermediate';
  String get focusArea => metadata['focus'] as String? ?? 'general';
  
  List<String> get recommendedFor {
    final recommendations = metadata['recommendedFor'];
    if (recommendations is List) {
      return recommendations.map((r) => r.toString()).toList();
    }
    return [];
  }
}

class AssessmentGroup {
  final String id;
  final String title;
  final String name; // Alternative to title for skating assessments
  final String description;
  
  // Shot assessment specific
  final int? shots;
  final String? defaultType;
  final String? location;
  final String? instructions;
  final List<String> allowedShotTypes;
  final List<String> targetZones;
  final Map<String, dynamic> parameters;
  
  // Skating assessment specific
  final List<AssessmentTest>? tests;

  AssessmentGroup({
    required this.id,
    this.title = '',
    this.name = '',
    this.description = '',
    this.shots,
    this.defaultType,
    this.location,
    this.instructions,
    this.allowedShotTypes = const [],
    this.targetZones = const [],
    this.parameters = const {},
    this.tests,
  });

  factory AssessmentGroup.fromJson(Map<String, dynamic> json, String assessmentType) {
    if (assessmentType == 'skating') {
      return AssessmentGroup(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        title: json['title'] as String? ?? json['name'] as String? ?? '',
        description: json['description'] as String? ?? '',
        tests: json['tests'] != null 
            ? (json['tests'] as List<dynamic>)
                .map((t) => AssessmentTest.fromJson(t as Map<String, dynamic>))
                .toList()
            : null,
      );
    } else {
      // Shot assessment
      return AssessmentGroup(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        name: json['name'] as String? ?? json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        shots: json['shots'] as int?,
        defaultType: json['defaultType'] as String?,
        location: json['location'] as String?,
        instructions: json['instructions'] as String?,
        allowedShotTypes: json['allowedShotTypes'] != null
            ? List<String>.from(json['allowedShotTypes'])
            : [],
        targetZones: json['targetZones'] != null
            ? List<String>.from(json['targetZones'])
            : [],
        parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      );
    }
  }

  Map<String, dynamic> toJson() {
    if (tests != null) {
      // Skating assessment
      return {
        'id': id,
        'name': name.isNotEmpty ? name : title,
        'description': description,
        'tests': tests!.map((t) => t.toJson()).toList(),
      };
    } else {
      // Shot assessment
      return {
        'id': id,
        'title': title.isNotEmpty ? title : name,
        'description': description,
        'shots': shots,
        'defaultType': defaultType,
        'location': location,
        'instructions': instructions,
        'allowedShotTypes': allowedShotTypes,
        'targetZones': targetZones,
        'parameters': parameters,
      };
    }
  }
  
  String get displayName => name.isNotEmpty ? name : title;
}

class AssessmentTest {
  final String id;
  final String title;
  final String description;
  final String category;
  final String instructions;
  final Map<String, double> benchmarks;
  final List<String> equipment;
  final int duration; // in seconds

  AssessmentTest({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.instructions,
    this.benchmarks = const {},
    this.equipment = const [],
    this.duration = 60,
  });

  factory AssessmentTest.fromJson(Map<String, dynamic> json) {
    return AssessmentTest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'General',
      instructions: json['instructions'] as String? ?? '',
      benchmarks: json['benchmarks'] != null 
          ? Map<String, double>.from(json['benchmarks']) 
          : {},
      equipment: json['equipment'] != null
          ? List<String>.from(json['equipment'])
          : [],
      duration: json['duration'] as int? ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'instructions': instructions,
      'benchmarks': benchmarks,
      'equipment': equipment,
      'duration': duration,
    };
  }

  // Helper methods
  bool get hasBenchmarks => benchmarks.isNotEmpty;
  
  String get formattedDuration {
    if (duration < 60) return '${duration}s';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    if (seconds == 0) return '${minutes}m';
    return '${minutes}m ${seconds}s';
  }
  
  double? getBenchmark(String level) => benchmarks[level];
  List<String> get benchmarkLevels => benchmarks.keys.toList();
}

class AssessmentConfiguration {
  final List<AssessmentTemplate> templates;
  final Map<String, dynamic> globalSettings;
  final String configVersion;
  final DateTime lastUpdated;
  final String type; // 'shot' or 'skating'

  AssessmentConfiguration({
    required this.templates,
    this.globalSettings = const {},
    required this.configVersion,
    required this.lastUpdated,
    required this.type,
  });

  factory AssessmentConfiguration.fromJson(Map<String, dynamic> json, String assessmentType) {
    return AssessmentConfiguration(
      templates: (json['templates'] as List<dynamic>)
          .map((t) => AssessmentTemplate.fromJson(t as Map<String, dynamic>, assessmentType))
          .toList(),
      globalSettings: json['globalSettings'] as Map<String, dynamic>? ?? {},
      configVersion: json['configVersion'] as String,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      type: assessmentType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'templates': templates.map((t) => t.toJson()).toList(),
      'globalSettings': globalSettings,
      'configVersion': configVersion,
      'lastUpdated': lastUpdated.toIso8601String(),
      'type': type,
    };
  }

  AssessmentTemplate? getTemplate(String id) {
    try {
      return templates.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<AssessmentTemplate> getTemplatesByCategory(String category) {
    return templates.where((t) => t.category == category).toList();
  }

  Map<String, List<AssessmentTemplate>> getTemplatesGroupedByCategory() {
    final Map<String, List<AssessmentTemplate>> grouped = {};
    for (final template in templates) {
      grouped.putIfAbsent(template.category, () => []).add(template);
    }
    return grouped;
  }

  // Helper methods for getting available options
  List<String> get availableCategories {
    return templates.map((t) => t.category).toSet().toList();
  }
  
  List<String> get availableTestCategories {
    final categories = <String>{};
    for (final template in templates) {
      for (final group in template.groups) {
        if (group.tests != null) {
          for (final test in group.tests!) {
            categories.add(test.category);
          }
        }
      }
    }
    return categories.toList();
  }
  
  int get maxTestsPerGroup => globalSettings['maxTestsPerGroup'] as int? ?? 10;
  int get maxGroupsPerAssessment => globalSettings['maxGroupsPerAssessment'] as int? ?? 5;
  int get estimatedTimePerTest => globalSettings['estimatedTimePerTest'] as int? ?? 60;
  
  List<String> get defaultCategories {
    final categories = globalSettings['defaultCategories'];
    if (categories is List) {
      return categories.map((c) => c.toString()).toList();
    }
    if (type == 'skating') {
      return ['Speed', 'Agility', 'Technique'];
    } else {
      return ['Accuracy', 'Power', 'Quick Release'];
    }
  }
  
  List<String> get ageGroups {
    final groups = globalSettings['ageGroups'];
    if (groups is List) {
      return groups.map((g) => g.toString()).toList();
    }
    return ['youth_8_10', 'youth_11_14', 'youth_15_18', 'adult'];
  }
}