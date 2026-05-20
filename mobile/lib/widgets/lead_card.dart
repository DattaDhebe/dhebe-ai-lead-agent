import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/lead_model.dart';

class LeadCard extends StatelessWidget {
  const LeadCard({super.key, required this.lead, this.onTap});

  final LeadModel lead;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, lead.status);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      lead.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text(AppConstants.prettifyStatus(lead.status)),
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    side: BorderSide.none,
                    labelStyle: TextStyle(color: statusColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(lead.serviceInterested, style: theme.textTheme.bodyLarge),
              const SizedBox(height: 4),
              Text(lead.phone),
              const SizedBox(height: 10),
              Text(
                'Next follow-up: ${AppConstants.formatReadableDateTime(lead.nextFollowUpAt)}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ThemeData theme, String status) {
    switch (status) {
      case 'contacted':
        return theme.colorScheme.primary;
      case 'interested':
        return Colors.teal;
      case 'converted':
        return Colors.green;
      case 'lost':
        return Colors.redAccent;
      default:
        return theme.colorScheme.secondary;
    }
  }
}
