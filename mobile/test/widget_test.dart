import 'package:flutter_test/flutter_test.dart';

import 'package:dhebe_ai_lead_agent/models/lead_model.dart';

void main() {
  test('LeadModel parses API JSON safely', () {
    final lead = LeadModel.fromJson({
      'id': 1,
      'name': 'Rohit Sharma',
      'phone': '+919876543210',
      'source': 'WhatsApp',
      'service_interested': 'Website redesign',
      'customer_message': 'Need pricing details',
      'status': 'new',
      'next_follow_up_at': '2026-05-21 10:30:00',
    });

    expect(lead.id, 1);
    expect(lead.name, 'Rohit Sharma');
    expect(lead.status, 'new');
    expect(lead.nextFollowUpAt, isNotNull);
  });
}
