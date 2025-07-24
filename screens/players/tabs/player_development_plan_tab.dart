// lib/screens/players/tabs/player_development_plan_tab.dart - UPDATED VERSION
// Now focuses on displaying HIRE results and development planning, with input moved to HIRE Mentorship screen

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/services/development_plan_service.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/hire_rating_widgets.dart';
import 'package:hockey_shot_tracker/widgets/domain/player/development_plan_sections.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class PlayerDevelopmentPlanTab extends StatefulWidget {
  final Player player;
  final VoidCallback? onSave;

  const PlayerDevelopmentPlanTab({
    super.key,
    required this.player,
    this.onSave,
  });

  @override
  State<PlayerDevelopmentPlanTab> createState() => _PlayerDevelopmentPlanTabState();
}

class _PlayerDevelopmentPlanTabState extends State<PlayerDevelopmentPlanTab> {
  final DevelopmentPlanService _developmentPlanService = DevelopmentPlanService();
  
  // State management
  DevelopmentPlanData? _developmentPlan;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // UI controllers
  final ScrollController _scrollController = ScrollController();
  
  int get _playerId {
    final id = widget.player.id;
    if (id == null) {
      throw StateError('Player ID cannot be null');
    }
    return id;
  }

  int get _playerAge => widget.player.age ?? 16;

  @override
  void initState() {
    super.initState();
    _loadDevelopmentPlan();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================================
  // DATA LOADING & MANAGEMENT
  // ============================================================================

  Future<void> _loadDevelopmentPlan() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Loading development plan for player $_playerId');
      
      final plan = await _developmentPlanService.loadPlayerDevelopmentPlan(_playerId);
      
      if (!mounted) return;
      
      if (plan != null) {
        setState(() {
          _developmentPlan = plan;
          _isLoading = false;
        });
        debugPrint('Development plan loaded successfully');
      } else {
        final defaultPlan = _developmentPlanService.createDefaultPlanData(widget.player);
        
        setState(() {
          _developmentPlan = defaultPlan;
          _isLoading = false;
        });
        
        debugPrint('Created default development plan');
      }
    } catch (e) {
      debugPrint('Error loading development plan: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load development plan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveDevelopmentPlan() async {
    if (_developmentPlan == null || _isSaving) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      debugPrint('Saving development plan for player $_playerId');
      
      await _developmentPlanService.saveDevelopmentPlan(_developmentPlan!);
      
      if (!mounted) return;
      
      setState(() {
        _isSaving = false;
      });
      
      _showSuccessSnackBar('Development plan saved successfully');
      debugPrint('Development plan saved successfully');
      
      widget.onSave?.call();
      
    } catch (e) {
      debugPrint('Error saving development plan: $e');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to save development plan: ${e.toString()}';
        _isSaving = false;
      });
      
