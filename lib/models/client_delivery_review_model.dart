import 'package:intl/intl.dart';

import 'package:permit_plans/models/project_delivery_model.dart';

/// One delivery submission visible to the Client who owns the contract.
/// Private contact and payout details are intentionally not included.
class ClientDeliveryReviewModel {
  const ClientDeliveryReviewModel({
    required this.deliveryId,
    required this.contractId,
    required this.submissionNumber,
    required this.message,
    required this.status,
    required this.createdAt,
    required this.taskTitle,
    required this.taskCategory,
    required this.currency,
    required this.amountMinor,
    required this.engineerId,
    required this.engineerName,
    required this.files,
    this.reviewedAt,
    this.reviewNote,
    this.deadlineAt,
    this.engineerAvatarUrl,
  });

  final String deliveryId;
  final String contractId;
  final int submissionNumber;
  final String message;
  final String status;
  final DateTime createdAt;
  final DateTime? reviewedAt;
  final String? reviewNote;
  final String taskTitle;
  final String taskCategory;
  final String currency;
  final int amountMinor;
  final DateTime? deadlineAt;
  final String engineerId;
  final String engineerName;
  final String? engineerAvatarUrl;
  final List<ProjectDeliveryFile> files;

  bool get canReview => status == 'submitted';

  String get formattedAmount {
    final digits = _fractionDigits(currency);
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return NumberFormat.currency(name: currency, decimalDigits: digits)
        .format(amountMinor / divisor);
  }

  String get formattedDate =>
      DateFormat('dd MMM yyyy, hh:mm a').format(createdAt.toLocal());

  String get deadlineLabel => deadlineAt == null
      ? 'Not specified'
      : DateFormat('dd MMM yyyy').format(deadlineAt!.toLocal());

  String get statusLabel {
    switch (status) {
      case 'submitted':
        return 'Needs review';
      case 'revision_requested':
        return 'Revision requested';
      case 'approved':
        return 'Approved';
      case 'superseded':
        return 'Previous version';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String get engineerInitials {
    final parts = engineerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'E';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory ClientDeliveryReviewModel.fromJson(Map<String, dynamic> json) {
    final rawFiles = json['files'];
    final files = rawFiles is List
        ? rawFiles
            .whereType<Map>()
            .map((item) => ProjectDeliveryFile.fromJson(
                  Map<String, dynamic>.from(item),
                ))
            .toList(growable: false)
        : const <ProjectDeliveryFile>[];

    return ClientDeliveryReviewModel(
      deliveryId: _string(json['delivery_id']),
      contractId: _string(json['contract_id']),
      submissionNumber: _int(json['submission_number']),
      message: _string(json['message']),
      status: _string(json['delivery_status']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
      reviewedAt: _date(json['reviewed_at']),
      reviewNote: _nullable(json['review_note']),
      taskTitle: _string(json['task_title'], fallback: 'Untitled project'),
      taskCategory: _string(json['task_category'], fallback: 'Project'),
      currency: _string(json['currency'], fallback: 'USD').toUpperCase(),
      amountMinor: _int(json['agreed_amount_minor']),
      deadlineAt: _date(json['deadline_at']),
      engineerId: _string(json['engineer_id']),
      engineerName: _string(json['engineer_name'], fallback: 'Engineer'),
      engineerAvatarUrl: _nullable(json['engineer_avatar_url']),
      files: files,
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
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }

  static int _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }
}
