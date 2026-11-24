import 'package:get/get.dart';

import 'package:permit_plans/controllers/client_dashboard_controller.dart';
import 'package:permit_plans/repositries/client_dashboard_repository.dart';

class ClientDashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ClientDashboardRepository>(
      () => ClientDashboardRepository(),
    );
    Get.lazyPut<ClientDashboardController>(
      () => ClientDashboardController(
        repository: Get.find<ClientDashboardRepository>(),
      ),
    );
  }
}
