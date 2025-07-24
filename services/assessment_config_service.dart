// lib/services/assessment_config_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hockey_shot_tracker/models/assessment_config.dart';

class AssessmentConfigService {
  static AssessmentConfigService? _instance;
  static AssessmentConfigService get instance => _instance ??= AssessmentConfigService._();
  
  AssessmentConfigService._();

  AssessmentConfiguration? _shotConfiguration;
  AssessmentConfiguration? _skatingConfiguration;
  bool _shotConfigLoaded = false;
  bool _skatingConfigLoaded = false;

  /// Initialize both shot and skating configurations
  static Future<void> initialize() async {
    await instance.loadShotConfiguration();
    await instance.loadSkatingConfiguration();
  }

  /// Load shot assessment configuration from assets or cache
  Future<AssessmentConfiguration> loadShotConfiguration({bool forceReload = false}) async {
    if (_shotConfigLoaded && !forceReload && _shotConfiguration != null) {
      return _shotConfiguration!;
    }

    try {
      // Load from assets/config/shot_assessments.json
      final String configString = await rootBundle.loadString('assets/config/shot_assessments.json');
      final Map<String, dynamic> configJson = jsonDecode(configString);
      
      _shotConfiguration = AssessmentConfiguration.fromJson(configJson, 'shot');
      _shotConfigLoaded = true;
      
      print('Loaded ${_shotConfiguration!.templates.length} shot assessment templates (v${_shotConfiguration!.configVersion})');
      return _shotConfiguration!;
    } catch (e) {
      print('Error loading shot assessment configuration: $e');
      
      // Fallback to default configuration if file loading fails
      _shotConfiguration = _getDefaultShotConfiguration();
      _shotConfigLoaded = true;
      
      print('Using default shot assessment configuration');
      return _shotConfiguration!;
    }
  }

  /// Debug method to comprehensively check skating configuration loading
  Future<void> debugComprehensiveSkatingTemplate() async {
    print('=== COMPREHENSIVE SKATING DEBUG ===');
    
    try {
      // Load raw JSON
      final String configString = await rootBundle.loadString('assets/config/skating_assessments.json');
      final Map<String, dynamic> configJson = jsonDecode(configString);
      
      // Find comprehensive_skating template
      final templates = configJson['assessmentTemplates'] as List;
      final comprehensiveTemplate = templates.firstWhere(
        (t) => t['id'] == 'comprehensive_skating',
        orElse: () => null,
      );
      
      if (comprehensiveTemplate != null) {
        print('✅ Found comprehensive_skating template');
        print('Total Tests in JSON: ${comprehensiveTemplate['totalTests']}');
        
        final groups = comprehensiveTemplate['groups'] as List;
        print('✅ Groups in JSON: ${groups.length}');
        
        for (int i = 0; i < groups.length; i++) {
          final group = groups[i];
          print('\n--- Group $i ---');
          print('ID: ${group['id']}');
          print('Name: ${group['name']}');
          print('Title: ${group['title']}');
          
          final tests = group['tests'] as List;
          print('Tests: ${tests.length}');
          
          for (int j = 0; j < tests.length; j++) {
            final test = tests[j];
            print('  Test $j: ${test['id']} - ${test['title']}');
          }
        }
        
        // Now test AssessmentConfiguration.fromJson
        print('\n--- Testing AssessmentConfiguration.fromJson ---');
        try {
          final config = AssessmentConfiguration.fromJson(configJson, 'skating');
          final template = config.getTemplate('comprehensive_skating');
          
          if (template != null) {
            print('✅ Template parsed successfully');
            print('Parsed Groups: ${template.groups.length}');
            print('Parsed Total Tests: ${template.totalTests}');
            
            for (int i = 0; i < template.groups.length; i++) {
              final group = template.groups[i];
              print('\nParsed Group $i: ${group.displayName}');
              print('Tests: ${group.tests?.length ?? 0}');
              
              if (group.tests != null) {
                for (var test in group.tests!) {
                  print('  - ${test.id}: ${test.title}');
                }
              }
            }
          } else {
            print('❌ Template not found after parsing');
          }
        } catch (e) {
          print('❌ AssessmentConfiguration.fromJson failed: $e');
        }
        
      } else {
        print('❌ comprehensive_skating template not found in JSON');
      }
      
    } catch (e) {
      print('❌ Debug failed: $e');
    }
    
    print('=================================');
  }

