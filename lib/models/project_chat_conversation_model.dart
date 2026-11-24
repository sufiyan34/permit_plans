import 'package:intl/intl.dart';

class ProjectChatConversation {
  const ProjectChatConversation({
    required this.contractId,
    required this.taskId,
    required this.taskTitle,
    required this.contractStatus,
    required this.partnerId,
    required this.partnerName,
    required this.partnerRole,
    required this.unreadCount,
    required this.createdAt,
    this.partnerAvatarUrl,
    this.lastMessagePreview,
    this.lastAttachmentName,
    this.lastMessageAt,
  });

  final String contractId;
  final String taskId;
  final String taskTitle;
  final String contractStatus;
  final String partnerId;
  final String partnerName;
  final String partnerRole;
  final String? partnerAvatarUrl;
  final String? lastMessagePreview;
  final String? lastAttachmentName;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final DateTime createdAt;

  String get statusLabel {
    switch (contractStatus) {
      case 'awaiting_payment':
        return 'Awaiting payment';
      case 'funded':
        return 'Funded';
      case 'in_progress':
        return 'In progress';
      case 'submitted':
        return 'In review';
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
        return 'Project';
    }
  }

  String get lastActivityLabel {
    final date = lastMessageAt ?? createdAt;
    final local = date.toLocal();
    final now = DateTime.now();
    if (_isSameDay(local, now)) return DateFormat('h:mm a').format(local);
    if (now.difference(local).inDays < 7) return DateFormat('EEE').format(local);
    return DateFormat('dd MMM').format(local);
  }

  String get previewLabel {
    final text = lastMessagePreview?.trim() ?? '';
    if (text.isNotEmpty) return text;
    final attachment = lastAttachmentName?.trim() ?? '';
    if (attachment.isNotEmpty) return 'Attachment: $attachment';
    return 'Start a conversation about this project';
  }

  String get initials {
    final parts = partnerName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return partnerRole == 'client' ? 'C' : 'E';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get shortContractId => contractId.length <= 8
      ? contractId.toUpperCase()
      : contractId.substring(contractId.length - 8).toUpperCase();

  ProjectChatConversation copyWith({int? unreadCount}) {
    return ProjectChatConversation(
      contractId: contractId,
      taskId: taskId,
      taskTitle: taskTitle,
      contractStatus: contractStatus,
      partnerId: partnerId,
      partnerName: partnerName,
      partnerRole: partnerRole,
      partnerAvatarUrl: partnerAvatarUrl,
      lastMessagePreview: lastMessagePreview,
      lastAttachmentName: lastAttachmentName,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      createdAt: createdAt,
    );
  }

  factory ProjectChatConversation.fromJson(Map<String, dynamic> json) {
    return ProjectChatConversation(
      contractId: _string(json['contract_id']),
      taskId: _string(json['task_id']),
      taskTitle: _string(json['task_title'], fallback: 'Project'),
      contractStatus: _string(json['contract_status']),
      partnerId: _string(json['partner_id']),
      partnerName: _string(json['partner_name'], fallback: 'Project participant'),
      partnerRole: _string(json['partner_role']),
      partnerAvatarUrl: _nullable(json['partner_avatar_url']),
      lastMessagePreview: _nullable(json['last_message_preview']),
      lastAttachmentName: _nullable(json['last_attachment_name']),
      lastMessageAt: _date(json['last_message_at']),
      unreadCount: _int(json['unread_count']),
      createdAt: _date(json['created_at']) ?? DateTime.now(),
    );
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

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
