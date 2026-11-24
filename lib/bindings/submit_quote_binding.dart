import 'package:get/get.dart';

import 'package:permit_plans/controllers/submit_quote_controller.dart';
import 'package:permit_plans/models/engineer_task_invitation_model.dart';
import 'package:permit_plans/repositries/quote_submission_repository.dart';

class SubmitQuoteBinding extends Bindings {
  @override
  void dependencies() {
    final argument = Get.arguments;
    if (argument is! EngineerTaskInvitation) {
      throw ArgumentError(
        'SubmitQuoteScreen requires an EngineerTaskInvitation in Get.arguments.',
      );
    }

    Get.lazyPut<QuoteSubmissionRepository>(
      () => QuoteSubmissionRepository(),
    );
    Get.lazyPut<SubmitQuoteController>(
      () => SubmitQuoteController(
        repository: Get.find<QuoteSubmissionRepository>(),
        invitation: argument,
      ),
    );
  }
}
