import 'package:get/get.dart';

import 'package:permit_plans/controllers/admin_dashboard_controller.dart';
import 'package:permit_plans/repositries/admin_dashboard_repository.dart';

class AdminDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminDashboardRepository>(() => AdminDashboardRepository());
    Get.lazyPut<AdminDashboardController>(
      () => AdminDashboardController(
        repository: Get.find<AdminDashboardRepository>(),
      ),
    );
  }
}
