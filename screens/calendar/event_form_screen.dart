import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/calendar_event.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:hockey_shot_tracker/widgets/core/form/index.dart';
import 'package:hockey_shot_tracker/widgets/core/selection/index.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:intl/intl.dart';

class EventFormScreen extends StatefulWidget {
  final CalendarEvent? event;
  final DateTime selectedDate;

  const EventFormScreen({
    super.key,
    this.event,
    required this.selectedDate,
  });

  @override
  State<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends State<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _recurrenceIntervalController = TextEditingController();

  EventType _selectedEventType = EventType.workout;
  AssessmentType? _selectedAssessmentType;
  RecurrenceType _selectedRecurrenceType = RecurrenceType.none;
  
  DateTime _startTime = DateTime.now();
  DateTime _endTime = DateTime.now().add(const Duration(hours: 1));
  DateTime? _recurrenceEndDate;
  
  Player? _selectedPlayer;
  Team? _selectedTeam;
  TrainingProgram? _selectedTrainingProgram;
  
  int _recurrenceInterval = 1;
  bool _isLoading = false;
  bool _showRecurrenceOptions = false;

  List<Player> _availablePlayers = [];
  List<Team> _availableTeams = [];
  List<TrainingProgram> _availablePrograms = [];

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _loadFormData();
    _recurrenceIntervalController.text = _recurrenceInterval.toString();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    _locationController.dispose();
    _recurrenceIntervalController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.event != null) {
      final event = widget.event!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _notesController.text = event.notes ?? '';
      _locationController.text = event.location ?? '';
      
      _selectedEventType = event.eventType;
      _selectedAssessmentType = event.assessmentType;
      _selectedRecurrenceType = event.recurrenceType;
      _startTime = event.startTime;
      _endTime = event.endTime;
      _recurrenceEndDate = event.recurrenceEndDate;
      _recurrenceInterval = event.recurrenceInterval ?? 1;
      _showRecurrenceOptions = event.recurrenceType != RecurrenceType.none;
    } else {
      _startTime = DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        widget.selectedDate.day,
        9,
      );
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      await Future.wait([
        appState.loadPlayers(),
        appState.loadTeams(),
        _loadTrainingPrograms(),
      ]);

      setState(() {
        _availablePlayers = appState.players;
        _availableTeams = appState.teams;
        
        if (widget.event != null) {
          final event = widget.event!;
          
          if (event.playerId != null) {
            _selectedPlayer = _availablePlayers.firstWhere(
              (p) => p.id == event.playerId,
              orElse: () => _availablePlayers.isNotEmpty
                  ? _availablePlayers.first
                  : Player(
                      id: -1,
                      name: 'Unknown',
                      createdAt: DateTime.now(),
                    ),
            );
          }
          
          if (event.teamId != null) {
            _selectedTeam = _availableTeams.firstWhere(
              (t) => t.id == event.teamId,
              orElse: () => _availableTeams.isNotEmpty
                  ? _availableTeams.first
                  : Team(
                      id: -1,
                      name: 'Unknown',
                      createdAt: DateTime.now(),
                    ),
            );
          }
          
          if (event.trainingProgramId != null) {
            _selectedTrainingProgram = _availablePrograms.firstWhere(
              (p) => p.id == event.trainingProgramId,
              orElse: () => _availablePrograms.isNotEmpty
                  ? _availablePrograms.first
                  : TrainingProgram(
                      id: -1,
                      name: 'Unknown',
                      description: null,
                      createdAt: DateTime.now(),
                      difficulty: 'beginner',
                      type: 'general',
                      duration: '30 minutes',
                      totalShots: 50,
                      estimatedDuration: 30,
                    ),
            );
          }
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      DialogService.showError(
        context,
        title: 'Loading Error',
        message: 'Failed to load form data: $e',
      );
    }
  }

  Future<void> _loadTrainingPrograms() async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      final programs = await ApiServiceFactory.training.fetchTrainingPrograms();
      setState(() {
        _availablePrograms = programs;
      });
    } catch (e) {
      print('Error loading training programs: $e');
      setState(() {
        _availablePrograms = [];
      });
    }
  }

  Future<void> _selectDateTime(bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime ? _startTime : _endTime,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStartTime ? _startTime : _endTime),
      );

      if (pickedTime != null) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = newDateTime;
            if (_endTime.isBefore(_startTime)) {
              _endTime = _startTime.add(const Duration(hours: 1));
            }
          } else {
            _endTime = newDateTime;
          }
        });
      }
    }
  }

  Future<void> _selectRecurrenceEndDate() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _recurrenceEndDate ?? _startTime.add(const Duration(days: 30)),
      firstDate: _startTime,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _recurrenceEndDate = pickedDate;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_endTime.isBefore(_startTime)) {
      DialogService.showError(
        context,
        title: 'Invalid Time',
        message: 'End time must be after start time.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      final eventData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'start_time': _startTime.toIso8601String(),
        'end_time': _endTime.toIso8601String(),
        'event_type': _selectedEventType.toString().split('.').last,
        'location': _locationController.text.trim().isNotEmpty 
            ? _locationController.text.trim() 
            : null,
        'notes': _notesController.text.trim().isNotEmpty 
            ? _notesController.text.trim() 
            : null,
        'player_id': _selectedPlayer?.id,
        'team_id': _selectedTeam?.id,
        'training_program_id': _selectedTrainingProgram?.id,
        'assessment_type': _selectedAssessmentType?.toString().split('.').last,
        'recurrence_type': _selectedRecurrenceType.toString().split('.').last,
        'recurrence_interval': _selectedRecurrenceType != RecurrenceType.none ? _recurrenceInterval : null,
        'recurrence_end_date': _recurrenceEndDate?.toIso8601String(),
        'participant_ids': [],
      };

      if (widget.event != null) {
        await ApiServiceFactory.calendar.updateCalendarEvent(widget.event!.id!, eventData);
        
        DialogService.showSuccess(
          context,
          title: 'Event Updated',
          message: 'The event has been updated successfully.',
        );
      } else {
        await ApiServiceFactory.calendar.createCalendarEvent(eventData);
        
        DialogService.showSuccess(
          context,
          title: 'Event Created',
          message: 'The event has been created successfully.',
        );
      }

      Navigator.of(context).pop(true);
    } catch (e) {
      DialogService.showError(
        context,
        title: 'Save Failed',
        message: 'Failed to save event: $e',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.event != null;

    return AdaptiveScaffold(
      title: isEditing ? 'Edit Event' : 'Schedule Event',
      backgroundColor: Colors.grey[100],
      actions: [
        if (!_isLoading)
          TextButton(
            onPressed: _saveEvent,
            child: ResponsiveText(
              isEditing ? 'Update' : 'Create',
              baseFontSize: 16,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
      body: AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return _isLoading
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: ResponsiveConfig.dimension(context, 32),
                        height: ResponsiveConfig.dimension(context, 32),
                        child: const CircularProgressIndicator(color: Colors.cyanAccent),
                      ),
                      ResponsiveSpacing(multiplier: 2),
                      ResponsiveText('Loading event data...', baseFontSize: 16),
                    ],
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: ResponsiveConfig.paddingAll(context, 16),
                    child: ConstrainedBox(
                      constraints: ResponsiveConfig.constraints(
                        context,
                        maxWidth: deviceType == DeviceType.desktop ? 800 : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEventDetailsSection(deviceType),
                          ResponsiveSpacing(multiplier: 3),
                          _buildScheduleSection(deviceType),
                          ResponsiveSpacing(multiplier: 3),
                          _buildParticipantsSection(deviceType),
                          ResponsiveSpacing(multiplier: 3),
                          _buildRecurrenceSection(deviceType),
                          ResponsiveSpacing(multiplier: 3),
                          _buildNotesSection(deviceType),
                          ResponsiveSpacing(multiplier: 4),
                          _buildActionButton(isEditing),
                        ],
                      ),
                    ),
                  ),
                );
        },
      ),
    );
  }

  Widget _buildEventDetailsSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Event Details', Icons.event),
          ResponsiveSpacing(multiplier: 2),
          
          StandardTextField(
            controller: _titleController,
            labelText: 'Event Title *',
            prefixIcon: Icons.title,
            validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
          ),
          ResponsiveSpacing(multiplier: 2),
          
          StandardTextField(
            controller: _descriptionController,
            labelText: 'Description',
            prefixIcon: Icons.description,
            maxLines: 3,
          ),
          ResponsiveSpacing(multiplier: 2),
          
          StandardDropdown<EventType>(
            value: _selectedEventType,
            labelText: 'Event Type',
            prefixIcon: Icons.category,
            items: EventType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type.toString().split('.').last.toUpperCase()),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedEventType = value!;
                if (value != EventType.assessment) {
                  _selectedAssessmentType = null;
                }
                if (value != EventType.workout) {
                  _selectedTrainingProgram = null;
                }
              });
            },
          ),
          
          // Conditional fields based on event type
          if (_selectedEventType == EventType.assessment) ...[
            ResponsiveSpacing(multiplier: 2),
            StandardDropdown<AssessmentType>(
              value: _selectedAssessmentType,
              labelText: 'Assessment Type',
              prefixIcon: Icons.assessment,
              items: AssessmentType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAssessmentType = value;
                });
              },
            ),
          ],
          
          if (_selectedEventType == EventType.workout) ...[
            ResponsiveSpacing(multiplier: 2),
            StandardDropdown<TrainingProgram?>(
              value: _selectedTrainingProgram,
              labelText: 'Training Program (Optional)',
              prefixIcon: Icons.fitness_center,
              items: [
                const DropdownMenuItem<TrainingProgram?>(
                  value: null,
                  child: Text('No Program'),
                ),
                ..._availablePrograms.map((program) {
                  return DropdownMenuItem(
                    value: program,
                    child: Text(program.name),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedTrainingProgram = value;
                });
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildScheduleSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Schedule', Icons.schedule),
          ResponsiveSpacing(multiplier: 2),
          
          // Start and End time - Responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildDateTimeField(
                      'Start Time',
                      _startTime,
                      () => _selectDateTime(true),
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    _buildDateTimeField(
                      'End Time',
                      _endTime,
                      () => _selectDateTime(false),
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeField(
                        'Start Time',
                        _startTime,
                        () => _selectDateTime(true),
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: _buildDateTimeField(
                        'End Time',
                        _endTime,
                        () => _selectDateTime(false),
                      ),
                    ),
                  ],
                );
              }
            },
          ),
          ResponsiveSpacing(multiplier: 2),
          
          StandardTextField(
            controller: _locationController,
            labelText: 'Location (Optional)',
            prefixIcon: Icons.location_on,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Participants', Icons.people),
          ResponsiveSpacing(multiplier: 2),
          
          // Player and Team - Responsive layout
          AdaptiveLayout(
            builder: (deviceType, isLandscape) {
              if (deviceType == DeviceType.mobile && !isLandscape) {
                // Mobile Portrait: Stack vertically
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StandardDropdown<Player?>(
                      value: _selectedPlayer,
                      labelText: 'Player (Optional)',
                      prefixIcon: Icons.person,
                      items: [
                        const DropdownMenuItem<Player?>(
                          value: null,
                          child: Text('No specific player'),
                        ),
                        ..._availablePlayers.map((player) {
                          return DropdownMenuItem(
                            value: player,
                            child: Text(player.name ?? 'Unknown'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedPlayer = value;
                        });
                      },
                    ),
                    ResponsiveSpacing(multiplier: 2),
                    StandardDropdown<Team?>(
                      value: _selectedTeam,
                      labelText: 'Team (Optional)',
                      prefixIcon: Icons.group,
                      items: [
                        const DropdownMenuItem<Team?>(
                          value: null,
                          child: Text('No specific team'),
                        ),
                        ..._availableTeams.map((team) {
                          return DropdownMenuItem(
                            value: team,
                            child: Text(team.name ?? 'Unknown'),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedTeam = value;
                        });
                      },
                    ),
                  ],
                );
              } else {
                // Tablet/Desktop: Side by side
                return Row(
                  children: [
                    Expanded(
                      child: StandardDropdown<Player?>(
                        value: _selectedPlayer,
                        labelText: 'Player (Optional)',
                        prefixIcon: Icons.person,
                        items: [
                          const DropdownMenuItem<Player?>(
                            value: null,
                            child: Text('No specific player'),
                          ),
                          ..._availablePlayers.map((player) {
                            return DropdownMenuItem(
                              value: player,
                              child: Text(player.name ?? 'Unknown'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedPlayer = value;
                          });
                        },
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                    Expanded(
                      child: StandardDropdown<Team?>(
                        value: _selectedTeam,
                        labelText: 'Team (Optional)',
                        prefixIcon: Icons.group,
                        items: [
                          const DropdownMenuItem<Team?>(
                            value: null,
                            child: Text('No specific team'),
                          ),
                          ..._availableTeams.map((team) {
                            return DropdownMenuItem(
                              value: team,
                              child: Text(team.name ?? 'Unknown'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedTeam = value;
                          });
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecurrenceSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Recurrence', Icons.repeat),
          ResponsiveSpacing(multiplier: 2),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                value: _showRecurrenceOptions,
                onChanged: (value) {
                  setState(() {
                    _showRecurrenceOptions = value ?? false;
                    if (!_showRecurrenceOptions) {
                      _selectedRecurrenceType = RecurrenceType.none;
                      _recurrenceEndDate = null;
                    }
                  });
                },
              ),
              ResponsiveText('Recurring Event', baseFontSize: 16),
            ],
          ),
          
          if (_showRecurrenceOptions) ...[
            ResponsiveSpacing(multiplier: 2),
            StandardDropdown<RecurrenceType>(
              value: _selectedRecurrenceType,
              labelText: 'Repeat',
              prefixIcon: Icons.repeat,
              items: [
                RecurrenceType.daily,
                RecurrenceType.weekly,
                RecurrenceType.monthly,
              ].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedRecurrenceType = value ?? RecurrenceType.none;
                });
              },
            ),
            ResponsiveSpacing(multiplier: 2),
            
            // Interval and End Date - Responsive layout
            AdaptiveLayout(
              builder: (deviceType, isLandscape) {
                if (deviceType == DeviceType.mobile && !isLandscape) {
                  // Mobile Portrait: Stack vertically
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StandardTextField(
                        controller: _recurrenceIntervalController,
                        labelText: 'Every',
                        prefixIcon: Icons.numbers,
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          _recurrenceInterval = int.tryParse(value) ?? 1;
                        },
                      ),
                      ResponsiveSpacing(multiplier: 2),
                      _buildDateTimeField(
                        'Until',
                        _recurrenceEndDate,
                        _selectRecurrenceEndDate,
                        isRequired: false,
                      ),
                    ],
                  );
                } else {
                  // Tablet/Desktop: Side by side
                  return Row(
                    children: [
                      Expanded(
                        child: StandardTextField(
                          controller: _recurrenceIntervalController,
                          labelText: 'Every',
                          prefixIcon: Icons.numbers,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _recurrenceInterval = int.tryParse(value) ?? 1;
                          },
                        ),
                      ),
                      ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                      Expanded(
                        child: _buildDateTimeField(
                          'Until',
                          _recurrenceEndDate,
                          _selectRecurrenceEndDate,
                          isRequired: false,
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNotesSection(DeviceType deviceType) {
    return ResponsiveCard(
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Additional Notes', Icons.note),
          ResponsiveSpacing(multiplier: 2),
          
          StandardTextField(
            controller: _notesController,
            labelText: 'Notes (Optional)',
            prefixIcon: Icons.note,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon, 
          color: Colors.blueGrey[700], 
          size: ResponsiveConfig.iconSize(context, 20),
        ),
        ResponsiveSpacing(multiplier: 1, direction: Axis.horizontal),
        ResponsiveText(
          title,
          baseFontSize: 18,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey[800],
          ),
        ),
      ],
    );
  }

  Widget _buildDateTimeField(String label, DateTime? dateTime, VoidCallback onTap, {bool isRequired = true}) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.schedule, size: ResponsiveConfig.iconSize(context, 20)),
          border: const OutlineInputBorder(),
        ),
        child: ResponsiveText(
          dateTime != null
              ? DateFormat('MMM d, yyyy h:mm a').format(dateTime)
              : isRequired ? 'Select date and time' : 'Select end date',
          baseFontSize: 16,
        ),
      ),
    );
  }

  Widget _buildActionButton(bool isEditing) {
    return Center(
      child: ResponsiveButton(
        // 🔄 FIXED: Removed loadingText parameter - using conditional text instead
        text: _isLoading
            ? (isEditing ? 'Updating event...' : 'Creating event...')
            : (isEditing ? 'Update Event' : 'Create Event'),
        onPressed: _isLoading ? null : _saveEvent,
        baseHeight: 48,
        width: double.infinity,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black87,
        isLoading: _isLoading,
      ),
    );
  }
}