import 'package:intl/intl.dart';

/// One quote belonging to the signed-in Engineer.
/// Only public Client details and contract/quote terms are exposed.
class EngineerNegotiationItem {
  const EngineerNegotiationItem({
    required this.quoteId,
    required this.taskId,
    required this.clientId,
    required this.clientName,
    required this.taskTitle,
    required this.taskCategory,
    required this.taskDescription,
    required this.currency,
    required this.originalAmountMinor,
    required this.currentAmountMinor,
    required this.originalDeliveryDays,
    required this.currentDeliveryDays,
    required this.originalScopeOfWork,
    required this.currentScopeOfWork,
    required this.originalIncludedRevisions,
    required this.currentIncludedRevisions,
    required this.status,
    required this.updatedAt,
    this.clientAvatarUrl,
    this.clientCountry,
    this.currentNotes,
  });

  final String quoteId;
  final String taskId;
  final String clientId;
  final String clientName;
  final String? clientAvatarUrl;
  final String? clientCountry;
  final String taskTitle;
  final String taskCategory;
  final String taskDescription;
  final String currency;
  final int originalAmountMinor;
  final int currentAmountMinor;
  final int originalDeliveryDays;
  final int currentDeliveryDays;
  final String originalScopeOfWork;
  final String currentScopeOfWork;
  final int originalIncludedRevisions;
  final int currentIncludedRevisions;
  final String? currentNotes;
  final String status;
  final DateTime updatedAt;

  bool get needsEngineerResponse => status == 'client_countered';
  bool get waitingForClient =>
      status == 'engineer_countered' || status == 'pending_client_review';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  String get formattedOriginalAmount =>
      _formatMoney(originalAmountMinor, currency);
  String get formattedCurrentAmount =>
      _formatMoney(currentAmountMinor, currency);

  String get statusLabel {
    switch (status) {
      case 'client_countered':
        return 'Your response needed';
      case 'engineer_countered':
        return 'Waiting for client';
      case 'pending_client_review':
        return 'Waiting for client';
      case 'accepted':
        return 'Agreed · payment next';
      case 'rejected':
        return 'Negotiation closed';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  factory EngineerNegotiationItem.fromJson(Map<String, dynamic> json) {
    return EngineerNegotiationItem(
      quoteId: _string(json['quote_id']),
      taskId: _string(json['task_id']),
      clientId: _string(json['client_id']),
      clientName: _string(json['client_name'], fallback: 'Client'),
      clientAvatarUrl: _nullable(json['client_avatar_url']),
      clientCountry: _nullable(json['client_country']),
      taskTitle: _string(json['task_title'], fallback: 'Untitled task'),
      taskCategory: _string(json['task_category'], fallback: 'Project'),
      taskDescription: _string(json['task_description']),
      currency: _string(json['currency'], fallback: 'USD').toUpperCase(),
      originalAmountMinor: _int(json['original_amount_minor']),
      currentAmountMinor: _int(json['current_amount_minor']),
      originalDeliveryDays: _int(json['original_delivery_days']),
      currentDeliveryDays: _int(json['current_delivery_days']),
      originalScopeOfWork: _string(json['original_scope_of_work']),
      currentScopeOfWork: _string(json['current_scope_of_work']),
      originalIncludedRevisions: _int(json['original_included_revisions']),
      currentIncludedRevisions: _int(json['current_included_revisions']),
      currentNotes: _nullable(json['current_notes']),
      status: _string(json['status']),
      updatedAt:
          DateTime.tryParse(_string(json['updated_at']))?.toLocal() ??
          DateTime.now(),
    );
  }

  String get clientInitials {
    final parts = clientName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'C';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  static String _formatMoney(int minor, String currency) {
    final digits = _fractionDigits(currency);
    final divisor = digits == 0
        ? 1
        : digits == 3
        ? 1000
        : 100;
    return NumberFormat.currency(
      name: currency,
      decimalDigits: digits,
    ).format(minor / divisor);
  }

  static int _fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (const {
      'BIF',
      'CLP',
      'DJF',
      'GNF',
      'ISK',
      'JPY',
      'KMF',
      'KRW',
      'PYG',
      'RWF',
      'UGX',
      'VND',
      'VUV',
      'XAF',
      'XOF',
      'XPF',
    }.contains(code))
      return 0;
    if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}.contains(code))
      return 3;
    return 2;
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class EngineerQuoteRevision {
  const EngineerQuoteRevision({
    required this.revisionNumber,
    required this.proposedBy,
    required this.action,
    required this.amountMinor,
    required this.currency,
    required this.deliveryDays,
    required this.scopeOfWork,
    required this.includedRevisions,
    required this.createdAt,
    this.notes,
  });

  final int revisionNumber;
  final String proposedBy;
  final String action;
  final int amountMinor;
  final String currency;
  final int deliveryDays;
  final String scopeOfWork;
  final int includedRevisions;
  final DateTime createdAt;
  final String? notes;

  String get formattedAmount {
    final digits = EngineerNegotiationItem._fractionDigits(currency);
    final divisor = digits == 0
        ? 1
        : digits == 3
        ? 1000
        : 100;
    return NumberFormat.currency(
      name: currency,
      decimalDigits: digits,
    ).format(amountMinor / divisor);
  }

  factory EngineerQuoteRevision.fromJson(Map<String, dynamic> json) {
    return EngineerQuoteRevision(
      revisionNumber: _int(json['revision_number']),
      proposedBy: _string(json['proposed_by']),
      action: _string(json['action']),
      amountMinor: _int(json['amount_minor']),
      currency: _string(json['currency'], fallback: 'USD').toUpperCase(),
      deliveryDays: _int(json['delivery_days']),
      scopeOfWork: _string(json['scope_of_work']),
      includedRevisions: _int(json['included_revisions']),
      createdAt:
          DateTime.tryParse(_string(json['created_at']))?.toLocal() ??
          DateTime.now(),
      notes: _nullable(json['notes']),
    );
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;

    final result = value.toString().trim();

    return result.isEmpty ? fallback : result;
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
