import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/lead_card.dart';
import 'add_lead_screen.dart';
import 'lead_details_screen.dart';

class LeadsListScreen extends StatelessWidget {
  const LeadsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'Leads',
      selectedItem: 'leads',
      actions: [
        IconButton(
          onPressed: () => context.read<AppState>().fetchLeads(),
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const AddLeadScreen()));
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Lead'),
      ),
      body: RefreshIndicator(
        onRefresh: context.read<AppState>().fetchLeads,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (appState.leads.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    children: [
                      const Icon(Icons.people_outline_rounded, size: 34),
                      const SizedBox(height: 10),
                      const Text(
                        'No leads available yet. Add one to start tracking follow-ups.',
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AddLeadScreen(),
                            ),
                          );
                        },
                        child: const Text('Create lead'),
                      ),
                    ],
                  ),
                ),
              ),
            ...appState.leads.map(
              (lead) => LeadCard(
                lead: lead,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LeadDetailsScreen(lead: lead),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