  /// Direct JSON parsing method to bypass AssessmentConfiguration issues
  Future<Map<String, Map<String, dynamic>>> getSkatingAssessmentTypesDirectParsing() async {
    print('=== USING DIRECT PARSING ===');
    
    try {
      // Load raw JSON directly
      final String configString = await rootBundle.loadString('assets/config/skating_assessments.json');
      final Map<String, dynamic> configJson = jsonDecode(configString);
      
      final Map<String, Map<String, dynamic>> result = {};
      
      if (configJson.containsKey('assessmentTemplates')) {
        final templates = configJson['assessmentTemplates'] as List;
        
        for (final templateData in templates) {
          final template = templateData as Map<String, dynamic>;
          final templateId = template['id'] as String;
          
          // Skip mini templates for main UI selection
          if (template.containsKey('isMini') && template['isMini'] == true) continue;
          
          print('Processing template: $templateId');
          print('  JSON Total Tests: ${template['totalTests']}');
          print('  JSON Groups: ${(template['groups'] as List).length}');
          
          // Process groups
          final processedGroups = <Map<String, dynamic>>[];
          final jsonGroups = template['groups'] as List;
          
          for (int i = 0; i < jsonGroups.length; i++) {
            final group = jsonGroups[i] as Map<String, dynamic>;
            final groupTests = group['tests'] as List;
            
            print('  Group $i: ${group['name']} (${groupTests.length} tests)');
            
            final processedTests = groupTests.map((testData) {
              final test = testData as Map<String, dynamic>;
              print('    - ${test['id']}: ${test['title']}');
              
              return {
                'id': test['id'],
                'title': test['title'],
                'description': test['description'],
                'category': test['category'],
                'instructions': test['instructions'],
                'benchmarks': test['benchmarks'],
                'equipment': test['equipment'],
                'duration': test['duration'],
              };
            }).toList();
            
            processedGroups.add({
              'id': group['id'],
              'title': group['title'] ?? group['name'],
              'name': group['name'] ?? group['title'],
              'description': group['description'],
              'tests': processedTests,
            });
          }
          
          // Calculate total tests from processed groups
          final calculatedTotalTests = processedGroups.fold<int>(
            0, 
            (sum, group) => sum + (group['tests'] as List).length
          );
          
          print('  Calculated Total Tests: $calculatedTotalTests');
          
          result[templateId] = {
            'title': template['title'],
            'description': template['description'],
            'category': template['category'],
            'estimatedDurationMinutes': template['estimatedDurationMinutes'],
            'totalTests': calculatedTotalTests, // Use calculated value
            'groups': processedGroups,
            'metadata': template['metadata'] ?? {},
          };
        }
      }
      
      print('=== DIRECT PARSING COMPLETE ===');
      return result;
    } catch (e) {
      print('❌ Direct parsing failed: $e');
      rethrow;
    }
  }

  /// Get skating templates for UI display with fallback to direct parsing
  Future<Map<String, Map<String, dynamic>>> getSkatingAssessmentTypesForUIWithFallback() async {
    try {
      // Try the normal method first
      final normalResult = await getSkatingAssessmentTypesForUI();
      
      // Check if comprehensive_skating has all 6 tests
      final comprehensive = normalResult['comprehensive_skating'];
      if (comprehensive != null) {
        final groups = comprehensive['groups'] as List;
        final totalTests = groups.fold<int>(0, (sum, group) => sum + (group['tests'] as List).length);
        
        if (totalTests == 6) {
          print('✅ Normal parsing worked: $totalTests tests found');
          return normalResult;
        } else {
          print('⚠️ Normal parsing incomplete: only $totalTests tests found, expected 6');
        }
      }
      
      // Fall back to direct parsing
      print('🔄 Falling back to direct parsing...');
      return await getSkatingAssessmentTypesDirectParsing();
      
    } catch (e) {
      print('❌ Normal parsing failed: $e');
      print('🔄 Using direct parsing...');
      return await getSkatingAssessmentTypesDirectParsing();
    }
  }

  /// Get benchmarks for a specific test, age group, and position
  Future<Map<String, dynamic>> getBenchmarksForTest(String testId, String ageGroup, String position) async {
    try {
      // Load the skating configuration to get age-specific benchmarks
      final String configString = await rootBundle.loadString('assets/config/skating_assessments.json');
      final Map<String, dynamic> configJson = jsonDecode(configString);
      
      // Check if we have age-specific benchmarks
      if (configJson.containsKey('ageBenchmarks')) {
        final ageBenchmarks = configJson['ageBenchmarks'] as Map<String, dynamic>;
        
        if (ageBenchmarks.containsKey(ageGroup)) {
          final ageGroupBenchmarks = ageBenchmarks[ageGroup] as Map<String, dynamic>;
          
          if (ageGroupBenchmarks.containsKey(testId)) {
            var benchmarks = Map<String, dynamic>.from(ageGroupBenchmarks[testId] as Map<String, dynamic>);
            
            // Apply skill level adjustments if they exist
            if (ageGroupBenchmarks.containsKey('skillLevelAdjustments')) {
              final adjustments = ageGroupBenchmarks['skillLevelAdjustments'] as Map<String, dynamic>;
              // You could apply adjustments here based on player skill level
            }
            
            // Apply gender adjustments if they exist
            if (ageGroupBenchmarks.containsKey('genderAdjustments')) {
              final genderAdjustments = ageGroupBenchmarks['genderAdjustments'] as Map<String, dynamic>;
              // You could apply gender adjustments here
            }
            
            print('✅ Found benchmarks for $testId in $ageGroup: $benchmarks');
            return benchmarks;
          }
        }
      }
      
      // Fallback to template-level benchmarks
      final templates = configJson['assessmentTemplates'] as List;
      for (final template in templates) {
        final groups = template['groups'] as List;
        for (final group in groups) {
          final tests = group['tests'] as List;
          for (final test in tests) {
            if (test['id'] == testId && test.containsKey('benchmarks')) {
              final benchmarks = Map<String, dynamic>.from(test['benchmarks'] as Map<String, dynamic>);
              print('✅ Found template benchmarks for $testId: $benchmarks');
              return benchmarks;
            }
          }
        }
      }
      
      print('⚠️ No benchmarks found for $testId in $ageGroup, using fallback');
      return _getFallbackBenchmarks(testId, ageGroup);
      
    } catch (e) {
      print('❌ Error getting benchmarks for $testId: $e');
      return _getFallbackBenchmarks(testId, ageGroup);
    }
  }

