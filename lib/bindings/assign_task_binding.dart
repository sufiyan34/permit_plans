import 'package:get/get.dart';

import 'package:permit_plans/controllers/assign_task_controller.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';
import 'package:permit_plans/repositries/task_assignment_repository.dart';

class AssignTaskBinding extends Bindings {
  @override
  void dependencies() {
    final argument = Get.arguments;
    EngineerDirectoryProfile? engineer;

    if (argument is EngineerDirectoryProfile) {
      engineer = argument;
    } else if (argument is Map) {
      engineer = EngineerDirectoryProfile.fromMap(
        Map<String, dynamic>.from(argument),
      );
    }

    Get.lazyPut<TaskAssignmentRepository>(
      () => TaskAssignmentRepository(),
    );
    Get.lazyPut<AssignTaskController>(
      () => AssignTaskController(
        repository: Get.find<TaskAssignmentRepository>(),
        engineer: engineer,
      ),
    );
  }
}
