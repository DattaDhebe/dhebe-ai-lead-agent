class BusinessProfileModel {
  const BusinessProfileModel({
    required this.businessName,
    required this.ownerName,
    required this.businessPhone,
    required this.businessEmail,
    required this.website,
    required this.address,
    required this.servicesText,
    required this.faqText,
    required this.toneNotes,
    required this.policyNotes,
  });

  final String businessName;
  final String ownerName;
  final String businessPhone;
  final String businessEmail;
  final String website;
  final String address;
  final String servicesText;
  final String faqText;
  final String toneNotes;
  final String policyNotes;

  factory BusinessProfileModel.empty() {
    return const BusinessProfileModel(
      businessName: '',
      ownerName: '',
      businessPhone: '',
      businessEmail: '',
      website: '',
      address: '',
      servicesText: '',
      faqText: '',
      toneNotes: '',
      policyNotes: '',
    );
  }

  factory BusinessProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProfileModel(
      businessName: (json['business_name'] ?? '') as String,
      ownerName: (json['owner_name'] ?? '') as String,
      businessPhone: (json['business_phone'] ?? '') as String,
      businessEmail: (json['business_email'] ?? '') as String,
      website: (json['website'] ?? '') as String,
      address: (json['address'] ?? '') as String,
      servicesText: (json['services_text'] ?? '') as String,
      faqText: (json['faq_text'] ?? '') as String,
      toneNotes: (json['tone_notes'] ?? '') as String,
      policyNotes: (json['policy_notes'] ?? '') as String,
    );
  }

  BusinessProfileModel copyWith({
    String? businessName,
    String? ownerName,
    String? businessPhone,
    String? businessEmail,
    String? website,
    String? address,
    String? servicesText,
    String? faqText,
    String? toneNotes,
    String? policyNotes,
  }) {
    return BusinessProfileModel(
      businessName: businessName ?? this.businessName,
      ownerName: ownerName ?? this.ownerName,
      businessPhone: businessPhone ?? this.businessPhone,
      businessEmail: businessEmail ?? this.businessEmail,
      website: website ?? this.website,
      address: address ?? this.address,
      servicesText: servicesText ?? this.servicesText,
      faqText: faqText ?? this.faqText,
      toneNotes: toneNotes ?? this.toneNotes,
      policyNotes: policyNotes ?? this.policyNotes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'owner_name': ownerName,
      'business_phone': businessPhone,
      'business_email': businessEmail,
      'website': website,
      'address': address,
      'services_text': servicesText,
      'faq_text': faqText,
      'tone_notes': toneNotes,
      'policy_notes': policyNotes,
    };
  }
}