  /// Fallback benchmarks based on the JSON data provided
  Map<String, dynamic> _getFallbackBenchmarks(String testId, String ageGroup) {
    const benchmarkData = {
      'youth_8_10': {
        'forward_speed_test': {'Elite': 5.8, 'Advanced': 6.2, 'Developing': 6.6, 'Beginner': 7.2},
        'backward_speed_test': {'Elite': 6.8, 'Advanced': 7.4, 'Developing': 8.0, 'Beginner': 8.8},
        'agility_test': {'Elite': 15.0, 'Advanced': 16.5, 'Developing': 18.0, 'Beginner': 20.0},
        'transitions_test': {'Elite': 6.0, 'Advanced': 6.5, 'Developing': 7.0, 'Beginner': 7.8},
        'crossovers_test': {'Elite': 12.0, 'Advanced': 13.5, 'Developing': 15.0, 'Beginner': 17.0},
        'stop_start_test': {'Elite': 3.2, 'Advanced': 3.5, 'Developing': 3.8, 'Beginner': 4.2},
      },
      'youth_11_14': {
        'forward_speed_test': {'Elite': 4.7, 'Advanced': 5.1, 'Developing': 5.5, 'Beginner': 6.0},
        'backward_speed_test': {'Elite': 5.8, 'Advanced': 6.3, 'Developing': 6.8, 'Beginner': 7.4},
        'agility_test': {'Elite': 11.5, 'Advanced': 12.5, 'Developing': 13.8, 'Beginner': 15.2},
        'transitions_test': {'Elite': 5.0, 'Advanced': 5.5, 'Developing': 6.0, 'Beginner': 6.7},
        'crossovers_test': {'Elite': 9.5, 'Advanced': 10.5, 'Developing': 11.8, 'Beginner': 13.2},
        'stop_start_test': {'Elite': 2.7, 'Advanced': 2.9, 'Developing': 3.2, 'Beginner': 3.6},
      },
      'youth_15_18': {
        'forward_speed_test': {'Elite': 4.2, 'Advanced': 4.5, 'Developing': 4.8, 'Beginner': 5.2},
        'backward_speed_test': {'Elite': 5.2, 'Advanced': 5.6, 'Developing': 6.0, 'Beginner': 6.5},
        'agility_test': {'Elite': 9.0, 'Advanced': 9.8, 'Developing': 10.6, 'Beginner': 11.8},
        'transitions_test': {'Elite': 4.2, 'Advanced': 4.6, 'Developing': 5.0, 'Beginner': 5.5},
        'crossovers_test': {'Elite': 7.8, 'Advanced': 8.5, 'Developing': 9.3, 'Beginner': 10.2},
        'stop_start_test': {'Elite': 2.3, 'Advanced': 2.5, 'Developing': 2.8, 'Beginner': 3.2},
      },
      'adult': {
        'forward_speed_test': {'Elite': 3.9, 'Advanced': 4.2, 'Developing': 4.5, 'Beginner': 4.9},
        'backward_speed_test': {'Elite': 4.8, 'Advanced': 5.2, 'Developing': 5.6, 'Beginner': 6.2},
        'agility_test': {'Elite': 8.3, 'Advanced': 9.0, 'Developing': 9.8, 'Beginner': 10.8},
        'transitions_test': {'Elite': 3.8, 'Advanced': 4.2, 'Developing': 4.6, 'Beginner': 5.2},
        'crossovers_test': {'Elite': 7.2, 'Advanced': 7.8, 'Developing': 8.5, 'Beginner': 9.4},
        'stop_start_test': {'Elite': 2.0, 'Advanced': 2.2, 'Developing': 2.5, 'Beginner': 2.9},
      },
    };
    
    return benchmarkData[ageGroup]?[testId] ?? {
      'Elite': 4.0, 'Advanced': 4.5, 'Developing': 5.0, 'Beginner': 5.5
    };
  }

