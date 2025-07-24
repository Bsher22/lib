// lib/utils/hockey_ratings_config.dart

import 'package:flutter/material.dart';

// ============================================================================
// CORE RATING MODELS
// ============================================================================

class RatingScale {
  final int value;
  final String label;
  final String description;

  const RatingScale({
    required this.value,
    required this.label,
    required this.description,
  });
}

class RatingFactor {
  final String key;
  final String title;
  final String description;
  final String whyItMatters;
  final List<RatingScale> scaleDescriptions;
  final List<String> quickLabels; // For slider display
  final String category;

  const RatingFactor({
    required this.key,
    required this.title,
    required this.description,
    required this.whyItMatters,
    required this.scaleDescriptions,
    required this.quickLabels,
    required this.category,
  });
}

class RatingCategory {
  final String key;
  final String title;
  final String description;
  final AgeGroup? ageGroup;
  final List<RatingFactor> factors;

  const RatingCategory({
    required this.key,
    required this.title,
    required this.description,
    this.ageGroup,
    required this.factors,
  });
}

enum AgeGroup {
  youth(8, 12, 'Youth'),
  teen(13, 17, 'Teen'), 
  adult(18, 99, 'Adult');
  
  const AgeGroup(this.minAge, this.maxAge, this.label);
  
  final int minAge;
  final int maxAge;
  final String label;
  
  static AgeGroup fromAge(int age) {
    if (age >= 8 && age <= 12) return AgeGroup.youth;
    if (age >= 13 && age <= 17) return AgeGroup.teen;
    return AgeGroup.adult;
  }
}

// ============================================================================
// COMPREHENSIVE HOCKEY RATINGS CONFIGURATION
// ============================================================================

class HockeyRatingsConfig {
  
  // ============================================================================
  // RATING CONSTANTS
  // ============================================================================
  
  static const double minRating = 1.0;
  static const double maxRating = 10.0;
  static const double defaultRating = 5.0;
  
  // Threshold definitions
  static const double excellentThreshold = 8.5;
  static const double goodThreshold = 7.0;
  static const double averageThreshold = 5.0;
  static const double belowAverageThreshold = 3.0;
  
  // ============================================================================
  // ON-ICE PERFORMANCE FACTORS
  // ============================================================================
  
  static const RatingCategory onIceFactors = RatingCategory(
    key: 'onIce',
    title: 'On-Ice Performance Factors',
    description: 'Core hockey skills and mental attributes that directly impact game performance',
    factors: [
      RatingFactor(
        key: 'hockeyIQ',
        title: 'Hockey IQ',
        description: 'Reading the game, anticipation, and smart decision-making',
        whyItMatters: 'Players with high Hockey IQ often outperform more skilled players because they\'re always in the right place at the right time.',
        quickLabels: ['Poor', 'Below Avg', 'Average', 'Good', 'Excellent'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Always seems surprised by plays, makes obvious mistakes'),
          RatingScale(value: 2, label: 'Poor', description: 'Frequently confused, struggles to read basic plays'),
          RatingScale(value: 3, label: 'Poor', description: 'Limited game awareness, makes predictable mistakes'),
          RatingScale(value: 4, label: 'Below Average', description: 'Sometimes reads plays correctly but often confused'),
          RatingScale(value: 5, label: 'Below Average', description: 'Developing game sense, inconsistent reads'),
          RatingScale(value: 6, label: 'Average', description: 'Usually makes the right play, decent anticipation'),
          RatingScale(value: 7, label: 'Good', description: 'Good game awareness, some creative moments'),
          RatingScale(value: 8, label: 'Excellent', description: 'Consistently anticipates plays, sees the ice well'),
          RatingScale(value: 9, label: 'Excellent', description: 'Makes smart decisions under pressure, excellent anticipation'),
          RatingScale(value: 10, label: 'Elite', description: 'Always two steps ahead, exceptional game sense'),
        ],
      ),
      
      RatingFactor(
        key: 'competitiveness',
        title: 'Competitiveness',
        description: 'Desire to win, battle level, and competitive drive',
        whyItMatters: 'Hockey is a battle sport. Players who compete harder often overcome skill gaps.',
        quickLabels: ['Low', 'Below Avg', 'Average', 'High', 'Elite'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Low', description: 'Gives up easily, doesn\'t compete for loose pucks'),
          RatingScale(value: 2, label: 'Low', description: 'Minimal battle level, backs down from challenges'),
          RatingScale(value: 3, label: 'Low', description: 'Competes only when convenient, low intensity'),
          RatingScale(value: 4, label: 'Below Average', description: 'Competes sometimes but inconsistent'),
          RatingScale(value: 5, label: 'Below Average', description: 'Some competitive moments but often passive'),
          RatingScale(value: 6, label: 'Average', description: 'Usually competes hard, wants to win'),
          RatingScale(value: 7, label: 'High', description: 'Battles most of the time, good competitive drive'),
          RatingScale(value: 8, label: 'High', description: 'Extremely competitive, hates losing'),
          RatingScale(value: 9, label: 'Elite', description: 'Elevates game in big moments, infectious competitiveness'),
          RatingScale(value: 10, label: 'Elite', description: 'Obsessed with winning, brings out competitiveness in others'),
        ],
      ),
      
      RatingFactor(
        key: 'workEthic',
        title: 'Work Ethic',
        description: 'Effort level in practice and games, willingness to improve',
        whyItMatters: 'Talent without work ethic hits a ceiling quickly.',
        quickLabels: ['Poor', 'Below Avg', 'Average', 'Strong', 'Outstanding'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Coasts through drills, minimal effort'),
          RatingScale(value: 2, label: 'Poor', description: 'Low effort in practice, rarely challenges themselves'),
          RatingScale(value: 3, label: 'Poor', description: 'Does minimum required, no extra effort'),
          RatingScale(value: 4, label: 'Below Average', description: 'Works hard sometimes, inconsistent effort'),
          RatingScale(value: 5, label: 'Below Average', description: 'Decent effort but could push harder'),
          RatingScale(value: 6, label: 'Average', description: 'Generally works hard, good practice habits'),
          RatingScale(value: 7, label: 'Strong', description: 'Steady improvement, consistent effort'),
          RatingScale(value: 8, label: 'Strong', description: 'Always giving maximum effort'),
          RatingScale(value: 9, label: 'Outstanding', description: 'Exceptional work ethic, pushes others to work harder'),
          RatingScale(value: 10, label: 'Outstanding', description: 'Sets the standard for work ethic'),
        ],
      ),
      
      RatingFactor(
        key: 'coachability',
        title: 'Coachability',
        description: 'Ability to receive feedback and implement corrections',
        whyItMatters: 'Uncoachable players stop improving.',
        quickLabels: ['Resistant', 'Limited', 'Average', 'Good', 'Excellent'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Resistant', description: 'Argues with coaches, doesn\'t apply feedback'),
          RatingScale(value: 2, label: 'Resistant', description: 'Dismissive of coaching, resistant to change'),
          RatingScale(value: 3, label: 'Resistant', description: 'Listens but doesn\'t implement feedback'),
          RatingScale(value: 4, label: 'Limited', description: 'Sometimes listens but struggles to implement changes'),
          RatingScale(value: 5, label: 'Limited', description: 'Accepts feedback but slow to make adjustments'),
          RatingScale(value: 6, label: 'Average', description: 'Generally receptive to coaching'),
          RatingScale(value: 7, label: 'Good', description: 'Makes adjustments over time, good listener'),
          RatingScale(value: 8, label: 'Good', description: 'Actively seeks feedback, quickly implements corrections'),
          RatingScale(value: 9, label: 'Excellent', description: 'Eager learner, immediate implementation of feedback'),
          RatingScale(value: 10, label: 'Excellent', description: 'Hungry for feedback, learns immediately'),
        ],
      ),
      
