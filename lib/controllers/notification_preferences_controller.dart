import 'package:get/get.dart';

import 'package:permit_plans/models/notification_preferences_model.dart';
import 'package:permit_plans/repositries/notification_preferences_repository.dart';

class NotificationPreferencesController extends GetxController {
  NotificationPreferencesController({
    required NotificationPreferencesRepository repository,
  }) : _repository = repository;

  final NotificationPreferencesRepository _repository;

  final preferences = Rxn<NotificationPreferences>();
  final savedPreferences = Rxn<NotificationPreferences>();
  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final successMessage = ''.obs;

  bool get hasChanges {
    final draft = preferences.value;
    final saved = savedPreferences.value;
    if (draft == null || saved == null) return false;
    return draft.comparisonKey != saved.comparisonKey;
  }

  bool get canSave => hasChanges && !isSaving.value && !isLoading.value;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    isLoading.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final result = await _repository.loadOrCreate();
      savedPreferences.value = result;
      preferences.value = result;
    } catch (error) {
      errorMessage.value = _message(error);
    } finally {
      isLoading.value = false;
    }
  }

  void setInAppEnabled(bool value) => _update((current) =>
      current.copyWith(inAppEnabled: value));

  void setEmailEnabled(bool value) => _update((current) =>
      current.copyWith(emailEnabled: value));

  void setPushEnabled(bool value) => _update((current) =>
      current.copyWith(pushEnabled: value));

  void setTaskUpdates(bool value) => _update((current) =>
      current.copyWith(taskUpdates: value));

  void setQuoteUpdates(bool value) => _update((current) =>
      current.copyWith(quoteUpdates: value));

  void setMessageUpdates(bool value) => _update((current) =>
      current.copyWith(messageUpdates: value));

  void setDeliveryUpdates(bool value) => _update((current) =>
      current.copyWith(deliveryUpdates: value));

  void setProjectUpdates(bool value) => _update((current) =>
      current.copyWith(projectUpdates: value));

  void _update(NotificationPreferences Function(NotificationPreferences) change) {
    final current = preferences.value;
    if (current == null || isSaving.value) return;
    preferences.value = change(current);
    successMessage.value = '';
  }

  void discardChanges() {
    final saved = savedPreferences.value;
    if (saved == null || isSaving.value) return;
    preferences.value = saved;
    successMessage.value = '';
    errorMessage.value = '';
  }

  Future<void> save() async {
    final draft = preferences.value;
    if (draft == null || !canSave) return;

    isSaving.value = true;
    errorMessage.value = '';
    successMessage.value = '';
    try {
      final result = await _repository.save(draft);
      savedPreferences.value = result;
      preferences.value = result;
      successMessage.value = 'Your notification preferences have been saved.';
    } catch (error) {
      errorMessage.value = _message(error);
    } finally {
      isSaving.value = false;
    }
  }

  String _message(Object error) {
    if (error is NotificationPreferencesRepositoryException) {
      return error.message;
    }
    return 'Unable to load notification preferences. Please try again.';
  }
}
