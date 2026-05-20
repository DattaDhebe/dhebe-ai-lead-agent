import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/info_banner.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _feedbackController = TextEditingController();
  int? _rating;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'Settings',
      selectedItem: 'settings',
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const InfoBanner(
            message:
                'WhatsApp stays manual in this MVP. The app only drafts a message and opens WhatsApp for your review.',
          ),
          const SizedBox(height: 18),
          Card(
            child: Column(
              children: [
                RadioListTile<ThemeMode>(
                  value: ThemeMode.system,
                  groupValue: appState.themeMode,
                  title: const Text('System theme'),
                  onChanged: (value) =>
                      context.read<AppState>().setThemeMode(value!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.light,
                  groupValue: appState.themeMode,
                  title: const Text('Light theme'),
                  onChanged: (value) =>
                      context.read<AppState>().setThemeMode(value!),
                ),
                RadioListTile<ThemeMode>(
                  value: ThemeMode.dark,
                  groupValue: appState.themeMode,
                  title: const Text('Dark theme'),
                  onChanged: (value) =>
                      context.read<AppState>().setThemeMode(value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'API base URL',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const SelectableText(AppConstants.apiBaseUrl),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep API keys and database credentials only on the backend.',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feedback',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: List.generate(
                      5,
                      (index) => ChoiceChip(
                        label: Text('${index + 1}'),
                        selected: _rating == index + 1,
                        onSelected: (_) => setState(() => _rating = index + 1),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feedbackController,
                    minLines: 3,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      labelText: 'What should improve next?',
                    ),
                  ),
                  if (appState.lastError != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      appState.lastError!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: appState.isBusy ? null : _submitFeedback,
                    child: Text(
                      appState.isBusy ? 'Sending...' : 'Submit feedback',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => context.read<AppState>().logout(),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty) {
      return;
    }

    final success = await context.read<AppState>().submitFeedback(
      message: _feedbackController.text,
      rating: _rating,
    );

    if (!mounted || !success) {
      return;
    }

    _feedbackController.clear();
    setState(() => _rating = null);
  }
}
