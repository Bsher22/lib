// lib/utils/analytics_constants.dart

enum SkillType { shooting, skating }

class AnalyticsConstants {
  static const Map<SkillType, String> skillTypeNames = {
    SkillType.shooting: 'shots',
    SkillType.skating: 'skating',
  };
  
  static const Map<SkillType, String> skillTypeDisplayNames = {
    SkillType.shooting: 'Shooting',
    SkillType.skating: 'Skating',
  };
}