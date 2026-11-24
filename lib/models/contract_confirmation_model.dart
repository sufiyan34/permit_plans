import 'package:intl/intl.dart';

/// Read-only snapshot of the final accepted quote and the contract, if one has
/// already been confirmed. Money values are stored in currency minor units.
class ContractConfirmationModel {
  const ContractConfirmationModel({
    required this.quoteId,
    required this.taskId,
    required this.engineerId,
    required this.engineerName,
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
    this.engineerAvatarUrl,
    this.engineerCountry,
    this.engineerHeadline,
    this.notes,
    this.contractId,
    this.contractStatus,
    this.confirmedAt,
  });

  final String quoteId;
  final String taskId;
  final String engineerId;
  final String engineerName;
  final String? engineerAvatarUrl;
  final String? engineerCountry;
  final String? engineerHeadline;
  final String taskTitle;
  final String taskDescription;
  final String taskCategory;
  final String currency;
  final int amountMinor;
  final int deliveryDays;
  final String scopeOfWork;
  final int includedRevisions;
  final String? notes;
  final int commissionBps;
  final int platformFeeMinor;
  final int engineerNetMinor;
  final String? contractId;
  final String? contractStatus;
  final DateTime? confirmedAt;

  bool get isConfirmed => contractId != null && contractId!.isNotEmpty;

  int get currencyFractionDigits => _fractionDigits(currency);

  String formatMinor(int minor) {
    final digits = currencyFractionDigits;
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return NumberFormat.currency(name: currency, decimalDigits: digits)
        .format(minor / divisor);
  }

  String get formattedAmount => formatMinor(amountMinor);
  String get formattedPlatformFee => formatMinor(platformFeeMinor);
  String get formattedEngineerNet => formatMinor(engineerNetMinor);
  String get commissionPercent => (commissionBps / 100).toStringAsFixed(
        commissionBps % 100 == 0 ? 0 : 2,
      );

  String get engineerInitials {
    final parts = engineerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'E';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ContractConfirmationModel.fromJson(Map<String, dynamic> json) {
    final amount = _int(json['amount_minor']);
    final fee = _int(json['platform_fee_minor']);
    final netValue = json['engineer_net_minor'];

    return ContractConfirmationModel(
      quoteId: _string(json['quote_id']),
      taskId: _string(json['task_id']),
      engineerId: _string(json['engineer_id']),
      engineerName: _string(json['engineer_name'], fallback: 'Engineer'),
      engineerAvatarUrl: _nullable(json['engineer_avatar_url']),
      engineerCountry: _nullable(json['engineer_country']),
      engineerHeadline: _nullable(json['engineer_headline']),
      taskTitle: _string(json['task_title'], fallback: 'Untitled task'),
      taskDescription: _string(json['task_description']),
      taskCategory: _string(json['task_category'], fallback: 'Project'),
      currency: _string(json['currency'], fallback: 'USD').toUpperCase(),
      amountMinor: amount,
      deliveryDays: _int(json['delivery_days']),
      scopeOfWork: _string(json['scope_of_work']),
      includedRevisions: _int(json['included_revisions']),
      notes: _nullable(json['notes']),
      commissionBps: _int(json['commission_bps'], fallback: 500),
      platformFeeMinor: fee,
      engineerNetMinor: netValue == null ? amount - fee : _int(netValue),
      contractId: _nullable(json['contract_id']),
      contractStatus: _nullable(json['contract_status']),
      confirmedAt: _date(json['confirmed_at']),
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
}
