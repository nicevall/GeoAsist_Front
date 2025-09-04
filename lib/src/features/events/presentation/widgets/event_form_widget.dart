// lib/src/features/events/presentation/widgets/event_form_widget.dart
// Event creation/editing form widget

import 'package:flutter/material.dart';
import '../../../authentication/presentation/widgets/authentication_loading_widget.dart';

class EventFormWidget extends StatefulWidget {
  final Function(Map<String, dynamic>)? onSubmit;
  final Map<String, dynamic>? initialData;
  final bool isLoading;

  const EventFormWidget({
    super.key,
    this.onSubmit,
    this.initialData,
    this.isLoading = false,
  });

  @override
  State<EventFormWidget> createState() => _EventFormWidgetState();
}

class _EventFormWidgetState extends State<EventFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'] ?? '';
      _descriptionController.text = widget.initialData!['description'] ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const AuthenticationLoadingWidget(message: 'Procesando evento...');
    }

    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Título del evento',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'El título es requerido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Descripción',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  title: const Text('Fecha'),
                  subtitle: Text(
                    _selectedDate?.toString().split(' ')[0] ?? 'No seleccionada',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: _selectDate,
                ),
              ),
              Expanded(
                child: ListTile(
                  title: const Text('Hora'),
                  subtitle: Text(
                    _selectedTime?.format(context) ?? 'No seleccionada',
                  ),
                  trailing: const Icon(Icons.access_time),
                  onTap: _selectTime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Guardar Evento'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? TimeOfDay.now(),
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final data = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': _selectedDate?.toIso8601String(),
        'time': _selectedTime != null
            ? '${_selectedTime!.hour}:${_selectedTime!.minute}'
            : null,
      };
      widget.onSubmit?.call(data);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}