// lib/models/development_plan.dart - Updated to match your existing database schema

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/utils/hockey_ratings_config.dart';
import 'dart:convert';

// ============================================================================
// CORE DATA MODELS - Updated to match your existing database structure
// ============================================================================

class DevelopmentPlan {
  final String id;
  final String playerId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> goals;
  final Map<String, dynamic> ratings;

  DevelopmentPlan({
    required this.id,
    required this.playerId,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.goals = const [],
    this.ratings = const {},
  });

  factory DevelopmentPlan.fromJson(Map<String, dynamic> json) {
    return DevelopmentPlan(
      id: json['id']?.toString() ?? '',
      playerId: json['player_id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      goals: List<String>.from(json['goals'] ?? []),
      ratings: Map<String, dynamic>.from(json['ratings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'player_id': playerId,
      'title': title,
      'description': description,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'goals': goals,
      'ratings': ratings,
    };
  }
}

class HIREScores {
  final double hockey;
  final double integrity;
  final double respect;
  final double excellence;
  final double overall;
  final DateTime calculatedAt;
  final Map<String, dynamic> details;

  HIREScores({
    this.hockey = 0.0,
    this.integrity = 0.0,
    this.respect = 0.0,
    this.excellence = 0.0,
    this.overall = 0.0,
    DateTime? calculatedAt,
    this.details = const {},
  }) : calculatedAt = calculatedAt ?? DateTime.now();

  factory HIREScores.fromJson(Map<String, dynamic> json) {
    return HIREScores(
      hockey: (json['hockey'] ?? json['h_score'] as num?)?.toDouble() ?? 0.0,
      integrity: (json['integrity'] ?? json['i_score'] as num?)?.toDouble() ?? 0.0,
      respect: (json['respect'] ?? json['r_score'] as num?)?.toDouble() ?? 0.0,
      excellence: (json['excellence'] ?? json['e_score'] as num?)?.toDouble() ?? 0.0,
      overall: (json['overall'] ?? json['overall_hire_score'] as num?)?.toDouble() ?? 0.0,
      calculatedAt: json['calculated_at'] != null 
          ? DateTime.parse(json['calculated_at'])
          : (json['scores_calculated_at'] != null 
              ? DateTime.parse(json['scores_calculated_at'])
              : DateTime.now()),
      details: Map<String, dynamic>.from(json['details'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hockey': hockey,
      'integrity': integrity,
      'respect': respect,
      'excellence': excellence,
      'overall': overall,
      'calculated_at': calculatedAt.toIso8601String(),
      'details': details,
    };
  }
}

class DevelopmentPlanData {
  final int id; // Changed to match your database (integer primary key)
  final int playerId;
  String playerName;
  int playerAge;
  String season;
  String assessmentType;
  String planName;
  DateTime assessmentDate; // Using your column name
  List<String> strengths;
  List<String> improvements;
  List<CoreTarget> coreTargets;
  Map<String, String> monthlyTargets;
  
  // Coach information (flattened in your database)
  String coachName;
  String coachEmail;
  String coachPhone;
  String coachNotes;
  String playerNotes;
  
  // Mentorship notes (your dedicated fields)
  String mentorshipNote1;
  String mentorshipNote2;
  String mentorshipNote3;
  
  HIREPlayerRatings ratings;
  DateTime createdAt;
  DateTime updatedAt;
  DateTime? scoresCalculatedAt;
  bool needsRecalculation;

  DevelopmentPlanData({
    this.id = 0, // 0 for new records
    required this.playerId,
    required this.playerName,
    required this.playerAge,
    this.season = '2024-25',
    this.assessmentType = 'regular',
    this.planName = 'Development Plan',
    DateTime? assessmentDate,
    required this.strengths,
    required this.improvements,
    required this.coreTargets,
    required this.monthlyTargets,
    this.coachName = '',
    this.coachEmail = '',
    this.coachPhone = '',
    this.coachNotes = '',
    this.playerNotes = '',
    this.mentorshipNote1 = '',
    this.mentorshipNote2 = '',
    this.mentorshipNote3 = '',
    required this.ratings,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.scoresCalculatedAt,
    this.needsRecalculation = true,
  }) : 
    assessmentDate = assessmentDate ?? DateTime.now(),
    createdAt = createdAt ?? DateTime.now(),
    updatedAt = updatedAt ?? DateTime.now();

  factory DevelopmentPlanData.fromJson(Map<String, dynamic> json) {
    return DevelopmentPlanData(
      id: json['id'] ?? 0,
      playerId: json['player_id'] ?? 0,
      playerName: json['player_name'] ?? '',
      playerAge: json['player_age'] ?? 16,
      season: json['season'] ?? '2024-25',
      assessmentType: json['assessment_type'] ?? 'regular',
      planName: json['plan_name'] ?? 'Development Plan',
      assessmentDate: DateTime.parse(json['assessment_date'] ?? DateTime.now().toIso8601String()),
      
      // Parse JSON arrays from your database
      strengths: _parseJsonArray(json['strengths']),
      improvements: _parseJsonArray(json['improvements']),
      coreTargets: _parseJsonCoreTargets(json['core_targets']),
      monthlyTargets: _parseJsonStringMap(json['monthly_targets']),
      
      // Coach information (flattened in your database)
      coachName: json['coach_name'] ?? '',
      coachEmail: json['coach_email'] ?? '',
      coachPhone: json['coach_phone'] ?? '',
      coachNotes: json['coach_notes'] ?? '',
      playerNotes: json['player_notes'] ?? '',
      
      // Mentorship notes
      mentorshipNote1: json['mentorship_note_1'] ?? '',
      mentorshipNote2: json['mentorship_note_2'] ?? '',
      mentorshipNote3: json['mentorship_note_3'] ?? '',
      
      // Create ratings from the flattened structure in your database
      ratings: HIREPlayerRatings.fromDatabaseRow(json),
      
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      scoresCalculatedAt: json['scores_calculated_at'] != null 
          ? DateTime.parse(json['scores_calculated_at']) 
          : null,
      needsRecalculation: json['needs_recalculation'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id, // Only include if updating
      'player_id': playerId,
      'player_name': playerName,
      'player_age': playerAge,
      'season': season,
      'assessment_type': assessmentType,
      'plan_name': planName,
      'assessment_date': assessmentDate.toIso8601String(),
      
      // Convert to JSON for storage
      'strengths': strengths,
      'improvements': improvements,
      'core_targets': coreTargets.map((e) => e.toJson()).toList(),
      'monthly_targets': monthlyTargets,
      
      // Coach information
      'coach_name': coachName,
      'coach_email': coachEmail,
      'coach_phone': coachPhone,
      'coach_notes': coachNotes,
      'player_notes': playerNotes,
      
      // Mentorship notes
      'mentorship_note_1': mentorshipNote1,
      'mentorship_note_2': mentorshipNote2,
      'mentorship_note_3': mentorshipNote3,
      
      // Include all rating values and HIRE scores
      ...ratings.toDatabaseMap(),
      
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'scores_calculated_at': scoresCalculatedAt?.toIso8601String(),
      'needs_recalculation': needsRecalculation,
    };
  }

  // Helper methods for JSON parsing
  static List<String> _parseJsonArray(dynamic json) {
    if (json == null) return [];
    if (json is String) {
      try {
        final decoded = jsonDecode(json);
        return List<String>.from(decoded);
      } catch (e) {
        return [];
      }
    }
    if (json is List) return List<String>.from(json);
    return [];
  }

  static List<CoreTarget> _parseJsonCoreTargets(dynamic json) {
    if (json == null) return [];
    try {
      final List<dynamic> list = json is String ? jsonDecode(json) : json;
      return list.map((e) => CoreTarget.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Map<String, String> _parseJsonStringMap(dynamic json) {
    if (json == null) return {};
    try {
      final Map<String, dynamic> map = json is String ? jsonDecode(json) : json;
      return map.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      return {};
    }
  }

  // Get development insights based on HIRE scores
  DevelopmentInsights getInsights() {
    return DevelopmentInsights.fromRatings(ratings, playerAge);
  }

  // Create a CoachContact object from the flattened fields
  CoachContact get coachContact => CoachContact(
    name: coachName,
    email: coachEmail,
    phone: coachPhone,
  );

  // Create a MeetingNotes object from the separate fields
  MeetingNotes get meetingNotes => MeetingNotes(
    coachNotes: coachNotes,
    playerNotes: playerNotes,
    mentorshipNote1: mentorshipNote1,
    mentorshipNote2: mentorshipNote2,
    mentorshipNote3: mentorshipNote3,
  );

  // Helper setters for updating from old structure
  set coachContact(CoachContact contact) {
    coachName = contact.name;
    coachEmail = contact.email;
    coachPhone = contact.phone;
  }

  set meetingNotes(MeetingNotes notes) {
    coachNotes = notes.coachNotes;
    playerNotes = notes.playerNotes;
    mentorshipNote1 = notes.mentorshipNote1;
    mentorshipNote2 = notes.mentorshipNote2;
    mentorshipNote3 = notes.mentorshipNote3;
  }
}

class CoreTarget {
  String skill;
  String timeframe;

  CoreTarget({required this.skill, required this.timeframe});

  factory CoreTarget.fromJson(Map<String, dynamic> json) {
    return CoreTarget(
      skill: json['skill'] ?? '',
      timeframe: json['timeframe'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'skill': skill,
      'timeframe': timeframe,
    };
  }
}

class MeetingNotes {
  String coachNotes;
  String playerNotes;
  String mentorshipNote1;
  String mentorshipNote2;
  String mentorshipNote3;

  MeetingNotes({
    required this.coachNotes, 
    required this.playerNotes,
    this.mentorshipNote1 = '',
    this.mentorshipNote2 = '',
    this.mentorshipNote3 = '',
  });

  factory MeetingNotes.fromJson(Map<String, dynamic> json) {
    return MeetingNotes(
      coachNotes: json['coach_notes'] ?? '',
      playerNotes: json['player_notes'] ?? '',
      mentorshipNote1: json['mentorship_note_1'] ?? '',
      mentorshipNote2: json['mentorship_note_2'] ?? '',
      mentorshipNote3: json['mentorship_note_3'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'coach_notes': coachNotes,
      'player_notes': playerNotes,
      'mentorship_note_1': mentorshipNote1,
      'mentorship_note_2': mentorshipNote2,
      'mentorship_note_3': mentorshipNote3,
    };
  }
}

class CoachContact {
  String name;
  String email;
  String phone;

  CoachContact({required this.name, required this.email, required this.phone});

  factory CoachContact.fromJson(Map<String, dynamic> json) {
    return CoachContact(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
}

// ============================================================================
// HIRE RATINGS - Updated to match your database column structure
// ============================================================================

class HIREPlayerRatings {
  // Core HIRE Ratings (calculated by backend)
  double hScore = 0.0;
  double iScore = 0.0;
  double rScore = 0.0;
  double eScore = 0.0;
  double overallHIREScore = 0.0;

  // Component scores (calculated by backend)
  double humilityScore = 0.0;
  double hardworkScore = 0.0;
  double initiativeScore = 0.0;
  double integrityScore = 0.0;
  double responsibilityScore = 0.0;
  double respectScore = 0.0;
  double enthusiasmScore = 0.0;

  // All your rating factors (matching your database columns exactly)
  double hockeyIQ = 5.0;
  double competitiveness = 5.0;
  double workEthic = 5.0;
  double coachability = 5.0;
  double leadership = 5.0;
  double teamPlay = 5.0;
  double decisionMaking = 5.0;
  double adaptability = 5.0;
  double mentalToughness = 5.0;
  double physicalFitness = 5.0;
  double nutritionHabits = 5.0;
  double sleepQuality = 5.0;
  double timeManagement = 5.0;
  double respectForOthers = 5.0;
  double commitment = 5.0;
  double goalSetting = 5.0;
  double communicationSkills = 5.0;
  
  // Youth Factors (8-12)
  double funEnjoyment = 5.0;
  double attentionSpan = 5.0;
  double followingInstructions = 5.0;
  double sharing = 5.0;
  double equipmentCare = 5.0;
  double parentSupport = 5.0;
  
  // Teen Factors (13-17)
  double academicPerformance = 5.0;
  double socialMediaHabits = 5.0;
  double peerInfluence = 5.0;
  double independence = 5.0;
  double substanceAwareness = 5.0;
  double conflictResolution = 5.0;
  
  // Adult Factors (18+)
  double professionalBalance = 5.0;
  double financialManagement = 5.0;
  double familyCommitments = 5.0;
  double careerPlanning = 5.0;
  double stressManagement = 5.0;
  double longTermVision = 5.0;

  HIREPlayerRatings();

  factory HIREPlayerRatings.defaultForAge(int age) {
    final ratings = HIREPlayerRatings();
    return ratings;
  }

  // Create from database row (matching your table structure)
  factory HIREPlayerRatings.fromDatabaseRow(Map<String, dynamic> row) {
    final ratings = HIREPlayerRatings();
    
    // Load calculated scores
    ratings.hScore = (row['h_score'] as num?)?.toDouble() ?? 0.0;
    ratings.iScore = (row['i_score'] as num?)?.toDouble() ?? 0.0;
    ratings.rScore = (row['r_score'] as num?)?.toDouble() ?? 0.0;
    ratings.eScore = (row['e_score'] as num?)?.toDouble() ?? 0.0;
    ratings.overallHIREScore = (row['overall_hire_score'] as num?)?.toDouble() ?? 0.0;
    
    // Load component scores
    ratings.humilityScore = (row['humility_score'] as num?)?.toDouble() ?? 0.0;
    ratings.hardworkScore = (row['hardwork_score'] as num?)?.toDouble() ?? 0.0;
    ratings.initiativeScore = (row['initiative_score'] as num?)?.toDouble() ?? 0.0;
    ratings.integrityScore = (row['integrity_score'] as num?)?.toDouble() ?? 0.0;
    ratings.responsibilityScore = (row['responsibility_score'] as num?)?.toDouble() ?? 0.0;
    ratings.respectScore = (row['respect_score'] as num?)?.toDouble() ?? 0.0;
    ratings.enthusiasmScore = (row['enthusiasm_score'] as num?)?.toDouble() ?? 0.0;
    
    // Load all rating factors (matching your database column names exactly)
    ratings.hockeyIQ = (row['hockey_iq'] as num?)?.toDouble() ?? 5.0;
    ratings.competitiveness = (row['competitiveness'] as num?)?.toDouble() ?? 5.0;
    ratings.workEthic = (row['work_ethic'] as num?)?.toDouble() ?? 5.0;
    ratings.coachability = (row['coachability'] as num?)?.toDouble() ?? 5.0;
    ratings.leadership = (row['leadership'] as num?)?.toDouble() ?? 5.0;
    ratings.teamPlay = (row['team_play'] as num?)?.toDouble() ?? 5.0;
    ratings.decisionMaking = (row['decision_making'] as num?)?.toDouble() ?? 5.0;
    ratings.adaptability = (row['adaptability'] as num?)?.toDouble() ?? 5.0;
    ratings.mentalToughness = (row['mental_toughness'] as num?)?.toDouble() ?? 5.0;
    ratings.physicalFitness = (row['physical_fitness'] as num?)?.toDouble() ?? 5.0;
    ratings.nutritionHabits = (row['nutrition_habits'] as num?)?.toDouble() ?? 5.0;
    ratings.sleepQuality = (row['sleep_quality'] as num?)?.toDouble() ?? 5.0;
    ratings.timeManagement = (row['time_management'] as num?)?.toDouble() ?? 5.0;
    ratings.respectForOthers = (row['respect_for_others'] as num?)?.toDouble() ?? 5.0;
    ratings.commitment = (row['commitment'] as num?)?.toDouble() ?? 5.0;
    ratings.goalSetting = (row['goal_setting'] as num?)?.toDouble() ?? 5.0;
    ratings.communicationSkills = (row['communication_skills'] as num?)?.toDouble() ?? 5.0;
    
    // Youth factors
    ratings.funEnjoyment = (row['fun_enjoyment'] as num?)?.toDouble() ?? 5.0;
    ratings.attentionSpan = (row['attention_span'] as num?)?.toDouble() ?? 5.0;
    ratings.followingInstructions = (row['following_instructions'] as num?)?.toDouble() ?? 5.0;
    ratings.sharing = (row['sharing'] as num?)?.toDouble() ?? 5.0;
    ratings.equipmentCare = (row['equipment_care'] as num?)?.toDouble() ?? 5.0;
    ratings.parentSupport = (row['parent_support'] as num?)?.toDouble() ?? 5.0;
    
    // Teen factors
    ratings.academicPerformance = (row['academic_performance'] as num?)?.toDouble() ?? 5.0;
    ratings.socialMediaHabits = (row['social_media_habits'] as num?)?.toDouble() ?? 5.0;
    ratings.peerInfluence = (row['peer_influence'] as num?)?.toDouble() ?? 5.0;
    ratings.independence = (row['independence'] as num?)?.toDouble() ?? 5.0;
    ratings.substanceAwareness = (row['substance_awareness'] as num?)?.toDouble() ?? 5.0;
    ratings.conflictResolution = (row['conflict_resolution'] as num?)?.toDouble() ?? 5.0;
    
    // Adult factors
    ratings.professionalBalance = (row['professional_balance'] as num?)?.toDouble() ?? 5.0;
    ratings.financialManagement = (row['financial_management'] as num?)?.toDouble() ?? 5.0;
    ratings.familyCommitments = (row['family_commitments'] as num?)?.toDouble() ?? 5.0;
    ratings.careerPlanning = (row['career_planning'] as num?)?.toDouble() ?? 5.0;
    ratings.stressManagement = (row['stress_management'] as num?)?.toDouble() ?? 5.0;
    ratings.longTermVision = (row['long_term_vision'] as num?)?.toDouble() ?? 5.0;
    
    return ratings;
  }

  // For backward compatibility with your existing fromJson
  factory HIREPlayerRatings.fromJson(Map<String, dynamic> json) {
    return HIREPlayerRatings.fromDatabaseRow(json);
  }

  // Convert to database map (matching your column names)
  Map<String, dynamic> toDatabaseMap() {
    return {
      // HIRE scores
      'h_score': hScore,
      'i_score': iScore,
      'r_score': rScore,
      'e_score': eScore,
      'overall_hire_score': overallHIREScore,
      
      // Component scores
      'humility_score': humilityScore,
      'hardwork_score': hardworkScore,
      'initiative_score': initiativeScore,
      'integrity_score': integrityScore,
      'responsibility_score': responsibilityScore,
      'respect_score': respectScore,
      'enthusiasm_score': enthusiasmScore,
      
      // All rating factors (using your database column names)
      'hockey_iq': hockeyIQ,
      'competitiveness': competitiveness,
      'work_ethic': workEthic,
      'coachability': coachability,
      'leadership': leadership,
      'team_play': teamPlay,
      'decision_making': decisionMaking,
      'adaptability': adaptability,
      'mental_toughness': mentalToughness,
      'physical_fitness': physicalFitness,
      'nutrition_habits': nutritionHabits,
      'sleep_quality': sleepQuality,
      'time_management': timeManagement,
      'respect_for_others': respectForOthers,
      'commitment': commitment,
      'goal_setting': goalSetting,
      'communication_skills': communicationSkills,
      
      // Youth factors
      'fun_enjoyment': funEnjoyment,
      'attention_span': attentionSpan,
      'following_instructions': followingInstructions,
      'sharing': sharing,
      'equipment_care': equipmentCare,
      'parent_support': parentSupport,
      
      // Teen factors
      'academic_performance': academicPerformance,
      'social_media_habits': socialMediaHabits,
      'peer_influence': peerInfluence,
      'independence': independence,
      'substance_awareness': substanceAwareness,
      'conflict_resolution': conflictResolution,
      
      // Adult factors
      'professional_balance': professionalBalance,
      'financial_management': financialManagement,
      'family_commitments': familyCommitments,
      'career_planning': careerPlanning,
      'stress_management': stressManagement,
      'long_term_vision': longTermVision,
    };
  }

  // For backward compatibility
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {
      // Calculated scores (from backend)
      'hScore': hScore,
      'iScore': iScore,
      'rScore': rScore,
      'eScore': eScore,
      'overallHIREScore': overallHIREScore,
      
      // Component scores (from backend)
      'humilityScore': humilityScore,
      'hardworkScore': hardworkScore,
      'initiativeScore': initiativeScore,
      'integrityScore': integrityScore,
      'responsibilityScore': responsibilityScore,
      'respectScore': respectScore,
      'enthusiasmScore': enthusiasmScore,
    };

    // Add all rating factors using your system's structure
    final allFactors = HockeyRatingsConfig.onIceFactors.factors +
                      HockeyRatingsConfig.offIceFactors.factors +
                      HockeyRatingsConfig.youthFactors.factors +
                      HockeyRatingsConfig.teenFactors.factors +
                      HockeyRatingsConfig.adultFactors.factors;

    for (final factor in allFactors) {
      result[factor.key] = getRatingValue(factor.key);
    }
    
    return result;
  }

  double getRatingValue(String key) {
    switch (key) {
      // On-ice factors
      case 'hockeyIQ': return hockeyIQ;
      case 'competitiveness': return competitiveness;
      case 'workEthic': return workEthic;
      case 'coachability': return coachability;
      case 'leadership': return leadership;
      case 'teamPlay': return teamPlay;
      case 'decisionMaking': return decisionMaking;
      case 'adaptability': return adaptability;
      
      // Off-ice factors
      case 'physicalFitness': return physicalFitness;
      case 'nutritionHabits': return nutritionHabits;
      case 'sleepQuality': return sleepQuality;
      case 'mentalToughness': return mentalToughness;
      case 'timeManagement': return timeManagement;
      case 'respectForOthers': return respectForOthers;
      case 'commitment': return commitment;
      case 'goalSetting': return goalSetting;
      case 'communicationSkills': return communicationSkills;
      
      // Youth factors
      case 'funEnjoyment': return funEnjoyment;
      case 'attentionSpan': return attentionSpan;
      case 'followingInstructions': return followingInstructions;
      case 'sharing': return sharing;
      case 'equipmentCare': return equipmentCare;
      case 'parentSupport': return parentSupport;
      
      // Teen factors
      case 'academicPerformance': return academicPerformance;
      case 'socialMediaHabits': return socialMediaHabits;
      case 'peerInfluence': return peerInfluence;
      case 'independence': return independence;
      case 'substanceAwareness': return substanceAwareness;
      case 'conflictResolution': return conflictResolution;
      
      // Adult factors
      case 'professionalBalance': return professionalBalance;
      case 'financialManagement': return financialManagement;
      case 'familyCommitments': return familyCommitments;
      case 'careerPlanning': return careerPlanning;
      case 'stressManagement': return stressManagement;
      case 'longTermVision': return longTermVision;
      
      default: return 5.0;
    }
  }

  void setRatingValue(String key, double value) {
    switch (key) {
      // On-ice factors
      case 'hockeyIQ': hockeyIQ = value; break;
      case 'competitiveness': competitiveness = value; break;
      case 'workEthic': workEthic = value; break;
      case 'coachability': coachability = value; break;
      case 'leadership': leadership = value; break;
      case 'teamPlay': teamPlay = value; break;
      case 'decisionMaking': decisionMaking = value; break;
      case 'adaptability': adaptability = value; break;
      
      // Off-ice factors
      case 'physicalFitness': physicalFitness = value; break;
      case 'nutritionHabits': nutritionHabits = value; break;
      case 'sleepQuality': sleepQuality = value; break;
      case 'mentalToughness': mentalToughness = value; break;
      case 'timeManagement': timeManagement = value; break;
      case 'respectForOthers': respectForOthers = value; break;
      case 'commitment': commitment = value; break;
      case 'goalSetting': goalSetting = value; break;
      case 'communicationSkills': communicationSkills = value; break;
      
      // Youth factors
      case 'funEnjoyment': funEnjoyment = value; break;
      case 'attentionSpan': attentionSpan = value; break;
      case 'followingInstructions': followingInstructions = value; break;
      case 'sharing': sharing = value; break;
      case 'equipmentCare': equipmentCare = value; break;
      case 'parentSupport': parentSupport = value; break;
      
      // Teen factors
      case 'academicPerformance': academicPerformance = value; break;
      case 'socialMediaHabits': socialMediaHabits = value; break;
      case 'peerInfluence': peerInfluence = value; break;
      case 'independence': independence = value; break;
      case 'substanceAwareness': substanceAwareness = value; break;
      case 'conflictResolution': conflictResolution = value; break;
      
      // Adult factors
      case 'professionalBalance': professionalBalance = value; break;
      case 'financialManagement': financialManagement = value; break;
      case 'familyCommitments': familyCommitments = value; break;
      case 'careerPlanning': careerPlanning = value; break;
      case 'stressManagement': stressManagement = value; break;
      case 'longTermVision': longTermVision = value; break;
    }
  }

  /// Update calculated scores from backend response
  void updateCalculatedScores(Map<String, dynamic> scoreData) {
    final scores = scoreData['scores'] as Map<String, dynamic>? ?? {};
    final components = scoreData['components'] as Map<String, dynamic>? ?? {};
    
    // Update main HIRE scores (from backend calculation service)
    hScore = (scores['h_score'] as num?)?.toDouble() ?? 0.0;
    iScore = (scores['i_score'] as num?)?.toDouble() ?? 0.0;
    rScore = (scores['r_score'] as num?)?.toDouble() ?? 0.0;
    eScore = (scores['e_score'] as num?)?.toDouble() ?? 0.0;
    overallHIREScore = (scores['overall_hire_score'] as num?)?.toDouble() ?? 0.0;
    
    // Update component scores (from backend calculation service)
    humilityScore = (components['humility'] as num?)?.toDouble() ?? 0.0;
    hardworkScore = (components['hardwork'] as num?)?.toDouble() ?? 0.0;
    initiativeScore = (components['initiative'] as num?)?.toDouble() ?? 0.0;
    integrityScore = (components['integrity'] as num?)?.toDouble() ?? 0.0;
    responsibilityScore = (components['responsibility'] as num?)?.toDouble() ?? 0.0;
    respectScore = (components['respect'] as num?)?.toDouble() ?? 0.0;
    enthusiasmScore = (components['enthusiasm'] as num?)?.toDouble() ?? 0.0;
  }

  /// Request HIRE score calculation from backend
  Future<Map<String, dynamic>?> requestHIRECalculation() async {
    print('WARNING: requestHIRECalculation() should be implemented to call backend API');
    print('All HIRE calculations must be performed by the backend HIRECalculationService');
    return null;
  }

  // Get ratings appropriate for display (filtered by age)
  Map<String, double> getAllRatings({int? playerAge}) {
    final Map<String, double> ratings = {};
    
    if (playerAge != null) {
      final categories = HockeyRatingsConfig.getCategoriesForAge(playerAge);
      
      for (final category in categories) {
        for (final factor in category.factors) {
          ratings[factor.key] = getRatingValue(factor.key);
        }
      }
    } else {
      final allFactors = HockeyRatingsConfig.onIceFactors.factors +
                        HockeyRatingsConfig.offIceFactors.factors +
                        HockeyRatingsConfig.youthFactors.factors +
                        HockeyRatingsConfig.teenFactors.factors +
                        HockeyRatingsConfig.adultFactors.factors;
      
      for (final factor in allFactors) {
        ratings[factor.key] = getRatingValue(factor.key);
      }
    }
    
    return ratings;
  }

  // Get ALL ratings including all age-specific factors (for backend storage)
  Map<String, double> getAllInputRatings() {
    final Map<String, double> ratings = {};
    
    final allFactors = HockeyRatingsConfig.onIceFactors.factors +
                      HockeyRatingsConfig.offIceFactors.factors +
                      HockeyRatingsConfig.youthFactors.factors +
                      HockeyRatingsConfig.teenFactors.factors +
                      HockeyRatingsConfig.adultFactors.factors;
    
    for (final factor in allFactors) {
      ratings[factor.key] = getRatingValue(factor.key);
    }
    
    return ratings;
  }

  // Keep all other existing methods...
  List<String> getTopStrengths({int? playerAge, int limit = 3}) {
    final relevantRatings = getAllRatings(playerAge: playerAge);
    return HockeyRatingsConfig.getTopStrengths(relevantRatings, limit: limit);
  }

  List<String> getImprovementAreas({int? playerAge, int limit = 3}) {
    final relevantRatings = getAllRatings(playerAge: playerAge);
    return HockeyRatingsConfig.getImprovementAreas(relevantRatings, limit: limit);
  }

  RatingFactor? getRatingFactor(String key) {
    return HockeyRatingsConfig.getFactor(key);
  }

  String getScaleDescription(String key) {
    final rating = getRatingValue(key);
    return HockeyRatingsConfig.getScaleDescription(key, rating);
  }

  Map<String, Map<String, double>> getRatingsByCategory({int? playerAge}) {
    final Map<String, Map<String, double>> result = {};
    
    final categories = playerAge != null 
        ? HockeyRatingsConfig.getCategoriesForAge(playerAge)
        : [
            HockeyRatingsConfig.onIceFactors,
            HockeyRatingsConfig.offIceFactors,
            HockeyRatingsConfig.youthFactors,
            HockeyRatingsConfig.teenFactors,
            HockeyRatingsConfig.adultFactors,
          ];
    
    for (final category in categories) {
      final categoryRatings = <String, double>{};
      for (final factor in category.factors) {
        categoryRatings[factor.key] = getRatingValue(factor.key);
      }
      result[category.title] = categoryRatings;
    }
    
    return result;
  }
}

// Extension methods for HIREPlayerRatings
extension HIREPlayerRatingsExtension on HIREPlayerRatings {
  String get hireScoreInterpretation {
    if (overallHIREScore >= 9.0) return 'Elite HIRE characteristics';
    if (overallHIREScore >= 8.0) return 'Strong HIRE traits';
    if (overallHIREScore >= 7.0) return 'Good HIRE development';
    if (overallHIREScore >= 6.0) return 'Average HIRE traits';
    if (overallHIREScore >= 5.0) return 'Below average - needs improvement';
    return 'Requires significant development';
  }

  Color get hireScoreColor {
    return HockeyRatingsConfig.getColorForRating(overallHIREScore);
  }

  bool meetsMinimumStandards({double threshold = 6.0}) {
    return overallHIREScore >= threshold;
  }

  Map<String, String> getDetailedBreakdown() {
    return {
      'H (Hockey)': '${hScore.toStringAsFixed(1)} - $hireScoreInterpretation',
      'I (Integrity)': '${iScore.toStringAsFixed(1)} - $hireScoreInterpretation',
      'R (Respect)': '${rScore.toStringAsFixed(1)} - $hireScoreInterpretation',
      'E (Excellence)': '${eScore.toStringAsFixed(1)} - $hireScoreInterpretation',
      'Overall': '${overallHIREScore.toStringAsFixed(1)} - $hireScoreInterpretation',
    };
  }

  List<String> getRatingsNeedingAttention({int? playerAge}) {
    final ratings = getAllRatings(playerAge: playerAge);
    final needAttention = <String>[];
    
    ratings.forEach((key, value) {
      if (value < 6.0) {
        final factor = HockeyRatingsConfig.getFactor(key);
        needAttention.add(factor?.title ?? key);
      }
    });
    
    return needAttention;
  }

  List<String> getStrongestRatings({int? playerAge}) {
    final ratings = getAllRatings(playerAge: playerAge);
    final strongest = <String>[];
    
    ratings.forEach((key, value) {
      if (value >= 8.0) {
        final factor = HockeyRatingsConfig.getFactor(key);
        strongest.add(factor?.title ?? key);
      }
    });
    
    return strongest;
  }
}

// Keep all existing DevelopmentInsights class exactly as it was...
class DevelopmentInsights {
  final List<String> strengths;
  final List<String> focusAreas;
  final List<String> priorityActions;
  final List<String> characterStrengths;
  final String developmentLevel;
  final double overallScore;
  final Map<String, List<String>> categoryInsights;

  const DevelopmentInsights({
    required this.strengths,
    required this.focusAreas,
    required this.priorityActions,
    required this.characterStrengths,
    required this.developmentLevel,
    required this.overallScore,
    required this.categoryInsights,
  });

  factory DevelopmentInsights.fromRatings(HIREPlayerRatings ratings, int age) {
    final allRatings = ratings.getAllRatings(playerAge: age);
    
    final strengths = HockeyRatingsConfig.getTopStrengths(allRatings, limit: 3);
    final focusAreas = HockeyRatingsConfig.getImprovementAreas(allRatings, limit: 3);
    
    final priorityActions = _generatePriorityActions(ratings, age);
    final characterStrengths = _generateCharacterStrengths(ratings);
    final developmentLevel = _getDevelopmentLevel(ratings.overallHIREScore);
    final categoryInsights = _generateCategoryInsights(ratings, age);
    
    return DevelopmentInsights(
      strengths: strengths,
      focusAreas: focusAreas,
      priorityActions: priorityActions,
      characterStrengths: characterStrengths,
      developmentLevel: developmentLevel,
      overallScore: ratings.overallHIREScore,
      categoryInsights: categoryInsights,
    );
  }

  static List<String> _generatePriorityActions(HIREPlayerRatings ratings, int age) {
    final actions = <String>[];
    final categories = HockeyRatingsConfig.getCategoriesForAge(age);
    
    final lowRatings = <String, double>{};
    for (final category in categories) {
      for (final factor in category.factors) {
        final rating = ratings.getRatingValue(factor.key);
        if (rating < 6.0) {
          lowRatings[factor.key] = rating;
        }
      }
    }
    
    final sortedLowRatings = lowRatings.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    for (final entry in sortedLowRatings.take(4)) {
      final factor = HockeyRatingsConfig.getFactor(entry.key);
      if (factor != null) {
        actions.add('Focus on improving ${factor.title}: ${factor.whyItMatters}');
      }
    }
    
    return actions;
  }

  static List<String> _generateCharacterStrengths(HIREPlayerRatings ratings) {
    final strengths = <String>[];
    
    final characterFactors = [
      ('coachability', 'High coachability makes them easy to develop'),
      ('workEthic', 'Outstanding work ethic drives continuous improvement'),
      ('leadership', 'Natural leadership qualities inspire teammates'),
      ('competitiveness', 'Strong competitive drive elevates performance'),
      ('teamPlay', 'Excellent team player who makes others better'),
      ('respectForOthers', 'Respectful attitude creates positive team culture'),
      ('commitment', 'High commitment level shows dedication to improvement'),
      ('mentalToughness', 'Mental toughness helps overcome challenges'),
    ];
    
    for (final (key, description) in characterFactors) {
      if (ratings.getRatingValue(key) >= 8.0) {
        strengths.add(description);
      }
    }
    
    return strengths.take(3).toList();
  }

  static String _getDevelopmentLevel(double score) {
    if (score >= 9.0) return 'Elite HIRE characteristics - program exemplar';
    if (score >= 8.0) return 'Strong HIRE traits - leadership candidate';
    if (score >= 7.0) return 'Good HIRE development - on positive trajectory';
    if (score >= 6.0) return 'Average HIRE traits - needs focused improvement';
    if (score >= 5.0) return 'Below average - requires significant development';
    return 'Concerning - may not be good fit for program values';
  }

  static Map<String, List<String>> _generateCategoryInsights(HIREPlayerRatings ratings, int age) {
    final insights = <String, List<String>>{};
    final categories = HockeyRatingsConfig.getCategoriesForAge(age);
    
    for (final category in categories) {
      final categoryInsights = <String>[];
      final categoryRatings = <double>[];
      
      for (final factor in category.factors) {
        categoryRatings.add(ratings.getRatingValue(factor.key));
      }
      
      final avgRating = categoryRatings.fold(0.0, (a, b) => a + b) / categoryRatings.length;
      
      if (avgRating >= 8.0) {
        categoryInsights.add('Exceptional strength in this area');
      } else if (avgRating >= 7.0) {
        categoryInsights.add('Strong foundation, continue building');
      } else if (avgRating >= 6.0) {
        categoryInsights.add('Solid base, focus on consistency');
      } else if (avgRating >= 5.0) {
        categoryInsights.add('Needs focused improvement');
      } else {
        categoryInsights.add('Priority development area');
      }
      
      insights[category.title] = categoryInsights;
    }
    
    return insights;
  }
}