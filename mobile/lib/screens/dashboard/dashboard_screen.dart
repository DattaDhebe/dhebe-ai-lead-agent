import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/lead_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/lead_card.dart';
import '../ai/ai_reply_screen.dart';
import '../business/business_profile_screen.dart';
import '../leads/add_lead_screen.dart';
import '../leads/lead_details_screen.dart';
import '../leads/leads_list_screen.dart';
import '../reminders/reminders_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final leads = appState.leads;
    final followUps = leads.where((lead) => lead.nextFollowUpAt != null).length;
    final interested = leads
        .where((lead) => lead.status == 'interested')
        .length;
    final recentLeads = leads.take(3).toList();

    return AppScaffold(
      title: 'Dashboard',
      selectedItem: 'dashboard',
      actions: [
        IconButton(
          onPressed: appState.isBusy
              ? null
              : () => context.read<AppState>().loadDashboardData(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      body: RefreshIndicator(
        onRefresh: context.read<AppState>().loadDashboardData,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hello ${appState.currentUser?.name ?? 'there'}',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep follow-ups timely, personal, and easy to act on.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            DashboardStatCard(
              label: 'Total leads',
              value: '${leads.length}',
              icon: Icons.people_alt_rounded,
              color: theme.colorScheme.primary,
              onTap: () => _open(context, const LeadsListScreen()),
            ),
            DashboardStatCard(
              label: 'Today reminders',
              value: '${appState.todayReminders.length}',
              icon: Icons.alarm_rounded,
              color: theme.colorScheme.secondary,
              onTap: () => _open(context, const RemindersScreen()),
            ),
            DashboardStatCard(
              label: 'Interested leads',
              value: '$interested',
              icon: Icons.thumb_up_alt_rounded,
              color: Colors.teal,
              onTap: () => _open(context, const LeadsListScreen()),
            ),
            DashboardStatCard(
              label: 'Scheduled follow-ups',
              value: '$followUps',
              icon: Icons.event_available_rounded,
              color: Colors.indigo,
              onTap: () => _open(context, const LeadsListScreen()),
            ),
            const SizedBox(height: 18),
            Text(
              'Quick actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: () => _open(context, const AddLeadScreen()),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Add lead'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _open(context, const AIReplyScreen()),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Generate reply'),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _open(context, const BusinessProfileScreen()),
                  icon: const Icon(Icons.business_center_rounded),
                  label: const Text('Business profile'),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent leads',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextButton(
                  onPressed: () => _open(context, const LeadsListScreen()),
                  child: const Text('View all'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (recentLeads.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.person_search_rounded, size: 36),
                      const SizedBox(height: 10),
                      const Text(
                        'No leads yet. Add your first lead to get started.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () => _open(context, const AddLeadScreen()),
                        child: const Text('Add first lead'),
                      ),
                    ],
                  ),
                ),
              ),
            ...recentLeads.map(
              (lead) =>
                  LeadCard(lead: lead, onTap: () => _openLead(context, lead)),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  void _openLead(BuildContext context, LeadModel lead) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => LeadDetailsScreen(lead: lead)));
  }
}
