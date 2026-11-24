import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/models/project_delivery_model.dart';

/// A revision request is the latest delivery version that the Client returned
/// with revision_requested status, paired with its contract and full history.
class EngineerRevisionRequestModel {
  const EngineerRevisionRequestModel({
    required this.project,
    required this.requestedDelivery,
    required this.history,
  });

  final EngineerProjectModel project;
  final ProjectDeliveryModel requestedDelivery;
  final List<ProjectDeliveryModel> history;

  int get previousSubmissionCount =>
      history.where((item) => item.submissionNumber < requestedDelivery.submissionNumber).length;

  int get attachmentCount => requestedDelivery.files.length;
}
