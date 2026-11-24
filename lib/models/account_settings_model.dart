class AccountSettingsSnapshot {
  const AccountSettingsSnapshot({
    required this.userId,
    required this.email,
    required this.role,
    required this.createdAt,
    this.deletionRequest,
  });

  final String userId;
  final String email;
  final String role;
  final DateTime? createdAt;
  final AccountDeletionRequest? deletionRequest;
}

class AccountDeletionRequest {
  const AccountDeletionRequest({
    required this.id,
    required this.status,
    required this.requestedAt,
    this.reason,
  });

  final String id;
  final String status;
  final DateTime? requestedAt;
  final String? reason;

  factory AccountDeletionRequest.fromMap(Map<String, dynamic> row) {
    return AccountDeletionRequest(
      id: row['id'] as String? ?? '',
      status: row['status'] as String? ?? 'requested',
      requestedAt: DateTime.tryParse(row['requested_at'] as String? ?? ''),
      reason: row['reason'] as String?,
    );
  }

  bool get isActive =>
      const {'requested', 'under_review', 'scheduled'}.contains(status);

  String get readableStatus {
    switch (status) {
      case 'under_review':
        return 'Under review';
      case 'scheduled':
        return 'Scheduled';
      case 'completed':
        return 'Completed';
      case 'rejected':
        return 'Not approved';
      default:
        return 'Request received';
    }
  }
}