      RatingFactor(
        key: 'leadership',
        title: 'Leadership',
        description: 'Leading by example, motivating teammates, taking responsibility',
        whyItMatters: 'Teams need leaders at every level.',
        quickLabels: ['Follower', 'Quiet', 'Supportive', 'Vocal', 'Natural Leader'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Follower', description: 'Passive, never speaks up'),
          RatingScale(value: 2, label: 'Follower', description: 'Very quiet, waits for others to lead'),
          RatingScale(value: 3, label: 'Follower', description: 'Rarely takes initiative'),
          RatingScale(value: 4, label: 'Quiet', description: 'Occasionally shows leadership but usually follows'),
          RatingScale(value: 5, label: 'Quiet', description: 'Leads by example but rarely vocal'),
          RatingScale(value: 6, label: 'Supportive', description: 'Supports teammates, positive influence'),
          RatingScale(value: 7, label: 'Vocal', description: 'Sometimes takes charge, encouraging to others'),
          RatingScale(value: 8, label: 'Vocal', description: 'Others look to them for guidance'),
          RatingScale(value: 9, label: 'Natural Leader', description: 'Strong leadership presence, teammates follow naturally'),
          RatingScale(value: 10, label: 'Natural Leader', description: 'Transformational leader'),
        ],
      ),
      
      RatingFactor(
        key: 'teamPlay',
        title: 'Team Play',
        description: 'Playing for the team, making the right play, unselfishness',
        whyItMatters: 'Hockey is the ultimate team sport.',
        quickLabels: ['Selfish', 'Individual', 'Average', 'Team-First', 'Selfless'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Selfish', description: 'Always shoots when should pass'),
          RatingScale(value: 2, label: 'Selfish', description: 'Rarely makes the team play, seeks personal glory'),
          RatingScale(value: 3, label: 'Selfish', description: 'Occasionally makes team play but usually individual-focused'),
          RatingScale(value: 4, label: 'Individual', description: 'Sometimes makes the team play but often looks for personal glory'),
          RatingScale(value: 5, label: 'Individual', description: 'Decent balance but still individual-focused'),
          RatingScale(value: 6, label: 'Average', description: 'Usually makes the right play, good team awareness'),
          RatingScale(value: 7, label: 'Team-First', description: 'Generally team-focused, makes smart plays'),
          RatingScale(value: 8, label: 'Team-First', description: 'Always makes the play that helps the team win'),
          RatingScale(value: 9, label: 'Selfless', description: 'Consistently puts team first, excellent team player'),
          RatingScale(value: 10, label: 'Selfless', description: 'Sacrifices personal success for team success'),
        ],
      ),
      
      RatingFactor(
        key: 'decisionMaking',
        title: 'Decision Making Under Pressure',
        description: 'Making good choices when the game is on the line',
        whyItMatters: 'Games are won and lost in crucial moments.',
        quickLabels: ['Poor', 'Struggles', 'Average', 'Good', 'Clutch'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Panics under pressure, makes bad decisions'),
          RatingScale(value: 2, label: 'Poor', description: 'Consistently poor decisions when pressure increases'),
          RatingScale(value: 3, label: 'Poor', description: 'Struggles with any pressure situations'),
          RatingScale(value: 4, label: 'Struggles', description: 'Sometimes makes good decisions but often cracks under pressure'),
          RatingScale(value: 5, label: 'Struggles', description: 'Inconsistent under pressure'),
          RatingScale(value: 6, label: 'Average', description: 'Generally makes decent decisions'),
          RatingScale(value: 7, label: 'Good', description: 'Handles some pressure, usually makes smart choices'),
          RatingScale(value: 8, label: 'Good', description: 'Thrives under pressure, makes great decisions'),
          RatingScale(value: 9, label: 'Clutch', description: 'Consistently excellent under pressure'),
          RatingScale(value: 10, label: 'Clutch', description: 'Always rises to the occasion'),
        ],
      ),
      
