import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/controllers/auth_controller.dart';
import 'package:permit_plans/models/account_settings_model.dart';
import 'package:permit_plans/repositries/account_settings_repository.dart';

class AccountSettingsController extends GetxController {
  AccountSettingsController({required AccountSettingsRepository repository})
      : _repository = repository;

  final AccountSettingsRepository _repository;

  final Rxn<AccountSettingsSnapshot> snapshot =
      Rxn<AccountSettingsSnapshot>();
  final RxBool isLoading = false.obs;
  final RxBool isChangingPassword = false.obs;
  final RxBool isSubmittingDeletion = false.obs;
  final RxBool obscureCurrentPassword = true.obs;
  final RxBool obscureNewPassword = true.obs;
  final RxBool obscureConfirmPassword = true.obs;
  final RxString errorMessage = ''.obs;

  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      snapshot.value = await _repository.loadSnapshot();
    } on AccountSettingsException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'We could not load your account settings.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> changePassword() async {
    if (isChangingPassword.value) return false;
    final current = currentPasswordController.text;
    final next = newPasswordController.text;
    final confirmation = confirmPasswordController.text;

    if (current.isEmpty) {
      _showMessage('Current password required', 'Enter your current password.');
      return false;
    }
    if (next.length < 8) {
      _showMessage('Password too short', 'Use at least 8 characters.');
      return false;
    }
    if (next == current) {
      _showMessage('Choose a new password', 'Your new password must be different.');
      return false;
    }
    if (next != confirmation) {
      _showMessage('Passwords do not match', 'Confirm your new password again.');
      return false;
    }

    isChangingPassword.value = true;
    try {
      await _repository.changePassword(
        currentPassword: current,
        newPassword: next,
      );
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();
      _showMessage('Password updated', 'Your account password has been changed.');
      return true;
    } on AccountSettingsException catch (error) {
      _showMessage('Unable to change password', error.message);
      return false;
    } catch (_) {
      _showMessage(
        'Unable to change password',
        'Please check your connection and try again.',
      );
      return false;
    } finally {
      isChangingPassword.value = false;
    }
  }

  Future<bool> requestAccountDeletion(String reason) async {
    if (isSubmittingDeletion.value) return false;
    if (snapshot.value?.deletionRequest?.isActive == true) {
      _showMessage(
        'Request already submitted',
        'Your existing account deletion request is still being reviewed.',
      );
      return false;
    }

    isSubmittingDeletion.value = true;
    try {
      await _repository.submitDeletionRequest(reason: reason);
      await load();
      _showMessage(
        'Request received',
        'Your account is not deleted immediately. Support will review the request.',
      );
      return true;
    } on AccountSettingsException catch (error) {
      _showMessage('Unable to submit request', error.message);
      return false;
    } catch (_) {
      _showMessage(
        'Unable to submit request',
        'Please check your connection and try again.',
      );
      return false;
    } finally {
      isSubmittingDeletion.value = false;
    }
  }

  Future<void> signOut() async {
    try {
      await Get.find<AuthController>().signOut();
    } catch (_) {
      _showMessage('Unable to sign out', 'Please try again.');
    }
  }

  void _showMessage(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
