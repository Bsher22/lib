// lib/widgets/common/form/standard_date_picker.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StandardDatePicker extends StatelessWidget {
  final TextEditingController controller;
  final String? labelText;
  final String? hintText;
  final String? errorText;
  final String? helperText;
  final IconData? prefixIcon;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final ValueChanged<DateTime>? onDateSelected;
  final FormFieldValidator<String>? validator;
  final String dateFormat;
  final bool enabled;

  const StandardDatePicker({
    Key? key,
    required this.controller,
    this.labelText,
    this.hintText,
    this.errorText,
    this.helperText,
    this.prefixIcon = Icons.calendar_today,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.dateFormat = 'MM/dd/yyyy',
    this.enabled = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      enabled: enabled,
      validator: validator,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        errorText: errorText,
        helperText: helperText,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
        suffixIcon: IconButton(
          icon: const Icon(Icons.date_range),
          onPressed: enabled ? () => _selectDate(context) : null,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onTap: enabled ? () => _selectDate(context) : null,
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime today = DateTime.now();
    
    // Determine initial date based on provided value or controller text
    DateTime? initialSelectedDate;
    if (initialDate != null) {
      initialSelectedDate = initialDate;
    } else if (controller.text.isNotEmpty) {
      try {
        initialSelectedDate = DateFormat(dateFormat).parse(controller.text);
      } catch (_) {
        initialSelectedDate = today;
      }
    } else {
      initialSelectedDate = today;
    }
    
    // Use provided date boundaries or defaults
    final DateTime startDate = firstDate ?? DateTime(1900);
    final DateTime endDate = lastDate ?? DateTime(today.year + 50, 12, 31);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialSelectedDate,
      firstDate: startDate,
      lastDate: endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blueGrey[800]!,
              onPrimary: Colors.white,
              onSurface: Colors.blueGrey[900]!,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      controller.text = DateFormat(dateFormat).format(picked);
      
      if (onDateSelected != null) {
        onDateSelected!(picked);
      }
    }
  }
}