      RatingFactor(
        key: 'adaptability',
        title: 'Adaptability',
        description: 'Adjusting to different systems, roles, and game situations',
        whyItMatters: 'Hockey is constantly evolving.',
        quickLabels: ['Rigid', 'Limited', 'Average', 'Flexible', 'Versatile'],
        category: 'onIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Rigid', description: 'Can only play one way, struggles with changes'),
          RatingScale(value: 2, label: 'Rigid', description: 'Very resistant to change, locked into one style'),
          RatingScale(value: 3, label: 'Rigid', description: 'Minimal adaptability, needs familiar situations'),
          RatingScale(value: 4, label: 'Limited', description: 'Adapts slowly, needs lots of time to adjust'),
          RatingScale(value: 5, label: 'Limited', description: 'Some adaptability but prefers familiar situations'),
          RatingScale(value: 6, label: 'Average', description: 'Generally adapts well'),
          RatingScale(value: 7, label: 'Flexible', description: 'Can play different roles, adjusts reasonably well'),
          RatingScale(value: 8, label: 'Flexible', description: 'Quickly adapts to new situations'),
          RatingScale(value: 9, label: 'Versatile', description: 'Excellent adaptability, embraces change'),
          RatingScale(value: 10, label: 'Versatile', description: 'Thrives on change, makes any system work'),
        ],
      ),
    ],
  );

  // ============================================================================
  // OFF-ICE LIFE FACTORS
  // ============================================================================
  
  static const RatingCategory offIceFactors = RatingCategory(
    key: 'offIce',
    title: 'Off-Ice Life Factors',
    description: 'Personal habits and characteristics that support hockey development',
    factors: [
      RatingFactor(
        key: 'physicalFitness',
        title: 'Physical Fitness',
        description: 'Overall conditioning, strength, and athletic ability',
        whyItMatters: 'Hockey demands elite fitness.',
        quickLabels: ['Poor', 'Below Avg', 'Average', 'Good', 'Elite'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Poor conditioning, gets tired quickly'),
          RatingScale(value: 2, label: 'Poor', description: 'Below average strength and conditioning'),
          RatingScale(value: 3, label: 'Poor', description: 'Struggles with basic fitness requirements'),
          RatingScale(value: 4, label: 'Below Average', description: 'Below team fitness standards'),
          RatingScale(value: 5, label: 'Below Average', description: 'Adequate but could improve fitness significantly'),
          RatingScale(value: 6, label: 'Average', description: 'Meets fitness expectations'),
          RatingScale(value: 7, label: 'Good', description: 'Decent strength and conditioning'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent fitness, rarely gets tired'),
          RatingScale(value: 9, label: 'Elite', description: 'Outstanding physical condition'),
          RatingScale(value: 10, label: 'Elite', description: 'Superior athlete, sets fitness standards'),
        ],
      ),
      
      RatingFactor(
        key: 'nutritionHabits',
        title: 'Nutrition Habits',
        description: 'Eating habits that support performance and recovery',
        whyItMatters: 'Nutrition directly impacts energy and recovery.',
        quickLabels: ['Poor', 'Below Avg', 'Average', 'Good', 'Excellent'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Fast food, junk food, poor meal timing'),
          RatingScale(value: 2, label: 'Poor', description: 'Consistently poor food choices'),
          RatingScale(value: 3, label: 'Poor', description: 'Limited understanding of proper nutrition'),
          RatingScale(value: 4, label: 'Below Average', description: 'Some good choices but inconsistent'),
          RatingScale(value: 5, label: 'Below Average', description: 'Developing better habits but still inconsistent'),
          RatingScale(value: 6, label: 'Average', description: 'Generally eats well'),
          RatingScale(value: 7, label: 'Good', description: 'Understands basic sports nutrition'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent nutrition plan, optimal fueling'),
          RatingScale(value: 9, label: 'Excellent', description: 'Sophisticated nutrition knowledge'),
          RatingScale(value: 10, label: 'Excellent', description: 'Nutrition expert, optimizes every meal'),
        ],
      ),
      
      RatingFactor(
        key: 'sleepQuality',
        title: 'Sleep Quality & Schedule',
        description: 'Getting adequate rest for recovery and performance',
        whyItMatters: 'Sleep is when the body recovers and grows stronger.',
        quickLabels: ['Poor', 'Below Avg', 'Average', 'Good', 'Excellent'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Inconsistent sleep, poor quality, often tired'),
          RatingScale(value: 2, label: 'Poor', description: 'Regularly tired, poor sleep habits'),
          RatingScale(value: 3, label: 'Poor', description: 'Sleep issues affecting performance'),
          RatingScale(value: 4, label: 'Below Average', description: 'Sometimes gets good sleep but often insufficient'),
          RatingScale(value: 5, label: 'Below Average', description: 'Inconsistent sleep schedule'),
          RatingScale(value: 6, label: 'Average', description: 'Generally good sleep habits'),
          RatingScale(value: 7, label: 'Good', description: 'Adequate rest most nights'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent sleep routine, consistently well-rested'),
          RatingScale(value: 9, label: 'Excellent', description: 'Optimized sleep schedule'),
          RatingScale(value: 10, label: 'Excellent', description: 'Optimized sleep for performance'),
        ],
      ),
      
      RatingFactor(
        key: 'mentalToughness',
        title: 'Mental Toughness',
        description: 'Resilience, handling adversity, and mental strength',
        whyItMatters: 'Hockey involves constant failure and adversity.',
        quickLabels: ['Fragile', 'Sensitive', 'Average', 'Resilient', 'Unbreakable'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Fragile', description: 'Breaks down under pressure, quits when things get hard'),
          RatingScale(value: 2, label: 'Fragile', description: 'Very sensitive to criticism and setbacks'),
          RatingScale(value: 3, label: 'Fragile', description: 'Struggles significantly with adversity'),
          RatingScale(value: 4, label: 'Sensitive', description: 'Sometimes resilient but often struggles'),
          RatingScale(value: 5, label: 'Sensitive', description: 'Developing resilience but still sensitive'),
          RatingScale(value: 6, label: 'Average', description: 'Generally bounces back'),
          RatingScale(value: 7, label: 'Resilient', description: 'Handles most challenges, good mental strength'),
          RatingScale(value: 8, label: 'Resilient', description: 'Thrives under adversity'),
          RatingScale(value: 9, label: 'Unbreakable', description: 'Exceptional mental toughness'),
          RatingScale(value: 10, label: 'Unbreakable', description: 'Impossible to break, uses setbacks as motivation'),
        ],
      ),
      
      RatingFactor(
        key: 'timeManagement',
        title: 'Time Management',
        description: 'Balancing hockey, school/work, and personal life',
        whyItMatters: 'Players with good time management can dedicate proper energy to hockey.',
        quickLabels: ['Poor', 'Struggles', 'Average', 'Good', 'Excellent'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Always late, misses commitments'),
          RatingScale(value: 2, label: 'Poor', description: 'Frequently disorganized, poor planning'),
          RatingScale(value: 3, label: 'Poor', description: 'Struggles with basic time management'),
          RatingScale(value: 4, label: 'Struggles', description: 'Sometimes organized but often overwhelmed'),
          RatingScale(value: 5, label: 'Struggles', description: 'Developing organization skills but inconsistent'),
          RatingScale(value: 6, label: 'Average', description: 'Generally manages time well'),
          RatingScale(value: 7, label: 'Good', description: 'Meets most commitments, good organization'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent organization, balances everything effectively'),
          RatingScale(value: 9, label: 'Excellent', description: 'Exceptional time management'),
          RatingScale(value: 10, label: 'Excellent', description: 'Time management expert'),
        ],
      ),
      
      RatingFactor(
        key: 'respectForOthers',
        title: 'Respect for Others',
        description: 'How they treat teammates, coaches, officials, and opponents',
        whyItMatters: 'Respect builds trust and team chemistry.',
        quickLabels: ['Disrespectful', 'Limited', 'Average', 'Respectful', 'Exemplary'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Disrespectful', description: 'Rude, disrespectful, creates negative environment'),
          RatingScale(value: 2, label: 'Disrespectful', description: 'Frequently disrespectful to others'),
          RatingScale(value: 3, label: 'Disrespectful', description: 'Often inconsiderate, poor treatment of others'),
          RatingScale(value: 4, label: 'Limited', description: 'Sometimes disrespectful, inconsistent'),
          RatingScale(value: 5, label: 'Limited', description: 'Generally okay but occasional respect issues'),
          RatingScale(value: 6, label: 'Average', description: 'Generally respectful'),
          RatingScale(value: 7, label: 'Respectful', description: 'Treats others well, positive interactions'),
          RatingScale(value: 8, label: 'Respectful', description: 'Always respectful, positive role model'),
          RatingScale(value: 9, label: 'Exemplary', description: 'Outstanding respect for others'),
          RatingScale(value: 10, label: 'Exemplary', description: 'Sets the standard for respect'),
        ],
      ),
      
      RatingFactor(
        key: 'commitment',
        title: 'Commitment & Dedication',
        description: 'Consistency in showing up and giving their best effort',
        whyItMatters: 'Development requires consistent commitment over years.',
        quickLabels: ['Unreliable', 'Sporadic', 'Average', 'Dedicated', 'Unwavering'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Unreliable', description: 'Frequently misses practice, inconsistent effort'),
          RatingScale(value: 2, label: 'Unreliable', description: 'Poor attendance and commitment'),
          RatingScale(value: 3, label: 'Unreliable', description: 'Inconsistent dedication to hockey'),
          RatingScale(value: 4, label: 'Sporadic', description: 'Sometimes committed but often distracted'),
          RatingScale(value: 5, label: 'Sporadic', description: 'Developing commitment but still inconsistent'),
          RatingScale(value: 6, label: 'Average', description: 'Generally reliable'),
          RatingScale(value: 7, label: 'Dedicated', description: 'Consistent commitment, good dedication'),
          RatingScale(value: 8, label: 'Dedicated', description: 'Extremely committed, hockey is top priority'),
          RatingScale(value: 9, label: 'Unwavering', description: 'Exceptional dedication and commitment'),
          RatingScale(value: 10, label: 'Unwavering', description: 'Total dedication, never wavers'),
        ],
      ),
      
      RatingFactor(
        key: 'goalSetting',
        title: 'Goal Setting & Planning',
        description: 'Setting realistic goals and working systematically toward them',
        whyItMatters: 'Players with clear goals and plans make faster progress.',
        quickLabels: ['No Goals', 'Vague', 'Some Goals', 'Clear Goals', 'Strategic'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'No Goals', description: 'No direction, no plans, just showing up'),
          RatingScale(value: 2, label: 'No Goals', description: 'Lacks any clear direction or purpose'),
          RatingScale(value: 3, label: 'No Goals', description: 'Minimal goal setting or planning'),
          RatingScale(value: 4, label: 'Vague', description: 'Some goals but unclear or unrealistic'),
          RatingScale(value: 5, label: 'Vague', description: 'Developing goal-setting skills but still vague'),
          RatingScale(value: 6, label: 'Some Goals', description: 'Has goals and generally works toward them'),
          RatingScale(value: 7, label: 'Clear Goals', description: 'Good goal setting with decent planning'),
          RatingScale(value: 8, label: 'Clear Goals', description: 'Excellent goal setting, detailed plans'),
          RatingScale(value: 9, label: 'Strategic', description: 'Sophisticated goal setting and strategic planning'),
          RatingScale(value: 10, label: 'Strategic', description: 'Master planner, helps others set goals'),
        ],
      ),
      
      RatingFactor(
        key: 'communicationSkills',
        title: 'Communication Skills',
        description: 'Expressing themselves clearly and listening to others',
        whyItMatters: 'Good communication builds relationships and resolves conflicts.',
        quickLabels: ['Poor', 'Limited', 'Average', 'Good', 'Excellent'],
        category: 'offIce',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Very poor communication, struggles to express thoughts'),
          RatingScale(value: 2, label: 'Poor', description: 'Limited communication ability'),
          RatingScale(value: 3, label: 'Poor', description: 'Basic communication struggles'),
          RatingScale(value: 4, label: 'Limited', description: 'Sometimes communicates well but often unclear'),
          RatingScale(value: 5, label: 'Limited', description: 'Developing communication skills but needs improvement'),
          RatingScale(value: 6, label: 'Average', description: 'Generally communicates adequately'),
          RatingScale(value: 7, label: 'Good', description: 'Good communication, expresses thoughts clearly'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent communication and listening skills'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding communicator, great listener'),
          RatingScale(value: 10, label: 'Excellent', description: 'Master communicator'),
        ],
      ),
    ],
  );

  // ============================================================================
  // AGE-SPECIFIC FACTORS
  // ============================================================================

  static const RatingCategory youthFactors = RatingCategory(
    key: 'ageSpecific',
    title: 'Youth Development Factors (Ages 8-12)',
    description: 'Key factors that impact young players\' hockey development and enjoyment',
    ageGroup: AgeGroup.youth,
    factors: [
      RatingFactor(
        key: 'funEnjoyment',
        title: 'Fun & Enjoyment Level',
        description: 'How much they love playing hockey and being at the rink',
        whyItMatters: 'If kids don\'t enjoy hockey, they\'ll quit.',
        quickLabels: ['Hates It', 'Dislikes', 'Neutral', 'Enjoys', 'Loves It'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Hates It', description: 'Clearly doesn\'t want to be there'),
          RatingScale(value: 2, label: 'Hates It', description: 'Frequently unhappy at the rink'),
          RatingScale(value: 3, label: 'Dislikes', description: 'Often seems to dislike hockey activities'),
          RatingScale(value: 4, label: 'Dislikes', description: 'Sometimes enjoys it but often seems unhappy'),
          RatingScale(value: 5, label: 'Neutral', description: 'Neutral about hockey, neither loves nor hates it'),
          RatingScale(value: 6, label: 'Neutral', description: 'Generally likes hockey'),
          RatingScale(value: 7, label: 'Enjoys', description: 'Has fun most of the time'),
          RatingScale(value: 8, label: 'Enjoys', description: 'Clearly loves the game, always excited to play'),
          RatingScale(value: 9, label: 'Loves It', description: 'Extremely enthusiastic about hockey'),
          RatingScale(value: 10, label: 'Loves It', description: 'Obsessed with hockey, would play every day'),
        ],
      ),
      
      RatingFactor(
        key: 'attentionSpan',
        title: 'Attention Span',
        description: 'Ability to focus during practices and listen to instruction',
        whyItMatters: 'Young players need to focus to learn.',
        quickLabels: ['Very Short', 'Short', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Very Short', description: 'Cannot focus for more than a few seconds'),
          RatingScale(value: 2, label: 'Very Short', description: 'Extremely short attention span'),
          RatingScale(value: 3, label: 'Short', description: 'Short attention span, easily distracted'),
          RatingScale(value: 4, label: 'Short', description: 'Below average attention span for age'),
          RatingScale(value: 5, label: 'Average', description: 'Average attention span for age group'),
          RatingScale(value: 6, label: 'Average', description: 'Generally focuses well during instruction'),
          RatingScale(value: 7, label: 'Good', description: 'Good focus during practices and drills'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent attention span, rarely distracted'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding focus for age group'),
          RatingScale(value: 10, label: 'Excellent', description: 'Exceptional attention span'),
        ],
      ),
      
      RatingFactor(
        key: 'followingInstructions',
        title: 'Following Instructions',
        description: 'Listening to coaches and doing what is asked',
        whyItMatters: 'Players who follow instructions learn faster.',
        quickLabels: ['Poor', 'Struggles', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Rarely follows instructions, does own thing'),
          RatingScale(value: 2, label: 'Poor', description: 'Very poor at following directions'),
          RatingScale(value: 3, label: 'Poor', description: 'Struggles to follow basic instructions'),
          RatingScale(value: 4, label: 'Struggles', description: 'Sometimes follows instructions but often distracted'),
          RatingScale(value: 5, label: 'Struggles', description: 'Developing ability to follow instructions'),
          RatingScale(value: 6, label: 'Average', description: 'Generally follows instructions'),
          RatingScale(value: 7, label: 'Good', description: 'Good at listening and following directions'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent at following instructions immediately'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding listener, follows all instructions'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect instruction following'),
        ],
      ),
      
      RatingFactor(
        key: 'sharing',
        title: 'Sharing & Teamwork',
        description: 'Willingness to pass the puck and include teammates',
        whyItMatters: 'Learning to share and work with teammates is essential.',
        quickLabels: ['Selfish', 'Reluctant', 'Average', 'Willing', 'Natural'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Selfish', description: 'Never passes, always wants the puck'),
          RatingScale(value: 2, label: 'Selfish', description: 'Very reluctant to share or pass'),
          RatingScale(value: 3, label: 'Selfish', description: 'Struggles with sharing and teamwork'),
          RatingScale(value: 4, label: 'Reluctant', description: 'Sometimes shares but often reluctant'),
          RatingScale(value: 5, label: 'Reluctant', description: 'Developing sharing skills but still learning'),
          RatingScale(value: 6, label: 'Average', description: 'Generally willing to share and pass'),
          RatingScale(value: 7, label: 'Willing', description: 'Good at sharing and including teammates'),
          RatingScale(value: 8, label: 'Willing', description: 'Very willing to pass and work with team'),
          RatingScale(value: 9, label: 'Natural', description: 'Natural team player, always includes others'),
          RatingScale(value: 10, label: 'Natural', description: 'Perfect teammate'),
        ],
      ),
      
      RatingFactor(
        key: 'equipmentCare',
        title: 'Equipment Care',
        description: 'Taking care of their gear and being responsible',
        whyItMatters: 'Caring for equipment teaches responsibility.',
        quickLabels: ['Careless', 'Poor', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Careless', description: 'Very careless with equipment, frequently loses things'),
          RatingScale(value: 2, label: 'Careless', description: 'Poor equipment care, often messy'),
          RatingScale(value: 3, label: 'Poor', description: 'Limited responsibility for equipment'),
          RatingScale(value: 4, label: 'Poor', description: 'Sometimes takes care of equipment but inconsistent'),
          RatingScale(value: 5, label: 'Average', description: 'Developing equipment care skills'),
          RatingScale(value: 6, label: 'Average', description: 'Generally takes decent care of equipment'),
          RatingScale(value: 7, label: 'Good', description: 'Good equipment care, usually organized'),
          RatingScale(value: 8, label: 'Good', description: 'Very responsible with equipment care'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding equipment care and organization'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect equipment care'),
        ],
      ),
      
      RatingFactor(
        key: 'parentSupport',
        title: 'Parent Support Level',
        description: 'Positive family environment and encouragement',
        whyItMatters: 'Family support is crucial for young players.',
        quickLabels: ['Negative', 'Limited', 'Average', 'Supportive', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Negative', description: 'Parents create pressure, negative environment'),
          RatingScale(value: 2, label: 'Negative', description: 'Often negative interactions with parents'),
          RatingScale(value: 3, label: 'Limited', description: 'Limited positive support from family'),
          RatingScale(value: 4, label: 'Limited', description: 'Minimal support, parents not very involved'),
          RatingScale(value: 5, label: 'Average', description: 'Adequate family support'),
          RatingScale(value: 6, label: 'Average', description: 'Good support, generally positive environment'),
          RatingScale(value: 7, label: 'Supportive', description: 'Good family support, encouraging parents'),
          RatingScale(value: 8, label: 'Supportive', description: 'Excellent family support, very encouraging'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding family support and environment'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect hockey family'),
        ],
      ),
    ],
  );

  static const RatingCategory teenFactors = RatingCategory(
    key: 'ageSpecific',
    title: 'Teen Development Factors (Ages 13-17)',
    description: 'Critical factors during the teenage years that impact hockey trajectory',
    ageGroup: AgeGroup.teen,
    factors: [
      RatingFactor(
        key: 'academicPerformance',
        title: 'Academic Performance',
        description: 'Maintaining good grades and study habits',
        whyItMatters: 'Academic failure can end hockey careers.',
        quickLabels: ['Failing', 'Poor', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Failing', description: 'Failing classes, no study habits'),
          RatingScale(value: 2, label: 'Failing', description: 'Very poor academic performance'),
          RatingScale(value: 3, label: 'Poor', description: 'Poor grades, struggling academically'),
          RatingScale(value: 4, label: 'Poor', description: 'Struggling academically, below average grades'),
          RatingScale(value: 5, label: 'Average', description: 'Average academic performance'),
          RatingScale(value: 6, label: 'Average', description: 'Decent grades, generally keeps up'),
          RatingScale(value: 7, label: 'Good', description: 'Good academic performance, solid grades'),
          RatingScale(value: 8, label: 'Good', description: 'High grades, excellent student'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding academic performance'),
          RatingScale(value: 10, label: 'Excellent', description: 'Academic excellence, perfect balance with hockey'),
        ],
      ),
      
      RatingFactor(
        key: 'socialMediaHabits',
        title: 'Social Media Habits',
        description: 'Responsible use of social media and technology',
        whyItMatters: 'Poor social media habits can damage reputation.',
        quickLabels: ['Problematic', 'Excessive', 'Average', 'Controlled', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Problematic', description: 'Very problematic social media use'),
          RatingScale(value: 2, label: 'Problematic', description: 'Poor social media choices, reputation issues'),
          RatingScale(value: 3, label: 'Excessive', description: 'Excessive use affecting other areas'),
          RatingScale(value: 4, label: 'Excessive', description: 'Too much time on social media'),
          RatingScale(value: 5, label: 'Average', description: 'Average social media use'),
          RatingScale(value: 6, label: 'Average', description: 'Generally responsible social media use'),
          RatingScale(value: 7, label: 'Controlled', description: 'Good control over social media habits'),
          RatingScale(value: 8, label: 'Controlled', description: 'Excellent social media discipline'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding social media responsibility'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect social media habits'),
        ],
      ),
      
      RatingFactor(
        key: 'peerInfluence',
        title: 'Peer Influence Management',
        description: 'Choosing friends who support their hockey goals',
        whyItMatters: 'Peer influence is huge during teen years.',
        quickLabels: ['Negative', 'Poor', 'Average', 'Positive', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Negative', description: 'Negative peer influence, bad friend choices'),
          RatingScale(value: 2, label: 'Negative', description: 'Poor peer influence affecting hockey'),
          RatingScale(value: 3, label: 'Poor', description: 'Sometimes influenced negatively by peers'),
          RatingScale(value: 4, label: 'Poor', description: 'Mixed peer influence, some concerning choices'),
          RatingScale(value: 5, label: 'Average', description: 'Average peer influence'),
          RatingScale(value: 6, label: 'Average', description: 'Generally good friend choices'),
          RatingScale(value: 7, label: 'Positive', description: 'Positive peer influence, supportive friends'),
          RatingScale(value: 8, label: 'Positive', description: 'Excellent friend choices, positive influence'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding peer relationships'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect peer influence'),
        ],
      ),
      
      RatingFactor(
        key: 'independence',
        title: 'Independence & Responsibility',
        description: 'Taking ownership of their development and choices',
        whyItMatters: 'Teens must learn independence to succeed.',
        quickLabels: ['Dependent', 'Limited', 'Average', 'Independent', 'Self-Directed'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Dependent', description: 'Very dependent on others, no personal responsibility'),
          RatingScale(value: 2, label: 'Dependent', description: 'Highly dependent, limited responsibility'),
          RatingScale(value: 3, label: 'Limited', description: 'Limited independence and responsibility'),
          RatingScale(value: 4, label: 'Limited', description: 'Some independence but still needs lots of guidance'),
          RatingScale(value: 5, label: 'Average', description: 'Average independence for age'),
          RatingScale(value: 6, label: 'Average', description: 'Generally independent, takes some responsibility'),
          RatingScale(value: 7, label: 'Independent', description: 'Good independence, takes ownership'),
          RatingScale(value: 8, label: 'Independent', description: 'Very independent, excellent personal responsibility'),
          RatingScale(value: 9, label: 'Self-Directed', description: 'Outstanding independence and self-direction'),
          RatingScale(value: 10, label: 'Self-Directed', description: 'Completely self-directed'),
        ],
      ),
      
      RatingFactor(
        key: 'substanceAwareness',
        title: 'Substance Awareness',
        description: 'Making smart choices about alcohol, drugs, and substances',
        whyItMatters: 'Substance issues can derail promising careers.',
        quickLabels: ['Poor Choices', 'At Risk', 'Average', 'Good Choices', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor Choices', description: 'Regular poor choices, substance issues'),
          RatingScale(value: 2, label: 'Poor Choices', description: 'Frequent poor substance choices'),
          RatingScale(value: 3, label: 'At Risk', description: 'Some concerning substance choices'),
          RatingScale(value: 4, label: 'At Risk', description: 'Sometimes makes poor choices'),
          RatingScale(value: 5, label: 'Average', description: 'Average awareness and choices'),
          RatingScale(value: 6, label: 'Average', description: 'Generally makes good choices'),
          RatingScale(value: 7, label: 'Good Choices', description: 'Consistently makes smart substance choices'),
          RatingScale(value: 8, label: 'Good Choices', description: 'Always makes excellent choices'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding decision-making about substances'),
          RatingScale(value: 10, label: 'Excellent', description: 'Leader in making smart choices'),
        ],
      ),
      
      RatingFactor(
        key: 'conflictResolution',
        title: 'Conflict Resolution',
        description: 'Handling disagreements and problems maturely',
        whyItMatters: 'Teens face many conflicts. Learning to resolve them builds character.',
        quickLabels: ['Poor', 'Immature', 'Average', 'Mature', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Very poor conflict resolution, escalates problems'),
          RatingScale(value: 2, label: 'Poor', description: 'Poor at handling disagreements'),
          RatingScale(value: 3, label: 'Immature', description: 'Immature responses to conflict'),
          RatingScale(value: 4, label: 'Immature', description: 'Sometimes immature in handling conflicts'),
          RatingScale(value: 5, label: 'Average', description: 'Average conflict resolution for age'),
          RatingScale(value: 6, label: 'Average', description: 'Generally handles conflicts reasonably well'),
          RatingScale(value: 7, label: 'Mature', description: 'Mature approach to conflict resolution'),
          RatingScale(value: 8, label: 'Mature', description: 'Very mature in handling disagreements'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding conflict resolution skills'),
          RatingScale(value: 10, label: 'Excellent', description: 'Master at resolving conflicts'),
        ],
      ),
    ],
  );

  static const RatingCategory adultFactors = RatingCategory(
    key: 'ageSpecific',
    title: 'Adult Development Factors (Ages 18+)',
    description: 'Life balance factors that impact continued hockey development',
    ageGroup: AgeGroup.adult,
    factors: [
      RatingFactor(
        key: 'professionalBalance',
        title: 'Work/Career Balance',
        description: 'Managing career demands with hockey commitments',
        whyItMatters: 'Adults must balance multiple priorities.',
        quickLabels: ['Poor', 'Struggles', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Career constantly interferes with hockey'),
          RatingScale(value: 2, label: 'Poor', description: 'Very poor work-hockey balance'),
          RatingScale(value: 3, label: 'Struggles', description: 'Struggles with work-hockey balance'),
          RatingScale(value: 4, label: 'Struggles', description: 'Difficulty balancing, one area usually suffers'),
          RatingScale(value: 5, label: 'Average', description: 'Average balance between work and hockey'),
          RatingScale(value: 6, label: 'Average', description: 'Generally manages both reasonably well'),
          RatingScale(value: 7, label: 'Good', description: 'Good balance, both areas function well'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent balance, both areas thrive'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding work-hockey integration'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect balance'),
        ],
      ),
      
      RatingFactor(
        key: 'financialManagement',
        title: 'Financial Management',
        description: 'Budgeting for hockey expenses and financial responsibility',
        whyItMatters: 'Hockey is expensive. Good financial management ensures sustainable participation.',
        quickLabels: ['Poor', 'Struggles', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Very poor financial management'),
          RatingScale(value: 2, label: 'Poor', description: 'Poor budgeting, financial stress affects hockey'),
          RatingScale(value: 3, label: 'Struggles', description: 'Struggles with hockey expenses'),
          RatingScale(value: 4, label: 'Struggles', description: 'Sometimes struggles financially with hockey costs'),
          RatingScale(value: 5, label: 'Average', description: 'Average financial management'),
          RatingScale(value: 6, label: 'Average', description: 'Generally manages hockey expenses well'),
          RatingScale(value: 7, label: 'Good', description: 'Good budgeting and financial planning'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent financial management of hockey expenses'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding financial planning'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect financial management'),
        ],
      ),
      
      RatingFactor(
        key: 'familyCommitments',
        title: 'Family Commitments',
        description: 'Balancing family responsibilities with hockey',
        whyItMatters: 'Family support is crucial for adult players.',
        quickLabels: ['Conflict', 'Struggles', 'Average', 'Balanced', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Conflict', description: 'Constant conflict between family and hockey'),
          RatingScale(value: 2, label: 'Conflict', description: 'Frequent family-hockey conflicts'),
          RatingScale(value: 3, label: 'Struggles', description: 'Struggles to balance family and hockey'),
          RatingScale(value: 4, label: 'Struggles', description: 'Sometimes struggles with family-hockey balance'),
          RatingScale(value: 5, label: 'Average', description: 'Average family-hockey balance'),
          RatingScale(value: 6, label: 'Average', description: 'Generally balances family and hockey well'),
          RatingScale(value: 7, label: 'Balanced', description: 'Good balance between family and hockey'),
          RatingScale(value: 8, label: 'Balanced', description: 'Excellent family-hockey integration'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding family support and balance'),
          RatingScale(value: 10, label: 'Excellent', description: 'Perfect family-hockey harmony'),
        ],
      ),
      
      RatingFactor(
        key: 'careerPlanning',
        title: 'Hockey Career Planning',
        description: 'Having realistic goals and plans for hockey future',
        whyItMatters: 'Adults need realistic hockey goals to maintain motivation.',
        quickLabels: ['No Plan', 'Vague', 'Some Plan', 'Clear Plan', 'Strategic'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'No Plan', description: 'No hockey career plan or goals'),
          RatingScale(value: 2, label: 'No Plan', description: 'Very unclear about hockey future'),
          RatingScale(value: 3, label: 'Vague', description: 'Vague or unrealistic hockey goals'),
          RatingScale(value: 4, label: 'Vague', description: 'Some goals but unclear planning'),
          RatingScale(value: 5, label: 'Some Plan', description: 'Some hockey planning but could be clearer'),
          RatingScale(value: 6, label: 'Some Plan', description: 'Generally clear about hockey direction'),
          RatingScale(value: 7, label: 'Clear Plan', description: 'Clear, realistic hockey goals and planning'),
          RatingScale(value: 8, label: 'Clear Plan', description: 'Excellent hockey career planning'),
          RatingScale(value: 9, label: 'Strategic', description: 'Outstanding strategic hockey planning'),
          RatingScale(value: 10, label: 'Strategic', description: 'Master planner, perfect hockey career strategy'),
        ],
      ),
      
      RatingFactor(
        key: 'stressManagement',
        title: 'Stress Management',
        description: 'Handling life pressures while maintaining performance',
        whyItMatters: 'Adult life involves many stressors.',
        quickLabels: ['Poor', 'Struggles', 'Average', 'Good', 'Excellent'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Poor', description: 'Very poor stress management, stress hurts hockey'),
          RatingScale(value: 2, label: 'Poor', description: 'Poor at handling life stress'),
          RatingScale(value: 3, label: 'Struggles', description: 'Struggles with stress management'),
          RatingScale(value: 4, label: 'Struggles', description: 'Sometimes struggles with stress'),
          RatingScale(value: 5, label: 'Average', description: 'Average stress management'),
          RatingScale(value: 6, label: 'Average', description: 'Generally handles stress reasonably well'),
          RatingScale(value: 7, label: 'Good', description: 'Good stress management, maintains performance'),
          RatingScale(value: 8, label: 'Good', description: 'Excellent at managing stress and pressure'),
          RatingScale(value: 9, label: 'Excellent', description: 'Outstanding stress management skills'),
          RatingScale(value: 10, label: 'Excellent', description: 'Master of stress management'),
        ],
      ),
      
      RatingFactor(
        key: 'longTermVision',
        title: 'Long-term Vision',
        description: 'Understanding hockey\'s role in their overall life plan',
        whyItMatters: 'Adults with clear vision make better decisions about hockey investment.',
        quickLabels: ['Unclear', 'Limited', 'Average', 'Clear', 'Strategic'],
        category: 'ageSpecific',
        scaleDescriptions: [
          RatingScale(value: 1, label: 'Unclear', description: 'No clear vision for hockey\'s role in life'),
          RatingScale(value: 2, label: 'Unclear', description: 'Very unclear about hockey\'s long-term place'),
          RatingScale(value: 3, label: 'Limited', description: 'Limited vision for hockey in life plan'),
          RatingScale(value: 4, label: 'Limited', description: 'Some vision but unclear integration'),
          RatingScale(value: 5, label: 'Average', description: 'Average understanding of hockey\'s role'),
          RatingScale(value: 6, label: 'Average', description: 'Generally clear about hockey\'s place in life'),
          RatingScale(value: 7, label: 'Clear', description: 'Clear vision for hockey in life plan'),
          RatingScale(value: 8, label: 'Clear', description: 'Very clear integration of hockey and life goals'),
          RatingScale(value: 9, label: 'Strategic', description: 'Outstanding long-term vision and planning'),
          RatingScale(value: 10, label: 'Strategic', description: 'Perfect long-term vision'),
        ],
      ),
    ],
  );

  // ============================================================================
  // CONFIGURATION METHODS
  // ============================================================================
  
  static List<RatingCategory> getCategoriesForAge(int age) {
    final ageGroup = AgeGroup.fromAge(age);
    final categories = [onIceFactors, offIceFactors];
    
    switch (ageGroup) {
      case AgeGroup.youth:
        categories.add(youthFactors);
        break;
      case AgeGroup.teen:
        categories.add(teenFactors);
        break;
      case AgeGroup.adult:
        categories.add(adultFactors);
        break;
    }
    
    return categories;
  }
  
  static RatingFactor? getFactor(String key) {
    final allFactors = [
      ...onIceFactors.factors,
      ...offIceFactors.factors,
      ...youthFactors.factors,
      ...teenFactors.factors,
      ...adultFactors.factors,
    ];
    
    try {
      return allFactors.firstWhere((factor) => factor.key == key);
    } catch (e) {
      return null;
    }
  }
  
  static Color getColorForRating(double rating) {
    if (rating <= belowAverageThreshold) return Colors.red[600]!;
    if (rating <= averageThreshold) return Colors.orange[600]!;
    if (rating <= goodThreshold) return Colors.yellow[700]!;
    if (rating <= excellentThreshold) return Colors.lightGreen[600]!;
    return Colors.green[700]!;
  }
  
  static String getScaleDescription(String factorKey, double rating) {
    final factor = getFactor(factorKey);
    if (factor == null) return 'No description available';
    
    final index = (rating - 1).round().clamp(0, factor.scaleDescriptions.length - 1);
    return factor.scaleDescriptions[index].description;
  }
  
  static List<String> getTopStrengths(Map<String, double> ratings, {int limit = 3}) {
    final sortedRatings = ratings.entries
        .where((entry) => entry.value >= goodThreshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedRatings
        .take(limit)
        .map((entry) => getFactor(entry.key)?.title ?? entry.key)
        .toList();
  }
  
  static List<String> getImprovementAreas(Map<String, double> ratings, {int limit = 3}) {
    final sortedRatings = ratings.entries
        .where((entry) => entry.value <= averageThreshold)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    return sortedRatings
        .take(limit)
        .map((entry) => getFactor(entry.key)?.title ?? entry.key)
        .toList();
  }
  
  static double calculateOverallScore(Map<String, double> ratings) {
    if (ratings.isEmpty) return defaultRating;
    
    final sum = ratings.values.fold(0.0, (sum, rating) => sum + rating);
    return sum / ratings.length;
  }

  // ============================================================================
  // ADDITIONAL UTILITY METHODS
  // ============================================================================
  
  /// Validate rating value
  static bool isValidRating(double rating) {
    return rating >= minRating && rating <= maxRating;
  }
  
  /// Clamp rating to valid range
  static double clampRating(double rating) {
    return rating.clamp(minRating, maxRating);
  }
  
  /// Get rating level description
  static String getRatingLevel(double rating) {
    if (rating >= excellentThreshold) return 'Excellent';
    if (rating >= goodThreshold) return 'Good';
    if (rating >= averageThreshold) return 'Average';
    if (rating >= belowAverageThreshold) return 'Below Average';
    return 'Needs Improvement';
  }

  /// Get all rating keys for specific age group
  static List<String> getAllRatingKeysForAge(int age) {
    final categories = getCategoriesForAge(age);
    final List<String> allKeys = [];
    
    for (final category in categories) {
      for (final factor in category.factors) {
        allKeys.add(factor.key);
      }
    }
    
    return allKeys;
  }

  /// Get rating statistics from a list of ratings
  static Map<String, double> getRatingStatistics(List<double> ratings) {
    if (ratings.isEmpty) {
      return {
        'mean': 0.0,
        'median': 0.0,
        'min': 0.0,
        'max': 0.0,
        'standardDeviation': 0.0
      };
    }
    
    final sortedRatings = List<double>.from(ratings)..sort();
    final sum = ratings.reduce((a, b) => a + b);
    final mean = sum / ratings.length;
    
    final median = ratings.length % 2 == 0
        ? (sortedRatings[ratings.length ~/ 2 - 1] + sortedRatings[ratings.length ~/ 2]) / 2
        : sortedRatings[ratings.length ~/ 2];
    
    final variance = ratings
        .map((rating) => (rating - mean) * (rating - mean))
        .reduce((a, b) => a + b) / ratings.length;
    
    return {
      'mean': double.parse(mean.toStringAsFixed(2)),
      'median': double.parse(median.toStringAsFixed(2)),
      'min': sortedRatings.first,
      'max': sortedRatings.last,
      'standardDeviation': double.parse((variance * variance).toStringAsFixed(2))
    };
  }

  // ============================================================================
  // HIRE SCORE UTILITIES
  // ============================================================================
  
  /// Get HIRE score interpretation
  static String getHIREScoreInterpretation(double score) {
    if (score >= 9.0) return 'Elite HIRE characteristics';
    if (score >= 8.0) return 'Strong HIRE traits';
    if (score >= 7.0) return 'Good HIRE development';
    if (score >= 6.0) return 'Average HIRE traits';
    if (score >= 5.0) return 'Below average - needs improvement';
    return 'Requires significant development';
  }
  
  /// Get coaching application advice
  static String getCoachingApplication(String applicationType, double score) {
    switch (applicationType) {
      case 'teamSelection':
        if (score >= 8.0) return 'Ideal candidate - strong character foundation';
        if (score >= 7.0) return 'Good candidate - solid HIRE development';
        if (score >= 6.0) return 'Consider with development plan';
        return 'Character concerns - needs significant work';
      
      case 'leadership':
        if (score >= 8.5) return 'Captain material - leads by example';
        if (score >= 7.5) return 'Assistant captain potential';
        if (score >= 6.5) return 'Developing leadership qualities';
        return 'Focus on personal development first';
      
      case 'development':
        if (score >= 8.0) return 'Maintain excellence, help others';
        if (score >= 7.0) return 'Continue positive trajectory';
        if (score >= 6.0) return 'Focus on specific improvement areas';
        return 'Intensive character development needed';
      
      default:
        return getHIREScoreInterpretation(score);
    }
  }
  
  /// Get recommended development actions
  static List<String> getRecommendedActions(double score) {
    if (score >= 8.0) {
      return [
        'Maintain current high standards',
        'Mentor younger players',
        'Take on leadership responsibilities',
        'Set example for team culture'
      ];
    } else if (score >= 7.0) {
      return [
        'Continue positive development trajectory',
        'Focus on consistency in all areas',
        'Seek additional leadership opportunities',
        'Help teammates with development'
      ];
    } else if (score >= 6.0) {
      return [
        'Identify 2-3 specific improvement areas',
        'Create structured development plan',
        'Regular check-ins with coaching staff',
        'Focus on character development'
      ];
    } else {
      return [
        'Intensive character development program',
        'Weekly one-on-one coaching sessions',
        'Clear expectations and accountability',
        'Address fundamental character issues'
      ];
    }
  }

  // ============================================================================
  // RATING COMPARISON UTILITIES
  // ============================================================================
  
  /// Compare two sets of ratings and return differences
  static Map<String, double> compareRatings(
    Map<String, double> baselineRatings,
    Map<String, double> currentRatings
  ) {
    final Map<String, double> differences = {};
    
    for (final key in currentRatings.keys) {
      if (baselineRatings.containsKey(key)) {
        differences[key] = currentRatings[key]! - baselineRatings[key]!;
      }
    }
    
    return differences;
  }
  
  /// Get improvement trend from rating differences
  static String getImprovementTrend(double difference) {
    if (difference >= 1.0) return 'Significant Improvement';
    if (difference >= 0.5) return 'Good Improvement';
    if (difference >= 0.1) return 'Slight Improvement';
    if (difference >= -0.1) return 'Stable';
    if (difference >= -0.5) return 'Slight Decline';
    if (difference >= -1.0) return 'Concerning Decline';
    return 'Significant Decline';
  }
  
  /// Get color for improvement trend
  static Color getImprovementTrendColor(double difference) {
    if (difference >= 0.5) return Colors.green[600]!;
    if (difference >= 0.1) return Colors.lightGreen[600]!;
    if (difference >= -0.1) return Colors.grey[600]!;
    if (difference >= -0.5) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  // ============================================================================
  // EXPORT UTILITIES
  // ============================================================================
  
  /// Get rating data formatted for export
  static Map<String, dynamic> formatForExport(
    Map<String, double> ratings,
    int playerAge,
    {bool includeDescriptions = false}
  ) {
    final Map<String, dynamic> exportData = {};
    final categories = getCategoriesForAge(playerAge);
    
    for (final category in categories) {
      final categoryData = <String, dynamic>{};
      
      for (final factor in category.factors) {
        final ratingValue = ratings[factor.key] ?? defaultRating;
        
        categoryData[factor.key] = {
          'value': ratingValue,
          'label': factor.title,
          'level': getRatingLevel(ratingValue),
          if (includeDescriptions) 'description': factor.description,
        };
      }
      
      exportData[category.title] = categoryData;
    }
    
    return exportData;
  }
  
    /// Get summary statistics for ratings
    static Map<String, double> getSummaryStatistics(List<double> values) {
    // Handle empty list to avoid division by zero
    if (values.isEmpty) {
        return {
        'mean': 0.0,
        'max': 0.0,
        'min': 0.0,
        'excellentPercentage': 0.0,
        'goodPercentage': 0.0,
        'averagePercentage': 0.0,
        'belowAveragePercentage': 0.0,
        };
    }

    // Define thresholds (adjust these based on your application's logic)
    const excellentThreshold = 80.0;
    const goodThreshold = 60.0;
    const averageThreshold = 40.0;

    // Calculate basic statistics
    final mean = values.reduce((a, b) => a + b) / values.length;
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);

    // Calculate distribution counts
    final excellentCount = values.where((v) => v >= excellentThreshold).length;
    final goodCount = values.where((v) => v >= goodThreshold && v < excellentThreshold).length;
    final averageCount = values.where((v) => v >= averageThreshold && v < goodThreshold).length;
    final belowAverageCount = values.where((v) => v < averageThreshold).length;

    // Return a Map<String, double> with statistical values
    return {
        'mean': mean,
        'max': max,
        'min': min,
        'excellentPercentage': (excellentCount / values.length * 100),
        'goodPercentage': (goodCount / values.length * 100),
        'averagePercentage': (averageCount / values.length * 100),
        'belowAveragePercentage': (belowAverageCount / values.length * 100),
    };
    }

  // ============================================================================
  // TEAM ANALYTICS UTILITIES
  // ============================================================================
  
  /// Calculate team averages from multiple player ratings
  static Map<String, double> calculateTeamAverages(List<Map<String, double>> playerRatings) {
    if (playerRatings.isEmpty) return {};
    
    final Map<String, List<double>> allRatings = {};
    
    // Collect all ratings by key
    for (final ratings in playerRatings) {
      ratings.forEach((key, value) {
        allRatings.putIfAbsent(key, () => []).add(value);
      });
    }
    
    // Calculate averages
    final Map<String, double> averages = {};
    allRatings.forEach((key, values) {
      final average = values.fold(0.0, (sum, value) => sum + value) / values.length;
      averages[key] = double.parse(average.toStringAsFixed(2));
    });
    
    return averages;
  }
  
  /// Get team insights from player ratings
  static Map<String, dynamic> getTeamInsights(List<Map<String, double>> playerRatings, int teamAge) {
    if (playerRatings.isEmpty) return {};
    
    final teamAverages = calculateTeamAverages(playerRatings);
    final teamStrengths = getTopStrengths(teamAverages, limit: 5);
    final teamWeaknesses = getImprovementAreas(teamAverages, limit: 5);
    
    return {
      'teamSize': playerRatings.length,
      'averageAge': teamAge,
      'overallAverage': calculateOverallScore(teamAverages),
      'teamStrengths': teamStrengths,
      'teamWeaknesses': teamWeaknesses,
      'categoryAverages': _getCategoryAverages(teamAverages, teamAge),
      'distributionAnalysis': getSummaryStatistics(teamAverages.values.toList()),
    };
  }
  
  static Map<String, double> _getCategoryAverages(Map<String, double> ratings, int age) {
    final categories = getCategoriesForAge(age);
    final Map<String, double> categoryAverages = {};
    
    for (final category in categories) {
      final categoryRatings = <double>[];
      for (final factor in category.factors) {
        if (ratings.containsKey(factor.key)) {
          categoryRatings.add(ratings[factor.key]!);
        }
      }
      
      if (categoryRatings.isNotEmpty) {
        final average = categoryRatings.fold(0.0, (sum, rating) => sum + rating) / categoryRatings.length;
        categoryAverages[category.title] = double.parse(average.toStringAsFixed(2));
      }
    }
    
    return categoryAverages;
  }
}