import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:permit_plans/constants/app_colors.dart';
import 'package:permit_plans/constants/app_routes.dart';
import 'package:permit_plans/models/engineer_directory_model.dart';

/// Holds the privacy-filtered engineer profile passed from the directory.
/// The directory RPC already returns the public fields needed by this screen,
/// so no second database query or broader RLS policy is required.
class EngineerProfileDetailsController extends GetxController {
  EngineerProfileDetailsController({required this.profile});

  final EngineerDirectoryProfile? profile;

  bool get canInvite => profile?.canReceiveAssignment ?? false;

  void goBack() {
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back<void>();
    } else {
      Get.offNamed<void>(AppRoutes.clientBrowseEngineers);
    }
  }

  void assignTask() {
    final engineer = profile;
    if (engineer == null) return;

    if (!engineer.canReceiveAssignment) {
      Get.snackbar(
        'Engineer unavailable',
        'This engineer is not accepting new assignments right now.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.warningSoft,
        colorText: AppColors.warningInk,
        margin: const EdgeInsets.all(14),
      );
      return;
    }

    Get.toNamed<void>(AppRoutes.clientAssignTask, arguments: engineer);
  }

  Future<void> copyPortfolioLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    Get.snackbar(
      'Link copied',
      'Portfolio link copied to your clipboard.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.brand,
      colorText: AppColors.white,
      margin: const EdgeInsets.all(14),
      duration: const Duration(seconds: 2),
    );
  }
}
