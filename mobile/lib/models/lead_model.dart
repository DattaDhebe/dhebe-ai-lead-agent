class LeadModel {
  const LeadModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.source,
    required this.serviceInterested,
    required this.customerMessage,
    required this.status,
    this.email,
    this.nextFollowUpAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final int id;
  final String name;
  final String phone;
  final String? email;
  final String source;
  final String serviceInterested;
  final String customerMessage;
  final String status;
  final DateTime? nextFollowUpAt;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: (json['name'] ?? '') as String,
      phone: (json['phone'] ?? '') as String,
      email: json['email'] as String?,
      source: (json['source'] ?? '') as String,
      serviceInterested: (json['service_interested'] ?? '') as String,
      customerMessage: (json['customer_message'] ?? '') as String,
      status: (json['status'] ?? 'new') as String,
      nextFollowUpAt: _parseDate(json['next_follow_up_at'] as String?),
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['created_at'] as String?),
      updatedAt: _parseDate(json['updated_at'] as String?),
    );
  }

  LeadModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? source,
    String? serviceInterested,
    String? customerMessage,
    String? status,
    DateTime? nextFollowUpAt,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LeadModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      source: source ?? this.source,
      serviceInterested: serviceInterested ?? this.serviceInterested,
      customerMessage: customerMessage ?? this.customerMessage,
      status: status ?? this.status,
      nextFollowUpAt: nextFollowUpAt ?? this.nextFollowUpAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.replaceFirst(' ', 'T'));
  }
}
