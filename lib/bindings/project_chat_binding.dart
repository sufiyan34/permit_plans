import 'package:get/get.dart';

import 'package:permit_plans/controllers/project_chat_controller.dart';
import 'package:permit_plans/repositries/project_chat_repository.dart';

class ProjectChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProjectChatRepository>(() => ProjectChatRepository());
    Get.lazyPut<ProjectChatController>(
      () => ProjectChatController(
        repository: Get.find<ProjectChatRepository>(),
      ),
    );
  }
}
