import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_task_invitation_model.dart';
import 'package:permit_plans/repositries/engineer_task_invitation_repository.dart';

class EngineerTaskInvitationsController extends GetxController {
  EngineerTaskInvitationsController({
    required EngineerTaskInvitationRepository repository,
  }) : _repository = repository;

  final EngineerTaskInvitationRepository _repository;

  final invitations = <EngineerTaskInvitation>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  final rejectingInvitationId = RxnString();

  bool _hasLoaded = false;

  List<EngineerTaskInvitation> get filteredInvitations {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return invitations.toList(growable: false);
    return invitations
        .where((item) {
          return item.title.toLowerCase().contains(query) ||
              item.category.toLowerCase().contains(query) ||
              item.clientName.toLowerCase().contains(query) ||
              item.requiredSkills.any(
                (skill) => skill.toLowerCase().contains(query),
              );
        })
        .toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    loadInvitations();
  }

  Future<void> loadInvitations({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) return;

    if (refresh || _hasLoaded) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await _repository.fetchPendingInvitations();
      invitations.assignAll(result);
      _hasLoaded = true;
    } on EngineerTaskInvitationRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (error) {
      // ignore: avoid_print
      print('[EngineerTaskInvitationsController.loadInvitations] $error');
      errorMessage.value = 'Unable to load invitations. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadInvitations(refresh: true);

  void updateSearch(String value) => searchQuery.value = value;

  Future<bool> rejectInvitation(EngineerTaskInvitation invitation) async {
    if (rejectingInvitationId.value != null) return false;
    rejectingInvitationId.value = invitation.invitationId;
    try {
      await _repository.rejectInvitation(invitation.invitationId);
      invitations.removeWhere(
        (item) => item.invitationId == invitation.invitationId,
      );
      Get.snackbar(
        'Invitation rejected',
        'You have declined “${invitation.title}”.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 3),
      );
      return true;
    } on EngineerTaskInvitationRepositoryException catch (error) {
      Get.snackbar(
        'Could not reject invitation',
        error.message,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(14),
        duration: const Duration(seconds: 4),
      );
      return false;
    } finally {
      rejectingInvitationId.value = null;
    }
  }
}
