import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_constants.dart';
import '../../models/lead_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/info_banner.dart';

class AIReplyScreen extends StatefulWidget {
  const AIReplyScreen({super.key, this.lead});

  final LeadModel? lead;

  @override
  State<AIReplyScreen> createState() => _AIReplyScreenState();
}

class _AIReplyScreenState extends State<AIReplyScreen> {
  late final TextEditingController _customerNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _sourceController;
  late final TextEditingController _serviceController;
  late final TextEditingController _messageController;
  final TextEditingController _replyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController(
      text: widget.lead?.name ?? '',
    );
    _phoneController = TextEditingController(text: widget.lead?.phone ?? '');
    _sourceController = TextEditingController(text: widget.lead?.source ?? '');
    _serviceController = TextEditingController(
      text: widget.lead?.serviceInterested ?? '',
    );
    _messageController = TextEditingController(
      text: widget.lead?.customerMessage ?? '',
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _phoneController.dispose();
    _sourceController.dispose();
    _serviceController.dispose();
    _messageController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'AI Reply Generator',
      selectedItem: 'ai_reply',
      showDrawer: widget.lead == null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const InfoBanner(
              message:
                  'AI-generated reply. Review before sending. The app does not send WhatsApp messages automatically.',
              icon: Icons.warning_amber_rounded,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _customerNameController,
              decoration: const InputDecoration(labelText: 'Customer name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sourceController,
              decoration: const InputDecoration(labelText: 'Lead source'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(
                labelText: 'Service interested',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              minLines: 5,
              maxLines: 7,
              decoration: const InputDecoration(labelText: 'Customer message'),
            ),
            if (appState.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                appState.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: appState.isBusy ? null : _generateReply,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: Text(appState.isBusy ? 'Generating...' : 'Generate reply'),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _replyController,
              minLines: 6,
              maxLines: 10,
              decoration: const InputDecoration(labelText: 'Generated reply'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyReply,
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _openWhatsAppDraft,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Open WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateReply() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a customer message first.')),
      );
      return;
    }

    final reply = await context.read<AppState>().generateAiReply(
      leadId: widget.lead?.id,
      customerMessage: _messageController.text,
      customerName: _customerNameController.text,
      serviceInterested: _serviceController.text,
      source: _sourceController.text,
    );

    if (!mounted || reply == null) {
      return;
    }

    _replyController.text = reply;
  }

  Future<void> _copyReply() async {
    if (_replyController.text.trim().isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: _replyController.text.trim()));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reply copied to clipboard.')));
  }

  Future<void> _openWhatsAppDraft() async {
    final phone = AppConstants.normalizePhone(_phoneController.text);
    final reply = _replyController.text.trim();

    if (phone.isEmpty || reply.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number and generated reply are required.'),
        ),
      );
      return;
    }

    final uri = Uri.parse(
      'https://wa.me/$phone?text=${Uri.encodeComponent(reply)}',
    );

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!launched && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open WhatsApp.')));
    }
  }
}
