import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/storage/secure_storage_service.dart';
import '../models/business_profile_model.dart';
import '../models/lead_model.dart';
import '../models/reminder_model.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AppState extends ChangeNotifier {
  AppState({SecureStorageService? storageService, ApiService? apiService})
    : _storageService = storageService ?? SecureStorageService(),
      _apiService = apiService ?? ApiService();

  final SecureStorageService _storageService;
  final ApiService _apiService;

  bool initialized = false;
  bool isBusy = false;
  ThemeMode themeMode = ThemeMode.system;
  UserModel? currentUser;
  String? _token;
  String? lastError;
  String? generatedReply;
  List<LeadModel> leads = <LeadModel>[];
  List<ReminderModel> todayReminders = <ReminderModel>[];
  BusinessProfileModel businessProfile = BusinessProfileModel.empty();

  bool get isAuthenticated => _token != null && currentUser != null;

  Future<void> initialize() async {
    themeMode = await _storageService.readThemeMode();
    _token = await _storageService.readToken();
    final rawUser = await _storageService.readUserJson();

    if (_token != null) {
      _apiService.token = _token;
    }

    if (rawUser != null && rawUser.isNotEmpty) {
      currentUser = UserModel.fromJson(
        jsonDecode(rawUser) as Map<String, dynamic>,
      );
    }

    initialized = true;
    notifyListeners();

    if (isAuthenticated) {
      await loadDashboardData(silent: true);
    }
  }

  Future<bool> login(String email, String password) async {
    return _execute<bool>(() async {
      final response = await _apiService.post(
        'auth/login.php',
        body: {'email': email.trim(), 'password': password},
      );

      final data = response['data'] as Map<String, dynamic>;
      await _storeSession(data);
      await loadDashboardData(silent: true);
      return true;
    }, fallback: false);
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String businessName,
  }) async {
    return _execute<bool>(() async {
      final response = await _apiService.post(
        'auth/register.php',
        body: {
          'name': name.trim(),
          'email': email.trim(),
          'phone': phone.trim(),
          'password': password,
          'business_name': businessName.trim(),
        },
      );

      final data = response['data'] as Map<String, dynamic>;
      await _storeSession(data);
      await loadDashboardData(silent: true);
      return true;
    }, fallback: false);
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    leads = <LeadModel>[];
    todayReminders = <ReminderModel>[];
    businessProfile = BusinessProfileModel.empty();
    generatedReply = null;
    lastError = null;
    _apiService.token = null;
    await _storageService.clearSession();
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    await _storageService.saveThemeMode(mode);
    notifyListeners();
  }

  Future<void> loadDashboardData({bool silent = false}) async {
    await _execute<void>(() async {
      await Future.wait([
        fetchLeads(silent: true),
        fetchTodayReminders(silent: true),
        loadBusinessProfile(silent: true),
      ]);

      if (!silent) {
        notifyListeners();
      }
    });
  }

  Future<bool> fetchLeads({bool silent = false}) async {
    return _execute<bool>(
      () async {
        final response = await _apiService.get('leads/list.php');
        final data = response['data'] as Map<String, dynamic>;
        final items = (data['leads'] as List<dynamic>? ?? const [])
            .map((item) => LeadModel.fromJson(item as Map<String, dynamic>))
            .toList();
        items.sort(_sortLeads);
        leads = items;

        if (!silent) {
          notifyListeners();
        }

        return true;
      },
      fallback: false,
      silent: silent,
    );
  }

  Future<Map<String, dynamic>?> fetchLeadBundle(int leadId) async {
    return _execute<Map<String, dynamic>?>(() async {
      final response = await _apiService.get(
        'leads/details.php',
        queryParameters: {'id': '$leadId'},
      );
      final data = response['data'] as Map<String, dynamic>;
      final lead = LeadModel.fromJson(data['lead'] as Map<String, dynamic>);
      _upsertLead(lead);
      return data;
    });
  }

  Future<bool> createLead(Map<String, dynamic> payload) async {
    return _execute<bool>(() async {
      final response = await _apiService.post(
        'leads/create.php',
        body: payload,
      );
      final lead = LeadModel.fromJson(
        (response['data'] as Map<String, dynamic>)['lead']
            as Map<String, dynamic>,
      );
      _upsertLead(lead);
      leads.sort(_sortLeads);
      notifyListeners();
      return true;
    }, fallback: false);
  }

  Future<bool> updateLead({
    required int id,
    required String name,
    required String phone,
    required String email,
    required String source,
    required String serviceInterested,
    required String customerMessage,
    required String status,
    required DateTime? nextFollowUpAt,
    required String notes,
    String? newNote,
  }) async {
    return _execute<bool>(() async {
      await _apiService.post(
        'leads/update.php',
        body: {
          'id': id,
          'name': name.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'source': source.trim(),
          'service_interested': serviceInterested.trim(),
          'customer_message': customerMessage.trim(),
          'status': status,
          'next_follow_up_at': nextFollowUpAt == null
              ? ''
              : AppConstants.formatApiDateTime(nextFollowUpAt),
          'notes': notes.trim(),
          'new_note': newNote?.trim() ?? '',
        },
      );

      await fetchLeads(silent: true);
      notifyListeners();
      return true;
    }, fallback: false);
  }

  Future<bool> deleteLead(int id) async {
    return _execute<bool>(() async {
      await _apiService.post('leads/delete.php', body: {'id': id});
      leads.removeWhere((lead) => lead.id == id);
      todayReminders = todayReminders
          .where((item) => item.leadId != id)
          .toList();
      notifyListeners();
      return true;
    }, fallback: false);
  }

  Future<String?> generateAiReply({
    int? leadId,
    required String customerMessage,
    required String customerName,
    required String serviceInterested,
    required String source,
  }) async {
    return _execute<String?>(() async {
      final response = await _apiService.post(
        'ai/generate-reply.php',
        body: {
          'lead_id': leadId,
          'customer_message': customerMessage.trim(),
          'customer_name': customerName.trim(),
          'service_interested': serviceInterested.trim(),
          'source': source.trim(),
        },
      );

      generatedReply =
          ((response['data'] as Map<String, dynamic>)['reply'] ?? '') as String;
      notifyListeners();
      return generatedReply;
    });
  }

  Future<bool> fetchTodayReminders({bool silent = false}) async {
    return _execute<bool>(
      () async {
        final response = await _apiService.get('reminders/today.php');
        final data = response['data'] as Map<String, dynamic>;
        todayReminders = (data['reminders'] as List<dynamic>? ?? const [])
            .map((item) => ReminderModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!silent) {
          notifyListeners();
        }

        return true;
      },
      fallback: false,
      silent: silent,
    );
  }

  Future<bool> createReminder({
    required String title,
    required DateTime reminderAt,
    int? leadId,
    String notes = '',
  }) async {
    return _execute<bool>(() async {
      await _apiService.post(
        'reminders/create.php',
        body: {
          'title': title.trim(),
          'lead_id': leadId,
          'reminder_at': AppConstants.formatApiDateTime(reminderAt),
          'notes': notes.trim(),
        },
      );
      await fetchTodayReminders(silent: true);
      notifyListeners();
      return true;
    }, fallback: false);
  }

  Future<bool> loadBusinessProfile({bool silent = false}) async {
    return _execute<bool>(
      () async {
        final response = await _apiService.get('business-profile/get.php');
        businessProfile = BusinessProfileModel.fromJson(
          (response['data'] as Map<String, dynamic>)['profile']
              as Map<String, dynamic>,
        );

        if (!silent) {
          notifyListeners();
        }

        return true;
      },
      fallback: false,
      silent: silent,
    );
  }

  Future<bool> saveBusinessProfile(BusinessProfileModel profile) async {
    return _execute<bool>(() async {
      await _apiService.post(
        'business-profile/save.php',
        body: profile.toJson(),
      );
      businessProfile = profile;
      notifyListeners();
      return true;
    }, fallback: false);
  }

  Future<bool> submitFeedback({required String message, int? rating}) async {
    return _execute<bool>(() async {
      await _apiService.post(
        'feedback/create.php',
        body: {'message': message.trim(), 'rating': rating},
      );
      return true;
    }, fallback: false);
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    final token = (data['token'] ?? '') as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);

    _token = token;
    currentUser = user;
    _apiService.token = token;

    await _storageService.saveToken(token);
    await _storageService.saveUserJson(jsonEncode(user.toJson()));
    notifyListeners();
  }

  Future<T> _execute<T>(
    Future<T> Function() callback, {
    T? fallback,
    bool silent = false,
  }) async {
    try {
      lastError = null;
      if (!silent) {
        isBusy = true;
        notifyListeners();
      }

      return await callback();
    } on ApiException catch (error) {
      lastError = error.message;
      notifyListeners();
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    } catch (_) {
      lastError = 'Something went wrong. Please try again.';
      notifyListeners();
      if (fallback != null) {
        return fallback;
      }
      rethrow;
    } finally {
      if (!silent) {
        isBusy = false;
        notifyListeners();
      }
    }
  }

  void _upsertLead(LeadModel lead) {
    final index = leads.indexWhere((item) => item.id == lead.id);

    if (index >= 0) {
      leads[index] = lead;
    } else {
      leads = [...leads, lead];
    }
  }

  int _sortLeads(LeadModel a, LeadModel b) {
    if (a.nextFollowUpAt == null && b.nextFollowUpAt == null) {
      return b.id.compareTo(a.id);
    }

    if (a.nextFollowUpAt == null) {
      return 1;
    }

    if (b.nextFollowUpAt == null) {
      return -1;
    }

    return a.nextFollowUpAt!.compareTo(b.nextFollowUpAt!);
  }
}
