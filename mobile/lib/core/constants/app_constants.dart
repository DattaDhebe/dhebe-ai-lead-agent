import 'package:intl/intl.dart';

class AppConstants {
  static const String appName = 'Dhebe AI Lead Agent';
  static const String apiBaseUrl = 'https://dhebe.com/api';

  static const List<String> leadStatuses = [
    'new',
    'contacted',
    'interested',
    'converted',
    'lost',
  ];

  static const List<String> leadSources = [
    'WhatsApp',
    'Website',
    'Facebook',
    'Instagram',
    'Referral',
    'Walk-in',
    'Other',
  ];

  static String formatApiDateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(value);
  }

  static String formatReadableDateTime(DateTime? value) {
    if (value == null) {
      return 'Not scheduled';
    }

    return DateFormat('dd MMM yyyy, hh:mm a').format(value);
  }

  static String prettifyStatus(String value) {
    if (value.isEmpty) {
      return value;
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  static String normalizePhone(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
