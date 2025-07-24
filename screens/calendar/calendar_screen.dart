import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:hockey_shot_tracker/models/calendar_event.dart';
import 'package:hockey_shot_tracker/models/player.dart';
import 'package:hockey_shot_tracker/models/team.dart';
import 'package:hockey_shot_tracker/models/training_program.dart';
import 'package:hockey_shot_tracker/providers/app_state.dart';
import 'package:hockey_shot_tracker/services/dialog_service.dart';
import 'package:hockey_shot_tracker/screens/calendar/event_form_screen.dart';
import 'package:hockey_shot_tracker/responsive_system/index.dart';
import 'package:hockey_shot_tracker/services/infrastructure/api_service_factory.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late ValueNotifier<List<CalendarEvent>> _selectedEvents;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  RangeSelectionMode _rangeSelectionMode = RangeSelectionMode.toggledOff;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  
  List<CalendarEvent> _events = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    _loadEvents();
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      
      // Calculate date range for current month view plus buffer
      final firstDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
      final lastDay = DateTime(_focusedDay.year, _focusedDay.month + 2, 0);
      
      final events = await ApiServiceFactory.calendar.fetchCalendarEvents(
        startDate: firstDay.toIso8601String(),
        endDate: lastDay.toIso8601String(),
      );
      
      setState(() {
        _events = events;
        _selectedEvents.value = _getEventsForDay(_selectedDay!);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load calendar events: $e';
        _isLoading = false;
      });
    }
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _events.where((event) {
      return isSameDay(event.startTime, day);
    }).toList();
  }

  List<CalendarEvent> _getEventsForRange(DateTime start, DateTime end) {
    return _events.where((event) {
      return event.startTime.isAfter(start.subtract(const Duration(days: 1))) &&
             event.startTime.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
        _rangeStart = null;
        _rangeEnd = null;
        _rangeSelectionMode = RangeSelectionMode.toggledOff;
      });

      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  void _onRangeSelected(DateTime? start, DateTime? end, DateTime focusedDay) {
    setState(() {
      _selectedDay = null;
      _focusedDay = focusedDay;
      _rangeStart = start;
      _rangeEnd = end;
      _rangeSelectionMode = RangeSelectionMode.toggledOn;
    });

    if (start != null && end != null) {
      _selectedEvents.value = _getEventsForRange(start, end);
    } else if (start != null) {
      _selectedEvents.value = _getEventsForDay(start);
    } else {
      _selectedEvents.value = [];
    }
  }

  void _onFormatChanged(CalendarFormat format) {
    if (_calendarFormat != format) {
      setState(() {
        _calendarFormat = format;
      });
    }
  }

  void _onPageChanged(DateTime focusedDay) {
    _focusedDay = focusedDay;
    _loadEvents(); // Reload events for new month
  }

  Color _getEventColor(EventType eventType) {
    switch (eventType) {
      case EventType.workout:
        return Colors.blue;
      case EventType.assessment:
        return Colors.orange;
      case EventType.practice:
        return Colors.green;
      case EventType.game:
        return Colors.red;
      case EventType.custom:
        return Colors.purple;
    }
  }

  Widget _buildEventMarker(DateTime day, List<CalendarEvent> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    
    return Positioned(
      right: 1,
      bottom: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: events.length == 1 
              ? _getEventColor(events.first.eventType)
              : Colors.grey[700]!,
        ),
        width: ResponsiveConfig.spacing(context, 16),
        height: ResponsiveConfig.spacing(context, 16),
        child: Center(
          child: ResponsiveText(
            '${events.length}',
            baseFontSize: 12,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createEvent() async {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // Check permissions
    if (!appState.isAdmin() && !appState.isCoordinator()) {
      DialogService.showInformation(
        context,
        title: 'Permission Denied',
        message: 'Only administrators and coordinators can create calendar events.',
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          selectedDate: _selectedDay ?? DateTime.now(),
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _editEvent(CalendarEvent event) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventFormScreen(
          event: event,
          selectedDate: event.startTime,
        ),
      ),
    );

    if (result == true) {
      _loadEvents();
    }
  }

  Future<void> _deleteEvent(CalendarEvent event) async {
    final confirmed = await DialogService.showConfirmation(
      context,
      title: 'Delete Event',
      message: 'Are you sure you want to delete "${event.title}"?',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true) return;

    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await ApiServiceFactory.calendar.deleteCalendarEvent(event.id!);
      
      DialogService.showSuccess(
        context,
        title: 'Event Deleted',
        message: 'The event has been deleted successfully.',
      );
      
      _loadEvents();
    } catch (e) {
      DialogService.showError(
        context,
        title: 'Delete Failed',
        message: 'Failed to delete event: $e',
      );
    }
  }

  Future<void> _markEventComplete(CalendarEvent event) async {
    try {
      final appState = Provider.of<AppState>(context, listen: false);
      await ApiServiceFactory.calendar.updateCalendarEvent(event.id!, {
        'is_completed': true,
      });
      
      _loadEvents();
    } catch (e) {
      DialogService.showError(
        context,
        title: 'Update Failed',
        message: 'Failed to mark event as complete: $e',
      );
    }
  }

  void _navigateToEvent(CalendarEvent event) {
    // Navigate to appropriate screen based on event type
    switch (event.eventType) {
      case EventType.workout:
        if (event.trainingProgramId != null) {
          Navigator.pushNamed(
            context,
            '/workout/${event.trainingProgramId}',
          );
        }
        break;
      case EventType.assessment:
        if (event.assessmentType == AssessmentType.shooting) {
          Navigator.pushNamed(context, '/shot-assessment');
        } else if (event.assessmentType == AssessmentType.skating) {
          Navigator.pushNamed(context, '/skating-assessment');
        }
        break;
      case EventType.practice:
      case EventType.game:
      case EventType.custom:
        // Could navigate to event details screen
        break;
    }
  }

  void _showFilterOptions() {
    // TODO: Implement filter options (by event type, player, team, etc.)
    DialogService.showInformation(
      context,
      title: 'Filters',
      message: 'Filter options coming soon!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final canSchedule = appState.isAdmin() || appState.isCoordinator();

    return AdaptiveScaffold(
      title: 'Calendar',
      backgroundColor: Colors.grey[50],
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadEvents,
          tooltip: 'Refresh',
        ),
        if (canSchedule)
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
            tooltip: 'Filter',
          ),
      ],
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _buildCalendarView(canSchedule),
    );
  }

  Widget _buildErrorView() {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Center(
          child: ConstrainedBox(
            constraints: ResponsiveConfig.constraints(
              context,
              maxWidth: deviceType == DeviceType.desktop ? 600 : null,
            ),
            child: ResponsiveCard(
              padding: ResponsiveConfig.paddingAll(context, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: ResponsiveConfig.spacing(context, 64),
                    color: Colors.red[400],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText(
                    'Failed to Load Calendar',
                    baseFontSize: 20,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    _errorMessage!,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                  ResponsiveSpacing(multiplier: 3),
                  ResponsiveButton(
                    text: 'Retry',
                    onPressed: _loadEvents,
                    baseHeight: 48,
                    icon: Icons.refresh,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCalendarView(bool canSchedule) {
    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Calendar widget
            ResponsiveCard(
              margin: ResponsiveConfig.paddingAll(context, 16),
              padding: ResponsiveConfig.paddingAll(context, 16),
              child: TableCalendar<CalendarEvent>(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                eventLoader: _getEventsForDay,
                rangeSelectionMode: _rangeSelectionMode,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                rangeStartDay: _rangeStart,
                rangeEndDay: _rangeEnd,
                onDaySelected: _onDaySelected,
                onRangeSelected: _onRangeSelected,
                onFormatChanged: _onFormatChanged,
                onPageChanged: _onPageChanged,
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, day, events) {
                    final calendarEvents = events.cast<CalendarEvent>();
                    return _buildEventMarker(day, calendarEvents);
                  },
                ),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  weekendTextStyle: TextStyle(color: Colors.red[400]!),
                  holidayTextStyle: TextStyle(color: Colors.red[400]!),
                  selectedDecoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    shape: BoxShape.circle,
                  ),
                  todayDecoration: BoxDecoration(
                    color: Colors.cyanAccent[700],
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: Colors.blueGrey[200]!,
                  rangeStartDecoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: BoxDecoration(
                    color: Colors.blueGrey[700],
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonShowsNext: false,
                  formatButtonDecoration: BoxDecoration(
                    color: Colors.cyanAccent,
                    borderRadius: ResponsiveConfig.borderRadius(context, 12),
                  ),
                  formatButtonTextStyle: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Events list
            Expanded(
              child: ValueListenableBuilder<List<CalendarEvent>>(
                valueListenable: _selectedEvents,
                builder: (context, value, _) {
                  return _buildEventsList(value);
                },
              ),
            ),
            
            // Floating action button for mobile
            if (canSchedule && deviceType == DeviceType.mobile)
              Container(
                padding: ResponsiveConfig.paddingAll(context, 16),
                child: ResponsiveButton(
                  text: 'Schedule Event',
                  onPressed: _createEvent,
                  baseHeight: 48,
                  width: double.infinity,
                  backgroundColor: Colors.cyanAccent,
                  textColor: Colors.black87,
                  icon: Icons.add,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    if (events.isEmpty) {
      final selectedDateStr = _selectedDay != null
          ? DateFormat('MMMM d, yyyy').format(_selectedDay!)
          : 'Selected period';
      
      return AdaptiveLayout(
        builder: (deviceType, isLandscape) {
          return Center(
            child: ConstrainedBox(
              constraints: ResponsiveConfig.constraints(
                context,
                maxWidth: deviceType == DeviceType.desktop ? 600 : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.event_note,
                    size: ResponsiveConfig.spacing(context, 64),
                    color: Colors.grey[400],
                  ),
                  ResponsiveSpacing(multiplier: 2),
                  ResponsiveText(
                    'No events scheduled',
                    baseFontSize: 18,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  ResponsiveSpacing(multiplier: 1),
                  ResponsiveText(
                    selectedDateStr,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return AdaptiveLayout(
      builder: (deviceType, isLandscape) {
        return ListView.builder(
          padding: ResponsiveConfig.paddingAll(context, 16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event);
          },
        );
      },
    );
  }

  Widget _buildEventCard(CalendarEvent event) {
    final appState = Provider.of<AppState>(context, listen: false);
    final canEdit = appState.isAdmin() || 
                    (appState.isCoordinator() && event.createdById == appState.getCurrentUser()?['id']);

    return ResponsiveCard(
      margin: ResponsiveConfig.paddingSymmetric(context, vertical: 6),
      padding: ResponsiveConfig.paddingAll(context, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: ResponsiveConfig.spacing(context, 4),
                height: ResponsiveConfig.spacing(context, 48),
                decoration: BoxDecoration(
                  color: _getEventColor(event.eventType),
                  borderRadius: ResponsiveConfig.borderRadius(context, 2),
                ),
              ),
              ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ResponsiveText(
                      event.title,
                      baseFontSize: 16,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: event.isCompleted ? TextDecoration.lineThrough : null,
                        color: event.isCompleted ? Colors.grey[600] : null,
                      ),
                    ),
                    ResponsiveSpacing(multiplier: 0.5),
                    ResponsiveText(
                      '${DateFormat('h:mm a').format(event.startTime)} - ${DateFormat('h:mm a').format(event.endTime)}',
                      baseFontSize: 14,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'navigate':
                      _navigateToEvent(event);
                      break;
                    case 'complete':
                      _markEventComplete(event);
                      break;
                    case 'edit':
                      _editEvent(event);
                      break;
                    case 'delete':
                      _deleteEvent(event);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (event.eventType == EventType.workout || event.eventType == EventType.assessment)
                    const PopupMenuItem(
                      value: 'navigate',
                      child: ListTile(
                        leading: Icon(Icons.play_arrow),
                        title: Text('Start'),
                      ),
                    ),
                  if (!event.isCompleted)
                    const PopupMenuItem(
                      value: 'complete',
                      child: ListTile(
                        leading: Icon(Icons.check),
                        title: Text('Mark Complete'),
                      ),
                    ),
                  if (canEdit) ...[
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (event.description.isNotEmpty) ...[
            ResponsiveSpacing(multiplier: 1),
            ResponsiveText(
              event.description,
              baseFontSize: 14,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
          if (event.playerName != null || event.location != null) ...[
            ResponsiveSpacing(multiplier: 1),
            Row(
              children: [
                if (event.playerName != null) ...[
                  Icon(Icons.person, size: ResponsiveConfig.spacing(context, 16), color: Colors.grey[600]),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    event.playerName!,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (event.location != null) 
                    ResponsiveSpacing(multiplier: 2, direction: Axis.horizontal),
                ],
                if (event.location != null) ...[
                  Icon(Icons.location_on, size: ResponsiveConfig.spacing(context, 16), color: Colors.grey[600]),
                  ResponsiveSpacing(multiplier: 0.5, direction: Axis.horizontal),
                  ResponsiveText(
                    event.location!,
                    baseFontSize: 14,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}