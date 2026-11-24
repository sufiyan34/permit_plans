/// Input submitted by an invited Engineer. The amount is always stored in
/// integer minor units (for example, cents), never as a floating-point value.
class QuoteSubmissionDraft {
  const QuoteSubmissionDraft({
    required this.invitationId,
    required this.amountMinor,
    required this.currency,
    required this.deliveryDays,
    required this.scopeOfWork,
    required this.includedRevisions,
    this.notes,
  });

  final String invitationId;
  final int amountMinor;
  final String currency;
  final int deliveryDays;
  final String scopeOfWork;
  final int includedRevisions;
  final String? notes;
}

class QuoteSubmissionResult {
  const QuoteSubmissionResult({required this.quoteId});

  final String quoteId;
}