  /// Enhanced version that ensures benchmarks are included in UI data
  Future<Map<String, Map<String, dynamic>>> getSkatingAssessmentTypesForUIWithBenchmarks({
    String ageGroup = 'youth_15_18',
    String position = 'forward',
  }) async {
    try {
      // Get the basic assessment types
      final assessmentTypes = await getSkatingAssessmentTypesForUIWithFallback();
      
      // Enhance each test with proper benchmarks
      final Map<String, Map<String, dynamic>> enhancedTypes = {};
      
      for (final entry in assessmentTypes.entries) {
        final templateId = entry.key;
        final templateData = Map<String, dynamic>.from(entry.value);
        
        // Process groups to add benchmarks
        final groups = List<Map<String, dynamic>>.from(templateData['groups'] as List);
        final enhancedGroups = <Map<String, dynamic>>[];
        
        for (final group in groups) {
          final groupCopy = Map<String, dynamic>.from(group);
          final tests = List<Map<String, dynamic>>.from(group['tests'] as List);
          final enhancedTests = <Map<String, dynamic>>[];
          
          for (final test in tests) {
            final testCopy = Map<String, dynamic>.from(test);
            final testId = testCopy['id'] as String;
            
            // Get benchmarks for this specific test
            final benchmarks = await getBenchmarksForTest(testId, ageGroup, position);
            testCopy['benchmarks'] = benchmarks;
            
            print('Enhanced test $testId with benchmarks: $benchmarks');
            enhancedTests.add(testCopy);
          }
          
          groupCopy['tests'] = enhancedTests;
          enhancedGroups.add(groupCopy);
        }
        
        templateData['groups'] = enhancedGroups;
        enhancedTypes[templateId] = templateData;
      }
      
      print('✅ Enhanced ${enhancedTypes.length} assessment types with benchmarks');
      return enhancedTypes;
      
    } catch (e) {
      print('❌ Error enhancing assessment types with benchmarks: $e');
      // Fall back to regular method
      return await getSkatingAssessmentTypesForUIWithFallback();
    }
  }

