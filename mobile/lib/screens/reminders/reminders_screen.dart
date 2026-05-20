import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _reminderAt = DateTime.now().add(const Duration(hours: 1));
  int? _selectedLeadId;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    if (appState.leads.isEmpty) {
      appState.fetchLeads(silent: true);
    }
    appState.fetchTodayReminders(silent: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'Follow-up Reminders',
      selectedItem: 'reminders',
      body: RefreshIndicator(
        onRefresh: () => context.read<AppState>().fetchTodayReminders(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Create reminder',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Reminder title',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: _selectedLeadId,
                      decoration: const InputDecoration(
                        labelText: 'Linked lead',
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No linked lead'),
                        ),
                        ...appState.leads.map(
                          (lead) => DropdownMenuItem<int?>(
                            value: lead.id,
                            child: Text('${lead.name} • ${lead.phone}'),
                          ),
                        ),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedLeadId = value),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reminder time'),
                      subtitle: Text(
                        AppConstants.formatReadableDateTime(_reminderAt),
                      ),
                      trailing: IconButton(
                        onPressed: _pickReminderDateTime,
                        icon: const Icon(Icons.schedule_rounded),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Notes'),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      onPressed: appState.isBusy ? null : _createReminder,
                      child: Text(
                        appState.isBusy ? 'Saving...' : 'Save reminder',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Today',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            if (appState.todayReminders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No reminders due today.'),
                ),
              )
            else
              ...appState.todayReminders.map(
                (reminder) => Card(
                  child: ListTile(
                    title: Text(reminder.title),
                    subtitle: Text(
                      '${AppConstants.formatReadableDateTime(reminder.reminderAt)}\n${reminder.leadName ?? reminder.notes ?? ''}',
                    ),
                    isThreeLine: true,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReminderDateTime() async {
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _reminderAt,
    );

    if (date == null || !mounted) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reminderAt),
    );

    if (time == null) {
      return;
    }

    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _createReminder() async {
    if (_titleController.text.trim().isEmpty) {
      return;
    }

    final success = await context.read<AppState>().createReminder(
      title: _titleController.text,
      reminderAt: _reminderAt,
      leadId: _selectedLeadId,
      notes: _notesController.text,
    );

    if (!mounted || !success) {
      return;
    }

    _titleController.clear();
    _notesController.clear();
    setState(() {
      _selectedLeadId = null;
      _reminderAt = DateTime.now().add(const Duration(hours: 1));
    });
  }
}
