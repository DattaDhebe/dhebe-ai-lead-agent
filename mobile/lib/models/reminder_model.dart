class ReminderModel {
  const ReminderModel({
    required this.id,
    required this.title,
    required this.reminderAt,
    required this.status,
    this.leadId,
    this.notes,
    this.leadName,
    this.leadPhone,
  });

  final int id;
  final int? leadId;
  final String title;
  final DateTime reminderAt;
  final String status;
  final String? notes;
  final String? leadName;
  final String? leadPhone;

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      leadId: (json['lead_id'] as num?)?.toInt(),
      title: (json['title'] ?? '') as String,
      reminderAt:
          DateTime.tryParse(
            ((json['reminder_at'] ?? '') as String).replaceFirst(' ', 'T'),
          ) ??
          DateTime.now(),
      status: (json['status'] ?? 'pending') as String,
      notes: json['notes'] as String?,
      leadName: json['lead_name'] as String?,
      leadPhone: json['lead_phone'] as String?,
    );
  }
}
