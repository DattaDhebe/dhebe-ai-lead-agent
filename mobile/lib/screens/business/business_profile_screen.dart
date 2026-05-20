import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/business_profile_model.dart';
import '../../providers/app_state.dart';
import '../../widgets/app_scaffold.dart';

class BusinessProfileScreen extends StatefulWidget {
  const BusinessProfileScreen({super.key});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _websiteController = TextEditingController();
  final _addressController = TextEditingController();
  final _servicesController = TextEditingController();
  final _faqController = TextEditingController();
  final _toneController = TextEditingController();
  final _policyController = TextEditingController();
  bool _hydrated = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final appState = context.read<AppState>();
      await appState.loadBusinessProfile();
      if (!mounted) {
        return;
      }
      _populate(appState.businessProfile);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hydrated) {
      return;
    }
    _populate(context.read<AppState>().businessProfile);
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _servicesController.dispose();
    _faqController.dispose();
    _toneController.dispose();
    _policyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return AppScaffold(
      title: 'Business Profile',
      selectedItem: 'business_profile',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(labelText: 'Business name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ownerNameController,
              decoration: const InputDecoration(labelText: 'Owner / rep name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Business phone'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Business email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Website'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _servicesController,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Services offered'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _faqController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'FAQs / approved facts',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _toneController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Tone notes'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _policyController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Policy notes / things AI should avoid claiming',
              ),
            ),
            if (appState.lastError != null) ...[
              const SizedBox(height: 12),
              Text(
                appState.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: appState.isBusy ? null : _saveProfile,
              child: Text(appState.isBusy ? 'Saving...' : 'Save profile'),
            ),
          ],
        ),
      ),
    );
  }

  void _populate(BusinessProfileModel profile) {
    _businessNameController.text = profile.businessName;
    _ownerNameController.text = profile.ownerName;
    _phoneController.text = profile.businessPhone;
    _emailController.text = profile.businessEmail;
    _websiteController.text = profile.website;
    _addressController.text = profile.address;
    _servicesController.text = profile.servicesText;
    _faqController.text = profile.faqText;
    _toneController.text = profile.toneNotes;
    _policyController.text = profile.policyNotes;
    _hydrated = true;
  }

  Future<void> _saveProfile() async {
    await context.read<AppState>().saveBusinessProfile(
      BusinessProfileModel(
        businessName: _businessNameController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        businessPhone: _phoneController.text.trim(),
        businessEmail: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        address: _addressController.text.trim(),
        servicesText: _servicesController.text.trim(),
        faqText: _faqController.text.trim(),
        toneNotes: _toneController.text.trim(),
        policyNotes: _policyController.text.trim(),
      ),
    );
  }
}