      _showErrorSnackBar('Failed to save development plan');
    }
  }

  // ============================================================================
  // UI BUILDING
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_developmentPlan == null) {
      return _buildEmptyState();
    }

    return _buildDevelopmentPlanContent();
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading development plan...'),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Development Plan',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDevelopmentPlan,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No Development Plan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a development plan to track player growth',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadDevelopmentPlan,
              icon: const Icon(Icons.add),
              label: const Text('Create Plan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopmentPlanContent() {
    return context.responsive<Widget>(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // ============================================================================
  // RESPONSIVE LAYOUTS
  // ============================================================================

  Widget _buildMobileLayout() {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Header with save button and navigation to HIRE Mentorship
        SliverToBoxAdapter(
          child: _buildMobileHeader(),
        ),
        
        // HIRE Scores Display (Read-only)
        SliverToBoxAdapter(
          child: _buildHIREScoresDisplay(),
        ),
        
        // Development Plan Sections
        SliverToBoxAdapter(
          child: _buildDevelopmentSections(),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content (scores display and plan sections)
        Expanded(
          flex: 3,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildTabletHeader(),
              ),
              SliverToBoxAdapter(
                child: _buildHIREScoresDisplay(),
              ),
              SliverToBoxAdapter(
                child: _buildDevelopmentSections(),
              ),
            ],
          ),
        ),
        
        // Sidebar with HIRE scores and insights
        Container(
          width: 320,
          padding: const EdgeInsets.all(16),
          child: _buildDesktopSidebar(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main content area
        Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _buildDesktopHeader(),
                ),
                SliverToBoxAdapter(
                  child: _buildHIREScoresDisplay(),
                ),
                SliverToBoxAdapter(
                  child: _buildDevelopmentSections(),
                ),
              ],
            ),
          ),
        ),
        
        // Enhanced sidebar with HIRE scores, insights, and actions
        Container(
          width: 380,
          padding: const EdgeInsets.all(16),
          child: _buildDesktopSidebar(),
        ),
      ],
    );
  }

  // ============================================================================
  // HEADER COMPONENTS
  // ============================================================================

  Widget _buildMobileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Development Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              _buildSaveButton(),
            ],
          ),
          const SizedBox(height: 8),
          _buildHIREMentorshipPrompt(),
        ],
      ),
    );
  }

  Widget _buildTabletHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Development Plan',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                _buildHIREMentorshipPrompt(),
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildGoToMentorshipButton(),
          const SizedBox(width: 8),
          _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildDesktopHeader() {
    return Container(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Development Plan - ${widget.player.name}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                _buildHIREMentorshipPrompt(),
              ],
            ),
          ),
          const SizedBox(width: 24),
          _buildDesktopActions(),
        ],
      ),
    );
  }

  Widget _buildDesktopActions() {
    return Row(
      children: [
        _buildGoToMentorshipButton(),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: _loadDevelopmentPlan,
          icon: const Icon(Icons.refresh),
          label: const Text('Refresh'),
        ),
        const SizedBox(width: 8),
        _buildSaveButton(),
      ],
    );
  }

  Widget _buildHIREMentorshipPrompt() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Update HIRE character assessment in HIRE Mentorship section',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/hire-mentorship'),
            child: const Text('Go to Mentorship'),
          ),
        ],
      ),
    );
  }

  Widget _buildGoToMentorshipButton() {
    return ElevatedButton.icon(
      onPressed: () => Navigator.pushNamed(context, '/hire-mentorship'),
      icon: const Icon(Icons.psychology),
      label: const Text('HIRE Mentorship'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  // ============================================================================
  // UI COMPONENTS
  // ============================================================================

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _isSaving ? null : _saveDevelopmentPlan,
      icon: _isSaving 
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.save),
      label: Text(_isSaving ? 'Saving...' : 'Save'),
    );
  }

  Widget _buildHIREScoresDisplay() {
    return Container(
      margin: const EdgeInsets.all(16),
      child: ResponsiveCard(
        elevation: 3,
        baseBorderRadius: 12,
        padding: ResponsiveConfig.paddingAll(context, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'HIRE Scores',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Age ${_playerAge}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Display current HIRE scores in a read-only format
            HIREScoresDisplayWidget(
              ratings: _developmentPlan!.ratings,
              playerAge: _playerAge,
            ),
            
            const SizedBox(height: 16),
            
            if (_developmentPlan!.scoresCalculatedAt != null)
              Text(
                'Last updated: ${_formatLastUpdated(_developmentPlan!.scoresCalculatedAt!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDevelopmentSections() {
    return DevelopmentPlanSections(
      plan: _developmentPlan!,
      onPlanUpdated: (updatedPlan) {
        setState(() {
          _developmentPlan = updatedPlan;
        });
      },
    );
  }

  Widget _buildDesktopSidebar() {
    return HIREScoresSidebar(
      ratings: _developmentPlan!.ratings,
      isCalculating: false, // No longer calculating here
      lastCalculated: _developmentPlan!.scoresCalculatedAt,
      onRecalculate: () => Navigator.pushNamed(context, '/hire-mentorship'),
      playerAge: _playerAge,
    );
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }
}

// NEW: Read-only widget to display HIRE scores without input capability
class HIREScoresDisplayWidget extends StatelessWidget {
  final dynamic ratings; // The ratings object from development plan
  final int playerAge;

  const HIREScoresDisplayWidget({
    super.key,
    required this.ratings,
    required this.playerAge,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Overall HIRE score display
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              Text(
                'Overall HIRE Score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(ratings.overallHIREScore * 100).toInt()}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
              Text(
                'out of 100',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Individual HIRE scores
        Row(
          children: [
            Expanded(child: _buildScoreCard('H', 'Hockey', ratings.hScore, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildScoreCard('I', 'Integrity', ratings.iScore, Colors.green)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildScoreCard('R', 'Respect', ratings.rScore, Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildScoreCard('E', 'Excellence', ratings.eScore, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildScoreCard(String letter, String title, double score, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            letter,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${(score * 100).toInt()}%',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}