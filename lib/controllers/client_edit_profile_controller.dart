import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permit_plans/models/client_profile_model.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

class ClientEditProfileController extends GetxController {
  ClientEditProfileController({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;

  final Rxn<ClientProfileModel> profile = Rxn<ClientProfileModel>();
  final RxBool isLoading = false.obs;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    if (isLoading.value) return;
    isLoading.value = true;
    errorMessage.value = '';
    try {
      profile.value = await _repository.fetchClientProfile();
    } on ProfileRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'We could not load your profile. Please try again.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save(
    ClientProfileModel updatedProfile, {
    XFile? avatar,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _repository.saveClientProfile(updatedProfile, avatar: avatar);
      profile.value = await _repository.fetchClientProfile();
      return true;
    } on ProfileRepositoryException catch (error) {
      errorMessage.value = error.message;
      return false;
    } catch (_) {
      errorMessage.value = 'Unable to save your profile. Please try again.';
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
