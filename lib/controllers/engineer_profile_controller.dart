import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permit_plans/models/engineer_profile_model.dart';
import 'package:permit_plans/repositries/profile_repository.dart';

class EngineerProfileController extends GetxController {
  EngineerProfileController({required ProfileRepository repository})
      : _repository = repository;

  final ProfileRepository _repository;
  final RxBool isSaving = false.obs;
  final RxString errorMessage = ''.obs;

  Future<bool> save(
    EngineerProfileModel profile, {
    XFile? avatar,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;
    errorMessage.value = '';
    try {
      await _repository.saveEngineerProfile(profile, avatar: avatar);
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
