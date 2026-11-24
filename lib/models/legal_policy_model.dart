/// Read-only policy copy shown in the WorkBridge Legal & Policies screen.
///
/// These are product drafts, not approved legal documents. Keep the draft
/// banner visible until the business entity, governing law, support contact,
/// provider terms and market-specific requirements have been reviewed.
class LegalPolicySection {
  const LegalPolicySection({
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;
}

class LegalPolicyDocument {
  const LegalPolicyDocument({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.summary,
    required this.sections,
  });

  final String id;
  final String title;
  final String shortTitle;
  final String summary;
  final List<LegalPolicySection> sections;
}

class LegalPolicyDocuments {
  LegalPolicyDocuments._();

  static const all = <LegalPolicyDocument>[
    LegalPolicyDocument(
      id: 'terms',
      title: 'Terms & Conditions',
      shortTitle: 'Terms',
      summary: 'The proposed rules for using WorkBridge as a Client or Engineer.',
      sections: [
        LegalPolicySection(
          title: '1. About WorkBridge',
          paragraphs: [
            'WorkBridge is being developed as an online marketplace that helps Clients find independent Engineers for project-based work. The platform provides tools for profiles, invitations, quotes, contract records, project communication and delivery review.',
            'WorkBridge is a marketplace platform. Unless a separate written agreement says otherwise, it is not the Client’s employer, the Engineer’s employer, or a party that performs the project work on either user’s behalf.',
          ],
        ),
        LegalPolicySection(
          title: '2. Accounts and eligibility',
          paragraphs: [
            'You must provide accurate account information, keep your sign-in credentials confidential and promptly update information that becomes inaccurate. You are responsible for activity carried out through your account, subject to applicable law.',
            'You may use the Client or Engineer features that match the role assigned to your account. Do not impersonate another person, misrepresent qualifications, create misleading profiles or use another person’s account without permission.',
          ],
        ),
        LegalPolicySection(
          title: '3. Client and Engineer responsibilities',
          paragraphs: [
            'Clients should provide a clear project brief, realistic requirements, relevant reference material and timely feedback. Clients should review the quote and contract details before accepting them.',
            'Engineers should submit truthful profile information, make quotes that accurately describe scope, price, delivery time and included revisions, and communicate material delays or blockers promptly.',
            'Both parties must communicate respectfully, use project files only for the intended project and avoid unlawful, deceptive, abusive or infringing activity.',
          ],
        ),
        LegalPolicySection(
          title: '4. Quotes and project contracts',
          paragraphs: [
            'A quote should identify the agreed scope, price, currency, delivery estimate and included revisions. A Client’s acceptance and the platform’s contract-confirmation record are intended to capture the agreed project terms.',
            'Changes to scope, price, timing or revisions should be recorded through the WorkBridge negotiation or another mutually acknowledged written process. Do not assume that a chat message alone changes a confirmed contract unless both parties clearly agree.',
          ],
        ),
        LegalPolicySection(
          title: '5. Platform fees',
          paragraphs: [
            'The current WorkBridge business plan is to charge a 5% platform commission against Engineer compensation. The exact calculation base, currency treatment, taxes and any other provider charges must be disclosed in the applicable contract or checkout before the relevant transaction is activated.',
            'Do not rely on an estimate shown in a development preview as a final payable or withdrawable amount. The final fee rules must be confirmed before production launch.',
          ],
        ),
        LegalPolicySection(
          title: '6. Work, files and intellectual property',
          paragraphs: [
            'You must have the rights or permissions needed to upload, share and use text, designs, source files, images and other material you provide through WorkBridge.',
            'Ownership or licensing of project deliverables should be stated in the accepted project contract. Unless the contract clearly says so, this draft does not promise that intellectual-property ownership automatically transfers on upload, submission or payment.',
          ],
        ),
        LegalPolicySection(
          title: '7. Disputes, suspension and termination',
          paragraphs: [
            'If a project disagreement occurs, users should first use the project conversation and the platform’s review or support process to explain the issue and provide relevant records.',
            'WorkBridge may restrict access where needed to investigate suspected fraud, security issues or serious policy violations, subject to applicable law and a fair review process. Detailed dispute timelines, appeal rights and termination rules must be finalized before launch.',
          ],
        ),
        LegalPolicySection(
          title: '8. Governing law and contact',
          paragraphs: [
            'The legal entity operating WorkBridge, governing law, courts or dispute forum, registered address and official support contact have not yet been finalized. Insert those details after the business jurisdiction and registration are confirmed.',
            'Official contact: [Add approved WorkBridge legal/support email and business address before publication].',
          ],
        ),
      ],
    ),
    LegalPolicyDocument(
      id: 'privacy',
      title: 'Privacy Policy',
      shortTitle: 'Privacy',
      summary: 'A draft explanation of the information the marketplace may use and why.',
      sections: [
        LegalPolicySection(
          title: '1. Information covered by this draft',
          paragraphs: [
            'Depending on the features you use, WorkBridge may process account details such as your name, email address, account role, profile photo, country, contact details and professional or company information.',
            'Project activity may include task briefs, quotes, contract details, messages, attachments, delivery files, review decisions and related timestamps. Technical information may include device, app, diagnostic, security and usage data needed to operate and protect the service.',
          ],
        ),
        LegalPolicySection(
          title: '2. How information is used',
          paragraphs: [
            'Information is intended to support account creation, profile display, Client and Engineer matching, task invitations, quotes, contract records, project communication, delivery review, customer support, platform security and service improvement.',
            'Information may also be used to detect abuse, investigate reports, comply with legal obligations and maintain records needed for active projects, payment-related enquiries or disputes.',
          ],
        ),
        LegalPolicySection(
          title: '3. When information is shared',
          paragraphs: [
            'Some profile and project information is shared with the other participant when needed to operate a project. For example, a Client and the assigned Engineer need access to relevant project scope, communication and delivery records.',
            'WorkBridge may use infrastructure, storage, authentication, communications, analytics or payment service providers to operate the service. Those providers should receive only the information needed for their assigned function and be covered by appropriate contractual and security safeguards.',
            'Information may be disclosed where required by law, to protect users or the platform, or as part of a business restructuring, subject to applicable legal requirements.',
          ],
        ),
        LegalPolicySection(
          title: '4. Payment information',
          paragraphs: [
            'The intended production design is to use an approved payment provider’s hosted checkout or secure tokenization flow. WorkBridge’s Flutter forms should not collect or store raw card numbers or CVV values.',
            'A payment provider may process payment credentials under its own privacy terms. The provider, data locations, international transfer safeguards and exact data fields must be identified before production payments are enabled.',
          ],
        ),
        LegalPolicySection(
          title: '5. Storage, security and retention',
          paragraphs: [
            'WorkBridge plans to use access controls and private storage for project files and other restricted information. No online service can guarantee absolute security; users should avoid uploading passwords, full card details or unrelated sensitive information into project chats or files.',
            'Information should be retained only as long as reasonably needed for the service, active contracts, disputes, accounting, security and legal obligations. Exact retention periods and deletion procedures must be documented before launch.',
          ],
        ),
        LegalPolicySection(
          title: '6. Your choices and requests',
          paragraphs: [
            'Users should be able to review and update profile information through account settings. Requests to access, correct, export or delete personal information will be handled according to applicable law and any legitimate record-retention requirements.',
            'Deleting an account may not immediately remove records that must be retained for an active contract, payment issue, dispute, fraud prevention or legal obligation. The final process and timelines need legal review.',
          ],
        ),
        LegalPolicySection(
          title: '7. International users and contact',
          paragraphs: [
            'WorkBridge is intended for users in more than one country. The operating entity, hosting locations, payment-provider locations and applicable international data-transfer safeguards must be stated once selected.',
            'Privacy contact: [Add approved privacy contact email and business address before publication].',
          ],
        ),
      ],
    ),
    LegalPolicyDocument(
      id: 'age',
      title: 'Age Eligibility Policy',
      shortTitle: 'Age eligibility',
      summary: 'A proposed minimum-age rule that must be checked against each launch market.',
      sections: [
        LegalPolicySection(
          title: '1. Proposed minimum age',
          paragraphs: [
            'Proposed WorkBridge platform rule: users must be at least 18 years old to create or maintain an account. If the law applying to the user requires a higher minimum age or greater legal capacity to enter the relevant agreement, the higher requirement applies.',
            'This is a product proposal for review, not a confirmed statement of the age-of-majority law in every country. WorkBridge must validate the rule for each launch market before accepting users there.',
          ],
        ),
        LegalPolicySection(
          title: '2. Account holder responsibilities',
          paragraphs: [
            'You must provide truthful age and identity information if requested through an approved verification process. Do not create an account using another person’s details or help someone bypass eligibility controls.',
            'A parent or guardian must not create or operate an account on behalf of an ineligible person unless WorkBridge has expressly adopted a legally reviewed process that permits it.',
          ],
        ),
        LegalPolicySection(
          title: '3. Checks and reports',
          paragraphs: [
            'Where reasonably necessary and legally permitted, WorkBridge may request proportionate evidence to check eligibility, restrict access while a concern is reviewed, or close an account that does not meet the final age requirements.',
            'The types of evidence, verification provider, retention period and appeal process must be finalized before this policy is published.',
          ],
        ),
        LegalPolicySection(
          title: '4. Market-by-market review',
          paragraphs: [
            'Before launch in a country, WorkBridge must confirm the minimum age, contractual capacity, any special rules for online services and any age-verification obligations that apply there.',
            'Launch checklist: [Legal reviewer to confirm the approved minimum age and eligible countries].',
          ],
        ),
      ],
    ),
    LegalPolicyDocument(
      id: 'payments',
      title: 'Payment & Cancellation Policy',
      shortTitle: 'Payment & cancellation',
      summary: 'A draft of the intended quote, payment, cancellation and refund workflow.',
      sections: [
        LegalPolicySection(
          title: '1. Quotes and agreed amounts',
          paragraphs: [
            'The Engineer’s quote should identify the project price, currency, scope, delivery estimate and included revisions. The Client should review these details before accepting the quote and confirming the contract.',
            'Any later change to price or scope should be agreed by both parties and recorded in the project workflow before the changed work proceeds.',
          ],
        ),
        LegalPolicySection(
          title: '2. Payment provider and funding',
          paragraphs: [
            'Production payments are intended to be processed through a payment provider that has approved WorkBridge’s business model and the relevant marketplace, collection and payout flows. The provider’s terms, eligibility checks and payment status records will apply.',
            'WorkBridge must not describe funds as held in escrow or safeguarded by WorkBridge unless the selected provider and applicable legal arrangement expressly authorize that description. Any holding or delayed-settlement arrangement must be documented and approved by the provider.',
            'Development and mock checkout screens do not move real money. A mock success state must not be treated as proof that a Client paid, a contract is funded or an Engineer can withdraw funds.',
          ],
        ),
        LegalPolicySection(
          title: '3. Platform commission and other charges',
          paragraphs: [
            'The current intended WorkBridge commission is 5% of Engineer compensation. Its final calculation base, timing, taxes, currency conversion, payment-provider fees and any Client-side charges must be clearly disclosed in the relevant quote, contract or checkout before launch.',
            'The displayed estimate in a development build is not a final invoice or confirmation of funds received.',
          ],
        ),
        LegalPolicySection(
          title: '4. Cancellation requests',
          paragraphs: [
            'If a project cannot proceed, the Client and Engineer should record the reason and any agreed outcome in the project conversation or designated support process. The applicable contract terms and provider rules will be considered.',
            'The permitted cancellation window, approval requirements, partial-work valuation and any cancellation charge have not yet been finalized. Do not assume that cancelling a project automatically creates a full refund.',
          ],
        ),
        LegalPolicySection(
          title: '5. Refunds, disputes and chargebacks',
          paragraphs: [
            'Refund eligibility and timing depend on the accepted contract, the facts of the project, the payment provider’s rules and applicable law. A dispute may require the parties to provide the quote, contract, messages, delivery versions and review decisions.',
            'Chargebacks and payment reversals are handled under the payment provider’s process. WorkBridge must publish the final complaint route, response deadlines and evidence requirements after the provider and dispute process are approved.',
          ],
        ),
        LegalPolicySection(
          title: '6. Engineer payouts',
          paragraphs: [
            'An approved delivery or completed project does not by itself prove that a payout has been initiated or settled. Payout eligibility, timing, currency, identity checks, reserves and fees depend on the approved provider arrangement.',
            'Until a provider is integrated and confirms a payout status, WorkBridge earnings and payout screens are informational or demonstrative only and must not be described as a withdrawable cash balance.',
          ],
        ),
        LegalPolicySection(
          title: '7. Support and launch details',
          paragraphs: [
            'For a payment or cancellation issue, users should retain the project ID, contract details, payment-provider reference (if one exists) and relevant project messages.',
            'Payment support: [Add approved support contact, provider name, complaint process and response times before publication].',
          ],
        ),
      ],
    ),
  ];

  static LegalPolicyDocument byId(String? id) {
    for (final document in all) {
      if (document.id == id) return document;
    }
    return all.first;
  }
}
