// lib/widgets/domain/player/development_plan_sections.dart

import 'package:flutter/material.dart';
import 'package:hockey_shot_tracker/models/development_plan.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';

class DevelopmentPlanSections extends StatefulWidget {
  final DevelopmentPlanData plan;
  final Function(DevelopmentPlanData) onPlanUpdated;

  const DevelopmentPlanSections({
    super.key,
    required this.plan,
    required this.onPlanUpdated,
  });

  @override
  State<DevelopmentPlanSections> createState() => _DevelopmentPlanSectionsState();
}

class _DevelopmentPlanSectionsState extends State<DevelopmentPlanSections> {
  late TextEditingController _coachNotesController;
  late TextEditingController _playerNotesController;
  late TextEditingController _coachNameController;
  late TextEditingController _coachEmailController;
  late TextEditingController _coachPhoneController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  void _initializeControllers() {
    _coachNotesController = TextEditingController(text: widget.plan.meetingNotes.coachNotes);
    _playerNotesController = TextEditingController(text: widget.plan.meetingNotes.playerNotes);
    _coachNameController = TextEditingController(text: widget.plan.coachContact.name);
    _coachEmailController = TextEditingController(text: widget.plan.coachContact.email);
    _coachPhoneController = TextEditingController(text: widget.plan.coachContact.phone);

    // Add listeners for auto-save
    _coachNotesController.addListener(_onCoachNotesChanged);
    _playerNotesController.addListener(_onPlayerNotesChanged);
    _coachNameController.addListener(_onCoachContactChanged);
    _coachEmailController.addListener(_onCoachContactChanged);
    _coachPhoneController.addListener(_onCoachContactChanged);
  }

  void _disposeControllers() {
    _coachNotesController.dispose();
    _playerNotesController.dispose();
    _coachNameController.dispose();
    _coachEmailController.dispose();
    _coachPhoneController.dispose();
  }

  void _onCoachNotesChanged() {
    widget.plan.meetingNotes.coachNotes = _coachNotesController.text;
    widget.onPlanUpdated(widget.plan);
  }

  void _onPlayerNotesChanged() {
    widget.plan.meetingNotes.playerNotes = _playerNotesController.text;
    widget.onPlanUpdated(widget.plan);
  }

  void _onCoachContactChanged() {
    widget.plan.coachContact.name = _coachNameController.text;
    widget.plan.coachContact.email = _coachEmailController.text;
    widget.plan.coachContact.phone = _coachPhoneController.text;
    widget.onPlanUpdated(widget.plan);
  }

