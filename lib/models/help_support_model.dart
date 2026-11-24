class HelpTopic {
  const HelpTopic({
    required this.value,
    required this.label,
    required this.description,
  });

  final String value;
  final String label;
  final String description;

  static const all = <HelpTopic>[
    HelpTopic(
      value: 'account_profile',
      label: 'Account & profile',
      description: 'Login, profile details and account security',
    ),
    HelpTopic(
      value: 'tasks_invitations',
      label: 'Tasks & invitations',
      description: 'Task assignment, invitations and project access',
    ),
    HelpTopic(
      value: 'quotes_contracts',
      label: 'Quotes & contracts',
      description: 'Quotes, negotiation and contract terms',
    ),
    HelpTopic(
      value: 'chat_delivery',
      label: 'Chat & delivery',
      description: 'Messages, attachments and submitted work',
    ),
    HelpTopic(
      value: 'payments_payouts',
      label: 'Payments & payouts',
      description: 'Checkout, funding, earnings and withdrawals',
    ),
    HelpTopic(
      value: 'project_payment_dispute',
      label: 'Project or payment dispute',
      description: 'A disagreement about project work or payment',
    ),
    HelpTopic(
      value: 'technical_issue',
      label: 'Technical issue',
      description: 'Errors, loading problems or unexpected behaviour',
    ),
    HelpTopic(
      value: 'other',
      label: 'Something else',
      description: 'Any other question for the WorkBridge team',
    ),
  ];

  static HelpTopic byValue(String value) => all.firstWhere(
        (topic) => topic.value == value,
        orElse: () => all.last,
      );
}

class HelpFaq {
  const HelpFaq({
    required this.category,
    required this.question,
    required this.answer,
  });

  final String category;
  final String question;
  final String answer;

  static const all = <HelpFaq>[
    HelpFaq(
      category: 'Tasks & invitations',
      question: 'How does a Client assign work to an Engineer?',
      answer:
          'A Client can open an Engineer profile, choose Assign Task and send an invitation with the task description and requirements. The Engineer can review the invitation and decline it or prepare a quote.',
    ),
    HelpFaq(
      category: 'Quotes & contracts',
      question: 'What happens after an Engineer sends a quote?',
      answer:
          'The Client reviews the proposed amount, delivery time, scope and revisions. Both parties can negotiate. Once the same terms are accepted, the Client can confirm the contract.',
    ),
    HelpFaq(
      category: 'Payments & payouts',
      question: 'Are real payments and withdrawals available now?',
      answer:
          'The current WorkBridge build uses a payment preview/mock flow. A live payment provider and payout integration have not yet been activated. Do not treat a mock success screen or estimated earnings as money received or available to withdraw.',
    ),
    HelpFaq(
      category: 'Chat & delivery',
      question: 'When can the Engineer submit completed work?',
      answer:
          'The Engineer can submit delivery when the contract is in an eligible funded or active state. The Client can then review the files, approve the delivery or request revisions.',
    ),
    HelpFaq(
      category: 'Chat & delivery',
      question: 'What happens when a Client requests a revision?',
      answer:
          'The Engineer can open Revision Requests, read the Client feedback and submit a new delivery version. Previous submissions are retained as delivery history.',
    ),
    HelpFaq(
      category: 'Account & profile',
      question: 'How do I update my profile?',
      answer:
          'Open the profile section from your dashboard sidebar and choose Edit Profile. Clients can update their personal and company information; Engineers can update their professional profile, skills and portfolio.',
    ),
    HelpFaq(
      category: 'Account & profile',
      question: 'I forgot my password. What should I do?',
      answer:
          'Use Forgot Password on the sign-in page and follow the password recovery email. If you are already signed in and know your current password, you can use Change Password in Account Settings.',
    ),
    HelpFaq(
      category: 'Project or payment dispute',
      question: 'How do I report a project or payment dispute?',
      answer:
          'Choose Project or payment dispute in the support form. Include the project or contract reference when available and explain the issue with dates and relevant details. Do not include card numbers, passwords or other secrets.',
    ),
  ];
}

class HelpSupportRequest {
  const HelpSupportRequest({
    required this.id,
    required this.category,
    required this.subject,
    required this.message,
    required this.status,
    required this.createdAt,
    this.relatedReference,
    this.adminNote,
  });

  final String id;
  final String category;
  final String subject;
  final String message;
  final String status;
  final DateTime? createdAt;
  final String? relatedReference;
  final String? adminNote;

  factory HelpSupportRequest.fromMap(Map<String, dynamic> row) {
    return HelpSupportRequest(
      id: row['id']?.toString() ?? '',
      category: row['category']?.toString() ?? 'other',
      subject: row['subject']?.toString() ?? '',
      message: row['message']?.toString() ?? '',
      status: row['status']?.toString() ?? 'open',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
      relatedReference: _nullable(row['related_reference']),
      adminNote: _nullable(row['admin_note']),
    );
  }

  String get readableStatus {
    switch (status) {
      case 'in_review':
        return 'In review';
      case 'waiting_for_user':
        return 'Waiting for you';
      case 'resolved':
        return 'Resolved';
      case 'closed':
        return 'Closed';
      default:
        return 'Open';
    }
  }

  static String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? null : text;
  }
}
