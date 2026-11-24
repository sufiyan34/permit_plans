import 'package:intl/intl.dart';

class AdminDashboardSnapshot {
  const AdminDashboardSnapshot({
    required this.metrics,
    required this.paymentProviderIntegrated,
    required this.paymentLedgerAvailable,
    required this.recentUsers,
    required this.recentWorkItems,
  });

  final Map<String, int> metrics;
  final bool paymentProviderIntegrated;
  final bool paymentLedgerAvailable;
  final List<AdminUserRecord> recentUsers;
  final List<AdminWorkItemRecord> recentWorkItems;

  int metric(String key) => metrics[key] ?? 0;

  factory AdminDashboardSnapshot.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['metrics'];
    final Map<String, int> metricsMap = rawMetrics is Map
        ? <String, int>{
            for (final entry in rawMetrics.entries)
              entry.key.toString(): _asInt(entry.value),
          }
        : <String, int>{};

    final rawPayment = json['payment_monitor'];
    final payment = rawPayment is Map
        ? Map<String, dynamic>.from(rawPayment)
        : <String, dynamic>{};

    return AdminDashboardSnapshot(
      metrics: metricsMap,
      paymentProviderIntegrated: payment['provider_integrated'] == true,
      paymentLedgerAvailable: payment['ledger_available'] == true,
      recentUsers: _jsonList(json['recent_users'])
          .map(AdminUserRecord.fromJson)
          .toList(growable: false),
      recentWorkItems: _jsonList(json['recent_work_items'])
          .map(AdminWorkItemRecord.fromJson)
          .toList(growable: false),
    );
  }
}

class AdminUserRecord {
  const AdminUserRecord({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.countryName,
    required this.profileCompleted,
    required this.createdAt,
  });

  final String userId;
  final String fullName;
  final String email;
  final String role;
  final String? countryName;
  final bool profileCompleted;
  final DateTime? createdAt;

  factory AdminUserRecord.fromJson(Map<String, dynamic> json) {
    return AdminUserRecord(
      userId: (json['user_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? 'WorkBridge user').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'unknown').toString(),
      countryName: _nullableText(json['country_name']),
      profileCompleted: json['profile_completed'] == true,
      createdAt: _asDate(json['created_at']),
    );
  }
}

class AdminWorkItemRecord {
  const AdminWorkItemRecord({
    required this.taskId,
    required this.taskTitle,
    required this.category,
    required this.taskStatus,
    required this.quoteStatus,
    required this.contractId,
    required this.contractStatus,
    required this.currency,
    required this.agreedAmountMinor,
    required this.clientName,
    required this.engineerName,
    required this.updatedAt,
  });

  final String taskId;
  final String taskTitle;
  final String category;
  final String taskStatus;
  final String? quoteStatus;
  final String? contractId;
  final String? contractStatus;
  final String currency;
  final int? agreedAmountMinor;
  final String clientName;
  final String engineerName;
  final DateTime? updatedAt;

  bool get hasContract => contractId != null && contractId!.isNotEmpty;

  String get formattedAgreedAmount {
    final minor = agreedAmountMinor;
    if (minor == null || currency.isEmpty) return 'Not contracted';
    final value = NumberFormat('#,##0.00').format(minor / 100);
    return '$currency $value';
  }

  String get effectiveStatus => contractStatus ?? taskStatus;

  factory AdminWorkItemRecord.fromJson(Map<String, dynamic> json) {
    final amount = json['agreed_amount_minor'];
    return AdminWorkItemRecord(
      taskId: (json['task_id'] ?? '').toString(),
      taskTitle: (json['task_title'] ?? 'Untitled task').toString(),
      category: (json['category'] ?? '').toString(),
      taskStatus: (json['task_status'] ?? 'unknown').toString(),
      quoteStatus: _nullableText(json['quote_status']),
      contractId: _nullableText(json['contract_id']),
      contractStatus: _nullableText(json['contract_status']),
      currency: (json['currency'] ?? 'USD').toString(),
      agreedAmountMinor: amount == null ? null : _asInt(amount),
      clientName: (json['client_name'] ?? 'Client').toString(),
      engineerName: (json['engineer_name'] ?? 'Engineer').toString(),
      updatedAt: _asDate(json['updated_at']),
    );
  }
}

List<Map<String, dynamic>> _jsonList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((row) => Map<String, dynamic>.from(row))
      .toList(growable: false);
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _asDate(dynamic value) {
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

String? _nullableText(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty || text == 'null' ? null : text;
}
