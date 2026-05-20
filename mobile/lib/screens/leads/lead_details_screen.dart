import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/lead_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/info_banner.dart';
import '../ai/ai_reply_screen.dart';

class LeadDetailsScreen extends StatefulWidget {
  const LeadDetailsScreen({super.key, required this.lead});

  final LeadModel lead;

  @override
  State<LeadDetailsScreen> createState() => _LeadDetailsScreenState();
}

class _LeadDetailsScreenState extends State<LeadDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _serviceController;
  late final TextEditingController _sourceController;
  late final TextEditingController _messageController;
  late final TextEditingController _notesController;
  final TextEditingController _newNoteController = TextEditingController();

  late String _status;
  DateTime? _nextFollowUpAt;
  late Future<Map<String, dynamic>?> _detailsFuture;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.lead.name);
    _phoneController = TextEditingController(text: widget.lead.phone);
    _emailController = TextEditingController(text: widget.lead.email ?? '');
    _serviceController = TextEditingController(
      text: widget.lead.serviceInterested,
    );
    _sourceController = TextEditingController(text: widget.lead.source);
    _messageController = TextEditingController(
      text: widget.lead.customerMessage,
    );
    _notesController = TextEditingController(text: widget.lead.notes ?? '');
    _status = widget.lead.status;
    _nextFollowUpAt = widget.lead.nextFollowUpAt;
    _detailsFuture = context.read<AppState>().fetchLeadBundle(widget.lead.id);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _serviceController.dispose();
    _sourceController.dispose();
    _messageController.dispose();
    _notesController.dispose();
    _newNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'Lead Details',
      selectedItem: 'leads',
      showDrawer: false,
      actions: [
        IconButton(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _detailsFuture,
        builder: (context, snapshot) {
          final notesHistory =
              (snapshot.data?['notes_history'] as List<dynamic>? ?? const []);
          final generatedReplies =
              (snapshot.data?['generated_replies'] as List<dynamic>? ??
              const []);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InfoBanner(
                  message:
                      'Keep customer updates factual and timely. The AI reply tool only drafts a message for review.',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Lead name'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _sourceController,
                  decoration: const InputDecoration(labelText: 'Source'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _serviceController,
                  decoration: const InputDecoration(
                    labelText: 'Service interested',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Customer message',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: AppConstants.leadStatuses
                      .map(
                        (status) => DropdownMenuItem(
                          value: status,
                          child: Text(AppConstants.prettifyStatus(status)),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() => _status = value ?? _status);
                  },
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Next follow-up'),
                  subtitle: Text(
                    AppConstants.formatReadableDateTime(_nextFollowUpAt),
                  ),
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
                  decoration: const InputDecoration(labelText: 'Current notes'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _newNoteController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Add note to history',
                  ),
                ),
                if (appState.lastError != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    appState.lastError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: appState.isBusy ? null : _saveLead,
                        child: Text(
                          appState.isBusy ? 'Saving...' : 'Save changes',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _openAiReply,
                        child: const Text('AI Reply'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Note history',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (notesHistory.isEmpty)
                  const Text('No note history yet.')
                else
                  ...notesHistory.map(
                    (item) => Card(
                      child: ListTile(
                        title: Text(
                          (item as Map<String, dynamic>)['note'] as String? ??
                              '',
                        ),
                        subtitle: Text(item['created_at'] as String? ?? ''),
                      ),
                    ),
                  ),
                const SizedBox(height: 22),
                Text(
                  'Recent AI drafts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                if (generatedReplies.isEmpty)
                  const Text('No AI drafts saved for this lead yet.')
                else
                  ...generatedReplies.map(
                    (item) => Card(
                      child: ListTile(
                        title: Text(
                          (item as Map<String, dynamic>)['generated_reply']
                                  as String? ??
                              '',
                        ),
                        subtitle: Text(
                          '${item['provider'] ?? ''} - ${item['created_at'] ?? ''}',
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
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

  Future<void> _saveLead() async {
    final success = await context.read<AppState>().updateLead(
      id: widget.lead.id,
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      source: _sourceController.text,
      serviceInterested: _serviceController.text,
      customerMessage: _messageController.text,
      status: _status,
      nextFollowUpAt: _nextFollowUpAt,
      notes: _notesController.text,
      newNote: _newNoteController.text,
    );

    if (!mounted || !success) {
      return;
    }

    _newNoteController.clear();
    setState(() {
      _detailsFuture = context.read<AppState>().fetchLeadBundle(widget.lead.id);
    });
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete lead?'),
        content: const Text('This will remove the lead and related reminders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final success = await context.read<AppState>().deleteLead(widget.lead.id);

    if (!mounted || !success) {
      return;
    }

    Navigator.of(context).pop();
  }

  void _openAiReply() {
    final lead = widget.lead.copyWith(
      name: _nameController.text,
      phone: _phoneController.text,
      email: _emailController.text,
      source: _sourceController.text,
      serviceInterested: _serviceController.text,
      customerMessage: _messageController.text,
      status: _status,
      nextFollowUpAt: _nextFollowUpAt,
      notes: _notesController.text,
    );

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => AIReplyScreen(lead: lead)))
        .then((_) {
          if (mounted) {
            setState(() {
              _detailsFuture = context.read<AppState>().fetchLeadBundle(
                widget.lead.id,
              );
            });
          }
        });
  }
}