  @override
  Widget build(BuildContext context) {
    return context.responsive<Widget>(
      mobile: _buildMobileLayout(),
      tablet: _buildTabletLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildStrengthsAndImprovementsCard(),
        const SizedBox(height: 16),
        _buildCoreTargetsCard(),
        const SizedBox(height: 16),
        _buildMonthlyTargetsCard(),
        const SizedBox(height: 16),
        _buildMeetingNotesCard(),
        const SizedBox(height: 16),
        _buildCoachContactCard(),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStrengthsAndImprovementsCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildCoreTargetsCard()),
          ],
        ),
        const SizedBox(height: 16),
        _buildMonthlyTargetsCard(),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildMeetingNotesCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildCoachContactCard()),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildStrengthsAndImprovementsCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildCoreTargetsCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildMonthlyTargetsCard()),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: _buildMeetingNotesCard()),
            const SizedBox(width: 20),
            Expanded(child: _buildCoachContactCard()),
          ],
        ),
      ],
    );
  }

  // ============================================================================
  // STRENGTHS AND IMPROVEMENTS
  // ============================================================================

  Widget _buildStrengthsAndImprovementsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Strengths & Areas for Improvement',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Strengths Section
            Text(
              'Strengths',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEditableList(
              items: widget.plan.strengths,
              onItemsChanged: (items) {
                widget.plan.strengths = items;
                widget.onPlanUpdated(widget.plan);
              },
              hintText: 'Add a strength...',
              color: Colors.green,
            ),
            
            const SizedBox(height: 16),
            
            // Improvements Section
            Text(
              'Areas for Improvement',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Colors.orange.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildEditableList(
              items: widget.plan.improvements,
              onItemsChanged: (items) {
                widget.plan.improvements = items;
                widget.onPlanUpdated(widget.plan);
              },
              hintText: 'Add an improvement area...',
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // CORE TARGETS
  // ============================================================================

  Widget _buildCoreTargetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.track_changes, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Core Development Targets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...widget.plan.coreTargets.asMap().entries.map((entry) {
              final index = entry.key;
              final target = entry.value;
              return _buildCoreTargetItem(target, index);
            }),
            
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addCoreTarget,
              icon: const Icon(Icons.add),
              label: const Text('Add Target'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCoreTargetItem(CoreTarget target, int index) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: TextFormField(
                initialValue: target.skill,
                decoration: const InputDecoration(
                  labelText: 'Skill/Area',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  target.skill = value;
                  widget.onPlanUpdated(widget.plan);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: target.timeframe,
                decoration: const InputDecoration(
                  labelText: 'Timeframe',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  target.timeframe = value;
                  widget.onPlanUpdated(widget.plan);
                },
              ),
            ),
            IconButton(
              onPressed: () => _removeCoreTarget(index),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _addCoreTarget() {
    widget.plan.coreTargets.add(CoreTarget(skill: '', timeframe: ''));
    widget.onPlanUpdated(widget.plan);
    setState(() {});
  }

  void _removeCoreTarget(int index) {
    widget.plan.coreTargets.removeAt(index);
    widget.onPlanUpdated(widget.plan);
    setState(() {});
  }

  // ============================================================================
  // MONTHLY TARGETS
  // ============================================================================

  Widget _buildMonthlyTargetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Monthly Targets',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            ...widget.plan.monthlyTargets.entries.map((entry) {
              return _buildMonthlyTargetItem(entry.key, entry.value);
            }),
            
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _addMonthlyTarget,
              icon: const Icon(Icons.add),
              label: const Text('Add Monthly Target'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyTargetItem(String month, String target) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                month,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: target,
                decoration: const InputDecoration(
                  hintText: 'Target for this month...',
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: (value) {
                  widget.plan.monthlyTargets[month] = value;
                  widget.onPlanUpdated(widget.plan);
                },
              ),
            ),
            IconButton(
              onPressed: () => _removeMonthlyTarget(month),
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade600,
            ),
          ],
        ),
      ),
    );
  }

  void _addMonthlyTarget() {
    _showMonthPicker().then((month) {
      if (month != null && !widget.plan.monthlyTargets.containsKey(month)) {
        widget.plan.monthlyTargets[month] = '';
        widget.onPlanUpdated(widget.plan);
        setState(() {});
      }
    });
  }

  void _removeMonthlyTarget(String month) {
    widget.plan.monthlyTargets.remove(month);
    widget.onPlanUpdated(widget.plan);
    setState(() {});
  }

  Future<String?> _showMonthPicker() async {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Month'),
        content: SizedBox(
          width: double.minPositive,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: months.length,
            itemBuilder: (context, index) {
              final month = months[index];
              final isAlreadyAdded = widget.plan.monthlyTargets.containsKey(month);
              
              return ListTile(
                title: Text(month),
                enabled: !isAlreadyAdded,
                trailing: isAlreadyAdded ? const Text('Added') : null,
                onTap: isAlreadyAdded 
                  ? null 
                  : () => Navigator.of(context).pop(month),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // ============================================================================
  // MEETING NOTES
  // ============================================================================

  Widget _buildMeetingNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notes, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Meeting Notes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Coach Notes
            Text(
              'Coach Notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _coachNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Notes from coaching staff...',
                border: OutlineInputBorder(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Player Notes
            Text(
              'Player Notes',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _playerNotesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Player thoughts and feedback...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // COACH CONTACT
  // ============================================================================

  Widget _buildCoachContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Coach Contact',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _coachNameController,
              decoration: const InputDecoration(
                labelText: 'Coach Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _coachEmailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _coachPhoneController,
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // EDITABLE LIST WIDGET
  // ============================================================================

  Widget _buildEditableList({
    required List<String> items,
    required Function(List<String>) onItemsChanged,
    required String hintText,
    required Color color,
  }) {
    return Column(
      children: [
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return _buildEditableListItem(
            item: item,
            color: color,
            onChanged: (value) {
              items[index] = value;
              onItemsChanged(items);
            },
            onRemove: () {
              items.removeAt(index);
              onItemsChanged(items);
              setState(() {});
            },
          );
        }),
        
        const SizedBox(height: 8),
        
        OutlinedButton.icon(
          onPressed: () {
            items.add('');
            onItemsChanged(items);
            setState(() {});
          },
          icon: Icon(Icons.add, color: color),
          label: Text('Add Item', style: TextStyle(color: color)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: color),
          ),
        ),
      ],
    );
  }

  Widget _buildEditableListItem({
    required String item,
    required Color color,
    required Function(String) onChanged,
    required VoidCallback onRemove,
  }) {
    return Card(
      color: color.withOpacity(0.05),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                initialValue: item,
                decoration: InputDecoration(
                  hintText: item.isEmpty ? 'Enter text...' : null,
                  border: InputBorder.none,
                  isDense: true,
                ),
                onChanged: onChanged,
              ),
            ),
            IconButton(
              onPressed: onRemove,
              icon: const Icon(Icons.delete_outline, size: 20),
              color: Colors.red.shade600,
            ),
          ],
        ),
      ),
    );
  }
}