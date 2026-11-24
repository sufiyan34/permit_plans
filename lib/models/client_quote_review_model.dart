import 'package:intl/intl.dart';

/// Public, client-visible details for one Engineer quote.
/// Sensitive fields (email, phone, payout details) are deliberately omitted.
class ClientQuoteReviewItem {
  const ClientQuoteReviewItem({
    required this.quoteId,
    required this.taskId,
    required this.engineerId,
    required this.engineerName,
    required this.engineerHeadline,
    required this.taskTitle,
    required this.taskCategory,
    required this.currency,
    required this.amountMinor,
    required this.deliveryDays,
    required this.scopeOfWork,
    required this.includedRevisions,
    required this.status,
    required this.submittedAt,
    this.engineerAvatarUrl,
    this.engineerCountry,
    this.engineerExperienceLevel,
    this.engineerYearsExperience = 0,
    this.taskDescription = '',
    this.notes,
  });

  final String quoteId;
  final String taskId;
  final String engineerId;
  final String engineerName;
  final String engineerHeadline;
  final String taskTitle;
  final String taskCategory;
  final String currency;
  final int amountMinor;
  final int deliveryDays;
  final String scopeOfWork;
  final int includedRevisions;
  final String status;
  final DateTime submittedAt;
  final String? engineerAvatarUrl;
  final String? engineerCountry;
  final String? engineerExperienceLevel;
  final int engineerYearsExperience;
  final String taskDescription;
  final String? notes;

  factory ClientQuoteReviewItem.fromJson(Map<String, dynamic> json) {
    return ClientQuoteReviewItem(
      quoteId: _string(json['quote_id']),
      taskId: _string(json['task_id']),
      engineerId: _string(json['engineer_id']),
      engineerName: _string(json['engineer_name'], fallback: 'Engineer'),
      engineerHeadline: _string(json['engineer_headline']),
      taskTitle: _string(json['task_title'], fallback: 'Untitled task'),
      taskCategory: _string(json['task_category']),
      currency: _string(json['currency'], fallback: 'USD').toUpperCase(),
      amountMinor: _int(json['amount_minor']),
      deliveryDays: _int(json['delivery_days']),
      scopeOfWork: _string(json['scope_of_work']),
      includedRevisions: _int(json['included_revisions']),
      status: _string(json['status']),
      submittedAt: DateTime.tryParse(_string(json['submitted_at']))?.toLocal() ??
          DateTime.now(),
      engineerAvatarUrl: _nullableString(json['engineer_avatar_url']),
      engineerCountry: _nullableString(json['engineer_country']),
      engineerExperienceLevel: _nullableString(json['engineer_experience_level']),
      engineerYearsExperience: _int(json['engineer_years_experience']),
      taskDescription: _string(json['task_description']),
      notes: _nullableString(json['notes']),
    );
  }

  String get initials {
    final parts = engineerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }

  int get currencyFractionDigits => _fractionDigits(currency);

  double get amountMajor =>
      amountMinor / (currencyFractionDigits == 0
          ? 1
          : currencyFractionDigits == 3
              ? 1000
              : 100);

  String get formattedAmount => NumberFormat.currency(
        name: currency,
        decimalDigits: currencyFractionDigits,
      ).format(amountMajor);

  String get statusLabel {
    switch (status) {
      case 'pending_client_review':
        return 'Needs your review';
      case 'engineer_countered':
        return 'Engineer counteroffer';
      case 'client_countered':
        return 'Waiting for engineer';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'withdrawn':
        return 'Withdrawn';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  bool get canRespond =>
      status == 'pending_client_review' || status == 'engineer_countered';

  String get amountInput {
    final digits = currencyFractionDigits;
    if (digits == 0) return amountMinor.toString();
    final divisor = digits == 3 ? 1000 : 100;
    return (amountMinor / divisor).toStringAsFixed(digits);
  }

  static int _fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (const {
      'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG',
      'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF'
    }.contains(code)) return 0;
    if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}
        .contains(code)) return 3;
    return 2;
  }

  static String _string(dynamic value, {String fallback = ''}) =>
      value == null ? fallback : value.toString();

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class QuoteRevisionItem {
  const QuoteRevisionItem({
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

  factory QuoteRevisionItem.fromJson(Map<String, dynamic> json) {
    return QuoteRevisionItem(
      revisionNumber: _int(json['revision_number']),
      proposedBy: (json['proposed_by'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      amountMinor: _int(json['amount_minor']),
      currency: (json['currency'] ?? 'USD').toString(),
      deliveryDays: _int(json['delivery_days']),
      scopeOfWork: (json['scope_of_work'] ?? '').toString(),
      includedRevisions: _int(json['included_revisions']),
      createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ??
          DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  String get formattedAmount {
    final digits = ClientQuoteReviewItem._fractionDigits(currency);
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return NumberFormat.currency(name: currency, decimalDigits: digits)
        .format(amountMinor / divisor);
  }

  String get actorLabel => proposedBy == 'client' ? 'You' : 'Engineer';

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
