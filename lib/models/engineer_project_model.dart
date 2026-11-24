import 'package:intl/intl.dart';

/// Read-only project view returned by the secure Engineer projects RPC.
/// Values are sourced from the immutable contract snapshot plus linked task
/// and Client display details. This model does not imply that a payment cleared.
class EngineerProjectModel {
  const EngineerProjectModel({
    required this.contractId,
    required this.taskId,
    required this.quoteId,
    required this.clientId,
    required this.clientName,
    required this.taskTitle,
    required this.taskDescription,
    required this.taskCategory,
    required this.currency,
    required this.amountMinor,
    required this.deliveryDays,
    required this.scopeOfWork,
    required this.includedRevisions,
    required this.commissionBps,
    required this.platformFeeMinor,
    required this.engineerNetMinor,
    required this.contractStatus,
    required this.createdAt,
    this.clientCompanyName,
    this.clientCountryName,
    this.clientAvatarUrl,
    this.requiredSkills = const [],
    this.deadlineAt,
    this.notes,
    this.confirmedAt,
    this.updatedAt,
  });

  final String contractId;
  final String taskId;
  final String quoteId;
  final String clientId;
  final String clientName;
  final String? clientCompanyName;
  final String? clientCountryName;
  final String? clientAvatarUrl;
  final String taskTitle;
  final String taskDescription;
  final String taskCategory;
  final List<String> requiredSkills;
  final DateTime? deadlineAt;
  final String currency;
  final int amountMinor;
  final int deliveryDays;
  final String scopeOfWork;
  final int includedRevisions;
  final String? notes;
  final int commissionBps;
  final int platformFeeMinor;
  final int engineerNetMinor;
  final String contractStatus;
  final DateTime? confirmedAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  String get statusLabel {
    switch (contractStatus) {
      case 'awaiting_payment':
        return 'Awaiting funding';
      case 'funded':
        return 'Funded';
      case 'in_progress':
        return 'In progress';
      case 'submitted':
        return 'In client review';
      case 'revision_requested':
        return 'Revision requested';
      case 'completed':
        return 'Completed';
      case 'disputed':
        return 'Disputed';
      case 'cancelled':
        return 'Cancelled';
      case 'refund_pending':
        return 'Refund pending';
      case 'refunded':
        return 'Refunded';
      default:
        return 'Unknown status';
    }
  }

  String get statusGroup {
    switch (contractStatus) {
      case 'awaiting_payment':
        return 'awaiting';
      case 'funded':
      case 'in_progress':
        return 'active';
      case 'submitted':
        return 'review';
      case 'revision_requested':
        return 'revision';
      case 'completed':
        return 'completed';
      default:
        return 'other';
    }
  }

  String formatMinor(int minor) {
    final digits = _fractionDigits(currency);
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return NumberFormat.currency(name: currency, decimalDigits: digits)
        .format(minor / divisor);
  }

  String get formattedAmount => formatMinor(amountMinor);
  String get formattedPlatformFee => formatMinor(platformFeeMinor);
  String get formattedEngineerNet => formatMinor(engineerNetMinor);

  String get commissionPercent =>
      (commissionBps / 100).toStringAsFixed(commissionBps % 100 == 0 ? 0 : 2);

  String get clientDisplayName =>
      (clientCompanyName?.trim().isNotEmpty ?? false)
          ? clientCompanyName!.trim()
          : clientName;

  String get contractShortId => contractId.length <= 8
      ? contractId
      : contractId.substring(contractId.length - 8).toUpperCase();

  String get deadlineLabel => deadlineAt == null
      ? 'Not set by Client'
      : DateFormat('dd MMM yyyy').format(deadlineAt!.toLocal());

  String get confirmedLabel => confirmedAt == null
      ? 'Confirmation date unavailable'
      : DateFormat('dd MMM yyyy').format(confirmedAt!.toLocal());

  factory EngineerProjectModel.fromJson(Map<String, dynamic> json) {
    return EngineerProjectModel(
      contractId: _string(json['contract_id']),
      taskId: _string(json['task_id']),
      quoteId: _string(json['quote_id']),
      clientId: _string(json['client_id']),
      clientName: _string(json['client_name'], fallback: 'Marketplace client'),
      clientCompanyName: _nullable(json['client_company_name']),
      clientCountryName: _nullable(json['client_country_name']),
      clientAvatarUrl: _nullable(json['client_avatar_url']),
      taskTitle: _string(json['task_title'], fallback: 'Untitled project'),
      taskDescription: _string(json['task_description']),
      taskCategory: _string(json['task_category'], fallback: 'Project'),
      requiredSkills: _stringList(json['required_skills']),
      deadlineAt: _date(json['deadline_at']),
      currency: _string(json['currency'], fallback: 'USD').toUpperCase(),
      amountMinor: _int(json['amount_minor']),
      deliveryDays: _int(json['delivery_days']),
      scopeOfWork: _string(json['scope_of_work']),
      includedRevisions: _int(json['included_revisions']),
      notes: _nullable(json['notes']),
      commissionBps: _int(json['commission_bps'], fallback: 500),
      platformFeeMinor: _int(json['platform_fee_minor']),
      engineerNetMinor: _int(json['engineer_net_minor']),
      contractStatus: _string(json['contract_status']),
      confirmedAt: _date(json['confirmed_at']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      updatedAt: _date(json['updated_at']),
    );
  }

  static int _fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (const {
      'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG',
      'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
    }.contains(code)) return 0;
    if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}
        .contains(code)) return 3;
    return 2;
  }

  static String _string(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  static String? _nullable(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
