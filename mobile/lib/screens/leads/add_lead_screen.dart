import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';

class AddLeadScreen extends StatefulWidget {
  const AddLeadScreen({super.key});

  @override
  State<AddLeadScreen> createState() => _AddLeadScreenState();
}

class _AddLeadScreenState extends State<AddLeadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _serviceController = TextEditingController();
  final _messageController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedSource = AppConstants.leadSources.first;
  String _selectedStatus = AppConstants.leadStatuses.first;
  DateTime? _nextFollowUpAt;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _serviceController.dispose();
    _messageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'Add Lead',
      selectedItem: 'leads',
      showDrawer: false,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Lead name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (optional)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedSource,
                decoration: const InputDecoration(labelText: 'Source'),
                items: AppConstants.leadSources
                    .map((source) => DropdownMenuItem(
                          value: source,
                          child: Text(source),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSource = value ?? _selectedSource),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _serviceController,
                decoration: const InputDecoration(labelText: 'Service interested'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _messageController,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(labelText: 'Customer message'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: AppConstants.leadStatuses
                    .map((status) => DropdownMenuItem(
                          value: status,
                          child: Text(AppConstants.prettifyStatus(status)),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedStatus = value ?? _selectedStatus),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Next follow-up'),
                subtitle: Text(AppConstants.formatReadableDateTime(_nextFollowUpAt)),
                trailing: IconButton(
                  onPressed: _pickFollowUpDateTime,
                  icon: const Icon(Icons.event_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
              if (appState.lastError != null) ...[
                const SizedBox(height: 12),
                Text(
                  appState.lastError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: appState.isBusy ? null : _submit,
                child: Text(appState.isBusy ? 'Saving...' : 'Save lead'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFollowUpDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _nextFollowUpAt ?? DateTime.now(),
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_nextFollowUpAt ?? DateTime.now()),
    );

    if (time == null) {
      return;
    }

    setState(() {
      _nextFollowUpAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final success = await context.read<AppState>().createLead({
      'name' => _nameController.text.trim(),
      'phone' => _phoneController.text.trim(),
      'email' => _emailController.text.trim(),
      'source' => _selectedSource,
      'service_interested' => _serviceController.text.trim(),
      'customer_message' => _messageController.text.trim(),
      'status' => _selectedStatus,
      'next_follow_up_at': _nextFollowUpAt == null
          ? ''
          : AppConstants.formatApiDateTime(_nextFollowUpAt!),
      'notes' => _notesController.text.trim(),
    });

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pop(true);
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }
}
