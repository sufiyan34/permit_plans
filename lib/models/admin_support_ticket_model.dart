import 'package:permit_plans/models/help_support_model.dart';

class AdminSupportTicket {
  const AdminSupportTicket({
    required this.id,
    required this.userId,
    required this.requesterName,
    required this.requesterEmail,
    required this.accountRole,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.priority,
    required this.createdAt,
    required this.updatedAt,
    this.relatedReference,
    this.adminNote,
    this.resolvedAt,
  });

  final String id;
  final String userId;
  final String requesterName;
  final String requesterEmail;
  final String accountRole;
  final String category;
  final String subject;
  final String message;
  final String status;
  final String priority;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final String? relatedReference;
  final String? adminNote;

  String get categoryLabel => HelpTopic.byValue(category).label;

  String get statusLabel => switch (status) {
        'in_review' => 'In review',
        'waiting_for_user' => 'Waiting for user',
        'resolved' => 'Resolved',
        'closed' => 'Closed',
        _ => 'Open',
      };

  String get priorityLabel => switch (priority) {
        'low' => 'Low',
        'high' => 'High',
        'urgent' => 'Urgent',
        _ => 'Normal',
      };

  factory AdminSupportTicket.fromMap(Map<String, dynamic> row) {
    return AdminSupportTicket(
      id: row['id']?.toString() ?? '',
      userId: row['user_id']?.toString() ?? '',
      requesterName: _text(row['requester_name'], fallback: 'WorkBridge user'),
      requesterEmail: _text(row['requester_email']),
      accountRole: _text(row['account_role'], fallback: 'user'),
      category: _text(row['category'], fallback: 'other'),
      subject: _text(row['subject']),
      message: _text(row['message']),
      status: _text(row['status'], fallback: 'open'),
      priority: _text(row['priority'], fallback: 'normal'),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(row['updated_at']?.toString() ?? ''),
      resolvedAt: DateTime.tryParse(row['resolved_at']?.toString() ?? ''),
      relatedReference: _nullable(row['related_reference']),
      adminNote: _nullable(row['admin_note']),
    );
  }

  static String _text(dynamic value, {String fallback = ''}) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? fallback : result;
  }

  static String? _nullable(dynamic value) {
    final result = value?.toString().trim() ?? '';
    return result.isEmpty ? null : result;
  }
}
