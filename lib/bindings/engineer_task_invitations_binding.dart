import 'package:get/get.dart';

import 'package:permit_plans/controllers/engineer_task_invitations_controller.dart';
import 'package:permit_plans/repositries/engineer_task_invitation_repository.dart';

class EngineerTaskInvitationsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EngineerTaskInvitationRepository>(
      () => EngineerTaskInvitationRepository(),
    );
    Get.lazyPut<EngineerTaskInvitationsController>(
      () => EngineerTaskInvitationsController(
        repository: Get.find<EngineerTaskInvitationRepository>(),
      ),
    );
  }
}