  /// Load skating assessment configuration with detailed error handling
  Future<AssessmentConfiguration> loadSkatingConfigurationWithDebug({bool forceReload = false}) async {
    print('=== DETAILED SKATING CONFIG DEBUG ===');
    
    try {
      // Load raw JSON
      final String configString = await rootBundle.loadString('assets/config/skating_assessments.json');
      print('✅ Raw JSON loaded: ${configString.length} characters');
      print('First 200 chars: ${configString.substring(0, 200)}...');
      
      // Parse JSON step by step
      final Map<String, dynamic> configJson = jsonDecode(configString);
      print('✅ JSON parsed successfully');
      print('Top-level keys: ${configJson.keys.toList()}');
      
      // Check specific structure
      if (configJson.containsKey('assessmentTemplates')) {
        final templates = configJson['assessmentTemplates'];
        print('✅ assessmentTemplates key found, type: ${templates.runtimeType}');
        
        if (templates is List) {
          print('✅ assessmentTemplates is a List with ${templates.length} items');
          
          for (int i = 0; i < templates.length; i++) {
            final template = templates[i];
            print('Template $i type: ${template.runtimeType}');
            
            if (template is Map<String, dynamic>) {
              print('  ID: ${template['id']}');
              print('  Title: ${template['title']}');
              print('  Groups key exists: ${template.containsKey('groups')}');
              
              if (template.containsKey('groups')) {
                final groups = template['groups'];
                print('  Groups type: ${groups.runtimeType}');
                
                if (groups is List) {
                  print('  Groups count: ${groups.length}');
                  
                  for (int j = 0; j < groups.length; j++) {
                    final group = groups[j];
                    print('    Group $j type: ${group.runtimeType}');
                    
                    if (group is Map<String, dynamic>) {
                      print('      Name: ${group['name']}');
                      print('      Tests key exists: ${group.containsKey('tests')}');
                      
                      if (group.containsKey('tests')) {
                        final tests = group['tests'];
                        print('      Tests type: ${tests.runtimeType}');
                        
                        if (tests is List) {
                          print('      Tests count: ${tests.length}');
                        } else {
                          print('      ❌ Tests is not a List!');
                        }
                      }
                    }
                  }
                } else {
                  print('  ❌ Groups is not a List!');
                }
              }
            }
          }
        } else {
          print('❌ assessmentTemplates is not a List! Type: ${templates.runtimeType}');
        }
      } else {
        print('❌ No assessmentTemplates key found');
      }
      
      // Now try the problematic parsing
      print('\n--- Attempting AssessmentConfiguration.fromJson ---');
      final config = AssessmentConfiguration.fromJson(configJson, 'skating');
      print('✅ AssessmentConfiguration created successfully');
      
      return config;
      
    } catch (e, stackTrace) {
      print('❌ Error in loadSkatingConfigurationWithDebug: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Load skating assessment configuration from assets or cache
  Future<AssessmentConfiguration> loadSkatingConfiguration({bool forceReload = false}) async {
    if (_skatingConfigLoaded && !forceReload && _skatingConfiguration != null) {
      return _skatingConfiguration!;
    }

    try {
      // Use the debug version to see exactly what's happening
      final config = await loadSkatingConfigurationWithDebug(forceReload: forceReload);
      
      _skatingConfiguration = config;
      _skatingConfigLoaded = true;
      
      print('Loaded ${_skatingConfiguration!.templates.length} skating assessment templates (v${_skatingConfiguration!.configVersion})');
      return _skatingConfiguration!;
    } catch (e) {
      print('Error loading skating assessment configuration: $e');
      
      // Fallback to default configuration if file loading fails
      _skatingConfiguration = _getDefaultSkatingConfiguration();
      _skatingConfigLoaded = true;
      
      print('Using default skating assessment configuration');
      return _skatingConfiguration!;
    }
  }

  // =============================================================================
  // SHOT ASSESSMENT METHODS
  // =============================================================================

  /// Get all available shot assessment templates
  Future<List<AssessmentTemplate>> getShotTemplates() async {
    final config = await loadShotConfiguration();
    return config.templates;
  }

  /// Get shot assessment template by ID
  Future<AssessmentTemplate?> getShotTemplate(String id) async {
    final config = await loadShotConfiguration();
    return config.getTemplate(id);
  }

  /// Get shot templates by category
  Future<List<AssessmentTemplate>> getShotTemplatesByCategory(String category) async {
    final config = await loadShotConfiguration();
    return config.getTemplatesByCategory(category);
  }

  /// Get shot templates grouped by category for UI display
  Future<Map<String, List<AssessmentTemplate>>> getShotTemplatesGroupedByCategory() async {
    final config = await loadShotConfiguration();
    return config.getTemplatesGroupedByCategory();
  }

  /// Get shot templates formatted for the current UI (backward compatibility)
  Future<Map<String, Map<String, dynamic>>> getShotAssessmentTypesForUI() async {
    final templates = await getShotTemplates();
    final Map<String, Map<String, dynamic>> result = {};

    for (final template in templates) {
      result[template.id] = {
        'title': template.displayTitle,
        'description': template.displayDescription,
        'category': template.category,
        'estimatedDuration': template.estimatedDurationMinutes,
        'totalShots': template.totalShots,
        'groups': template.groups.map((group) => {
          'id': group.id,
          'title': group.title,
          'shots': group.shots,
          'defaultType': group.defaultType,
          'location': group.location,
          'instructions': group.instructions,
          'allowedShotTypes': group.allowedShotTypes,
          'targetZones': group.targetZones,
          'parameters': group.parameters,
        }).toList(),
      };
    }

    return result;
  }

  // =============================================================================
  // SKATING ASSESSMENT METHODS
  // =============================================================================

  /// Get all available skating assessment templates
  Future<List<AssessmentTemplate>> getSkatingTemplates() async {
    final config = await loadSkatingConfiguration();
    return config.templates;
  }

  /// Get skating assessment template by ID
  Future<AssessmentTemplate?> getSkatingTemplate(String id) async {
    final config = await loadSkatingConfiguration();
    return config.getTemplate(id);
  }

  /// Get skating templates by category
  Future<List<AssessmentTemplate>> getSkatingTemplatesByCategory(String category) async {
    final config = await loadSkatingConfiguration();
    return config.getTemplatesByCategory(category);
  }

  /// Get skating templates grouped by category
  Future<Map<String, List<AssessmentTemplate>>> getSkatingTemplatesGroupedByCategory() async {
    final config = await loadSkatingConfiguration();
    return config.getTemplatesGroupedByCategory();
  }

  /// Get skating templates for UI display (exclude mini templates)
  Future<Map<String, Map<String, dynamic>>> getSkatingAssessmentTypesForUI() async {
    final templates = await getSkatingTemplates();
    final Map<String, Map<String, dynamic>> result = {};
    
    for (final template in templates) {
      // Skip mini templates for main UI selection
      if (template.isMini) continue;
      
      result[template.id] = {
        'title': template.title,
        'description': template.description,
        'category': template.category,
        'estimatedDurationMinutes': template.estimatedDurationMinutes,
        'totalTests': template.totalTests,
        'groups': template.groups.map((group) => {
          'id': group.id,
          'title': group.displayName, // Use displayName which handles both name and title
          'name': group.displayName,
          'description': group.description,
          'tests': group.tests?.map((test) => {
            'id': test.id,
            'title': test.title,
            'description': test.description,
            'category': test.category,
            'instructions': test.instructions,
            'benchmarks': test.benchmarks,
            'equipment': test.equipment,
            'duration': test.duration,
          }).toList() ?? [],
        }).toList(),
        'metadata': template.metadata,
      };
    }
    
    return result;
  }

  /// Convert skating template to assessment structure for execution
  Future<Map<String, dynamic>> convertSkatingTemplateToAssessment(
    String templateId, {
    required String selectedPlayer,
    required String position,
    required String ageGroup,
  }) async {
    final template = await getSkatingTemplate(templateId);
    if (template == null) {
      throw Exception('Skating template not found: $templateId');
    }

    return {
      'id': template.id,
      'title': template.title,
      'type': template.category,
      'description': template.description,
      'position': position,
      'ageGroup': ageGroup,
      'playerName': selectedPlayer,
      'date': DateTime.now().toIso8601String(),
      'estimatedDurationMinutes': template.estimatedDurationMinutes,
      'totalTests': template.totalTests,
      'groups': template.groups.map((group) => {
        'id': group.id,
        'title': group.displayName, // Use displayName which handles both name and title
        'name': group.displayName,
        'description': group.description,
        'tests': group.tests?.map((test) => {
          'id': test.id,
          'title': test.title,
          'description': test.description,
          'category': test.category,
          'instructions': test.instructions,
          'benchmarks': test.benchmarks,
          'equipment': test.equipment,
          'duration': test.duration,
        }).toList() ?? [],
      }).toList(),
      'metadata': template.metadata,
    };
  }

  /// Get comprehensive skating templates
  Future<List<AssessmentTemplate>> getComprehensiveSkatingTemplates() async {
    return await getSkatingTemplatesByCategory('comprehensive');
  }

  /// Get quick skating templates
  Future<List<AssessmentTemplate>> getQuickSkatingTemplates() async {
    return await getSkatingTemplatesByCategory('quick');
  }

  /// Get focused skating templates
  Future<List<AssessmentTemplate>> getFocusedSkatingTemplates() async {
    return await getSkatingTemplatesByCategory('focused');
  }

  /// Get mini skating templates
  Future<List<AssessmentTemplate>> getMiniSkatingTemplates() async {
    return await getSkatingTemplatesByCategory('mini');
  }

  /// Get available skating test categories across all templates
  Future<List<String>> getAvailableSkatingTestCategories() async {
    final config = await loadSkatingConfiguration();
    return config.availableTestCategories;
  }

  /// Get skating templates by difficulty level
  Future<List<AssessmentTemplate>> getSkatingTemplatesByDifficulty(String difficulty) async {
    final templates = await getSkatingTemplates();
    return templates.where((template) {
      return template.difficultyLevel == difficulty;
    }).toList();
  }

  /// Get skating templates by focus area
  Future<List<AssessmentTemplate>> getSkatingTemplatesByFocus(String focus) async {
    final templates = await getSkatingTemplates();
    return templates.where((template) {
      return template.focusArea.contains(focus.toLowerCase());
    }).toList();
  }

  /// Get skating template recommendations based on player characteristics
  Future<List<AssessmentTemplate>> getRecommendedSkatingTemplates({
    String? position,
    String? ageGroup,
    String? focusArea,
    int? availableTimeMinutes,
  }) async {
    var templates = await getSkatingTemplates();
    
    // Filter by time if specified
    if (availableTimeMinutes != null) {
      templates = templates.where((t) => 
        t.estimatedDurationMinutes <= availableTimeMinutes
      ).toList();
    }
    
    // Filter by focus area if specified
    if (focusArea != null) {
      templates = templates.where((t) => 
        t.focusArea.toLowerCase().contains(focusArea.toLowerCase()) ||
        t.recommendedFor.any((r) => r.toLowerCase().contains(focusArea.toLowerCase()))
      ).toList();
    }
    
    // Sort by relevance (comprehensive first, then by duration)
    templates.sort((a, b) {
      if (a.isComprehensive && !b.isComprehensive) return -1;
      if (!a.isComprehensive && b.isComprehensive) return 1;
      return a.estimatedDurationMinutes.compareTo(b.estimatedDurationMinutes);
    });
    
    return templates;
  }

  // =============================================================================
  // GENERAL METHODS
  // =============================================================================

  /// Get all templates (both shot and skating)
  Future<List<AssessmentTemplate>> getAllTemplates() async {
    final shotTemplates = await getShotTemplates();
    final skatingTemplates = await getSkatingTemplates();
    return [...shotTemplates, ...skatingTemplates];
  }

  /// Get template by ID (searches both shot and skating)
  Future<AssessmentTemplate?> getTemplate(String id) async {
    // Try shot templates first
    var template = await getShotTemplate(id);
    if (template != null) return template;
    
    // Try skating templates
    return await getSkatingTemplate(id);
  }

  /// Get templates by category (searches both shot and skating)
  Future<List<AssessmentTemplate>> getTemplatesByCategory(String category) async {
    final shotTemplates = await getShotTemplatesByCategory(category);
    final skatingTemplates = await getSkatingTemplatesByCategory(category);
    return [...shotTemplates, ...skatingTemplates];
  }

  /// Get templates grouped by category for UI display
  Future<Map<String, List<AssessmentTemplate>>> getTemplatesGroupedByCategory() async {
    final shotTemplates = await getShotTemplatesGroupedByCategory();
    final skatingTemplates = await getSkatingTemplatesGroupedByCategory();
    
    final Map<String, List<AssessmentTemplate>> combined = {};
    
    // Add shot templates
    shotTemplates.forEach((category, templates) {
      combined.putIfAbsent(category, () => []).addAll(templates);
    });
    
    // Add skating templates
    skatingTemplates.forEach((category, templates) {
      combined.putIfAbsent(category, () => []).addAll(templates);
    });
    
    return combined;
  }

  /// Get global settings for shot assessments
  Future<Map<String, dynamic>> getShotGlobalSettings() async {
    final config = await loadShotConfiguration();
    return config.globalSettings;
  }

  /// Get global settings for skating assessments
  Future<Map<String, dynamic>> getSkatingGlobalSettings() async {
    final config = await loadSkatingConfiguration();
    return config.globalSettings;
  }

  /// Get age groups from skating configuration
  Future<List<String>> getAgeGroups() async {
    final config = await loadSkatingConfiguration();
    return config.ageGroups;
  }

  /// Get default categories from skating configuration
  Future<List<String>> getDefaultSkatingCategories() async {
    final config = await loadSkatingConfiguration();
    return config.defaultCategories;
  }

  /// Validate a template configuration
  bool validateTemplate(AssessmentTemplate template) {
    // Basic validation
    if (template.title.isEmpty || template.groups.isEmpty) {
      return false;
    }

    if (template.isShotAssessment) {
      // Check if total shots calculation is correct
      final calculatedTotal = template.groups.fold(0, (sum, group) => sum + (group.shots ?? 0));
      if (calculatedTotal != template.totalShots) {
        print('Warning: Shot template ${template.id} total shots mismatch. Calculated: $calculatedTotal, Stored: ${template.totalShots}');
      }

      // Validate each group
      for (final group in template.groups) {
        if (group.title.isEmpty || (group.shots ?? 0) <= 0) {
          return false;
        }
      }
    } else {
      // Skating assessment validation
      final calculatedTotal = template.groups.fold(0, (sum, group) => sum + (group.tests?.length ?? 0));
      if (calculatedTotal != template.totalTests) {
        print('Warning: Skating template ${template.id} total tests mismatch. Calculated: $calculatedTotal, Stored: ${template.totalTests}');
      }

      // Validate each group
      for (final group in template.groups) {
        if (group.name.isEmpty && group.title.isEmpty) {
          return false;
        }
        if (group.tests == null || group.tests!.isEmpty) {
          return false;
        }
      }
    }

    return true;
  }

  /// Validate both configurations
  Future<bool> validateConfigurations() async {
    try {
      final shotConfig = await loadShotConfiguration();
      final skatingConfig = await loadSkatingConfiguration();
      
      // Check basic structure
      if (shotConfig.templates.isEmpty || skatingConfig.templates.isEmpty) return false;
      
      // Validate each template
      for (final template in shotConfig.templates) {
        if (!validateTemplate(template)) return false;
      }
      
      for (final template in skatingConfig.templates) {
        if (!validateTemplate(template)) return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Clear cached configurations (useful for testing or reloading)
  void clearCache() {
    _shotConfiguration = null;
    _skatingConfiguration = null;
    _shotConfigLoaded = false;
    _skatingConfigLoaded = false;
  }

  /// Force reload configurations
  Future<void> reload() async {
    clearCache();
    await initialize();
  }

  /// Get configuration metadata
  Future<Map<String, dynamic>> getConfigurationInfo() async {
    final shotConfig = await loadShotConfiguration();
    final skatingConfig = await loadSkatingConfiguration();
    
    return {
      'shot': {
        'version': shotConfig.configVersion,
        'lastUpdated': shotConfig.lastUpdated.toIso8601String(),
        'templateCount': shotConfig.templates.length,
        'categories': shotConfig.getTemplatesGroupedByCategory().keys.toList(),
      },
      'skating': {
        'version': skatingConfig.configVersion,
        'lastUpdated': skatingConfig.lastUpdated.toIso8601String(),
        'templateCount': skatingConfig.templates.length,
        'categories': skatingConfig.getTemplatesGroupedByCategory().keys.toList(),
      },
    };
  }

  // =============================================================================
  // FALLBACK/DEFAULT CONFIGURATIONS
  // =============================================================================

  /// Create default shot configuration as fallback
  AssessmentConfiguration _getDefaultShotConfiguration() {
    return AssessmentConfiguration(
      configVersion: '1.0.0',
      lastUpdated: DateTime.now(),
      type: 'shot',
      globalSettings: {
        'maxShotsPerGroup': 30,
        'maxGroupsPerAssessment': 10,
        'defaultShotTypes': ['Wrist Shot', 'Snap Shot', 'Slap Shot', 'Backhand'],
        'defaultZones': ['1', '2', '3', '4', '5', '6', '7', '8', '9'],
      },
      templates: [
        AssessmentTemplate(
          id: 'accuracy_precision_100',
          title: 'Accuracy Precision Test',
          description: 'Comprehensive directional accuracy assessment',
          category: 'comprehensive',
          estimatedDurationMinutes: 30,
          totalShots: 100,
          type: 'shot',
          groups: [
            AssessmentGroup(
              id: '0',
              title: 'Right Side Precision',
              shots: 25,
              defaultType: 'Wrist Shot',
              location: 'Slot',
              instructions: 'Target the right side of the net.',
              allowedShotTypes: ['Wrist Shot', 'Snap Shot'],
              targetZones: ['3', '6', '9'],
            ),
            AssessmentGroup(
              id: '1',
              title: 'Left Side Precision',
              shots: 25,
              defaultType: 'Wrist Shot',
              location: 'Slot',
              instructions: 'Target the left side of the net.',
              allowedShotTypes: ['Wrist Shot', 'Snap Shot'],
              targetZones: ['1', '4', '7'],
            ),
            AssessmentGroup(
              id: '2',
              title: 'Center Line Targeting',
              shots: 25,
              defaultType: 'Wrist Shot',
              location: 'Slot',
              instructions: 'Target the center line of the net.',
              allowedShotTypes: ['Wrist Shot', 'Snap Shot'],
              targetZones: ['2', '5', '8'],
            ),
            AssessmentGroup(
              id: '3',
              title: 'High Corner Precision',
              shots: 25,
              defaultType: 'Wrist Shot',
              location: 'Slot',
              instructions: 'Target the top shelf of the net.',
              allowedShotTypes: ['Wrist Shot', 'Snap Shot'],
              targetZones: ['1', '2', '3'],
            ),
          ],
        ),
      ],
    );
  }

  /// Create default skating configuration as fallback
  AssessmentConfiguration _getDefaultSkatingConfiguration() {
    return AssessmentConfiguration(
      configVersion: '1.0.0',
      lastUpdated: DateTime.now(),
      type: 'skating',
      globalSettings: {
        'maxTestsPerGroup': 10,
        'maxGroupsPerAssessment': 5,
        'defaultCategories': ['Speed', 'Agility', 'Technique'],
        'ageGroups': ['youth_8_10', 'youth_11_14', 'youth_15_18', 'adult'],
        'estimatedTimePerTest': 60,
      },
      templates: [
        AssessmentTemplate(
          id: 'comprehensive_skating',
          title: 'Comprehensive Skating Assessment',
          description: 'Full assessment of speed, agility, and technical skills',
          category: 'comprehensive',
          estimatedDurationMinutes: 25,
          totalTests: 5,
          type: 'skating',
          groups: [
            AssessmentGroup(
              id: 'speed_tests',
              title: 'Speed Tests',
              name: 'Speed Tests',
              description: 'Evaluate straight-line skating speed',
              tests: [
                AssessmentTest(
                  id: 'forward_speed_test',
                  title: 'Forward Speed Test',
                  description: 'Skate forward from blue line to blue line at maximum speed',
                  category: 'Speed',
                  instructions: 'Start at the blue line, skate forward at maximum speed to the opposite blue line.',
                  benchmarks: {'Excellent': 3.2, 'Good': 3.8, 'Average': 4.5, 'Below Average': 5.2},
                ),
                AssessmentTest(
                  id: 'backward_speed_test',
                  title: 'Backward Speed Test',
                  description: 'Skate backward from blue line to blue line at maximum speed',
                  category: 'Speed',
                  instructions: 'Start at the blue line facing backwards, skate backward at maximum speed to the opposite blue line.',
                  benchmarks: {'Excellent': 4.0, 'Good': 4.6, 'Average': 5.4, 'Below Average': 6.1},
                ),
              ],
            ),
            AssessmentGroup(
              id: 'agility_tests',
              title: 'Agility Tests',
              name: 'Agility Tests',
              description: 'Evaluate maneuverability and direction changes',
              tests: [
                AssessmentTest(
                  id: 'agility_test',
                  title: 'Agility Test',
                  description: 'Complete figure-8 pattern around cones at maximum speed',
                  category: 'Agility',
                  instructions: 'Navigate through the cone setup in a figure-8 pattern, maintaining speed and control.',
                  benchmarks: {'Excellent': 7.5, 'Good': 8.3, 'Average': 9.2, 'Below Average': 10.1},
                ),
              ],
            ),
          ],
        ),
        AssessmentTemplate(
          id: 'quick_skating',
          title: 'Quick Skating Assessment',
          description: 'Brief assessment of key skating skills',
          category: 'quick',
          estimatedDurationMinutes: 8,
          totalTests: 2,
          type: 'skating',
          groups: [
            AssessmentGroup(
              id: 'quick_assessment',
              title: 'Quick Assessment',
              name: 'Quick Assessment',
              description: 'Essential skating abilities',
              tests: [
                AssessmentTest(
                  id: 'forward_speed_test',
                  title: 'Forward Speed Test',
                  description: 'Basic forward speed evaluation',
                  category: 'Speed',
                  instructions: 'Start at the blue line, skate forward at maximum speed to the opposite blue line.',
                  benchmarks: {'Excellent': 3.2, 'Good': 3.8, 'Average': 4.5, 'Below Average': 5.2},
                ),
                AssessmentTest(
                  id: 'agility_test',
                  title: 'Agility Test',
                  description: 'Basic agility evaluation',
                  category: 'Agility',
                  instructions: 'Navigate through the cone setup in a figure-8 pattern, maintaining speed and control.',
                  benchmarks: {'Excellent': 7.5, 'Good': 8.3, 'Average': 9.2, 'Below Average': 10.1},
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // =============================================================================
  // BACKWARD COMPATIBILITY METHODS (for existing shot assessment code)
  // =============================================================================

  /// Get all available assessment templates (shot assessments only - for backward compatibility)
  Future<List<AssessmentTemplate>> getTemplates() async {
    return await getShotTemplates();
  }

  /// Get shot templates formatted for the current UI (backward compatibility)
  Future<Map<String, Map<String, dynamic>>> getAssessmentTypesForUI() async {
    return await getShotAssessmentTypesForUI();
  }

  /// Get global settings (shot assessments - for backward compatibility)
  Future<Map<String, dynamic>> getGlobalSettings() async {
    return await getShotGlobalSettings();
  }

  /// Load configuration (shot assessments - for backward compatibility)
  Future<AssessmentConfiguration> loadConfiguration({bool forceReload = false}) async {
    return await loadShotConfiguration(forceReload: forceReload);
  }
}