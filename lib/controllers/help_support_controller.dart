import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/help_support_model.dart';
import 'package:permit_plans/repositries/help_support_repository.dart';

class HelpSupportController extends GetxController {
  HelpSupportController({required HelpSupportRepository repository})
      : _repository = repository;

  final HelpSupportRepository _repository;

  final requests = <HelpSupportRequest>[].obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'account_profile'.obs;
  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;
  final requestError = ''.obs;

  final searchController = TextEditingController();
  final subjectController = TextEditingController();
  final messageController = TextEditingController();
  final referenceController = TextEditingController();

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;
  bool _receivedStreamValue = false;

  List<HelpFaq> get filteredFaqs {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return HelpFaq.all;
    return HelpFaq.all.where((faq) {
      return faq.question.toLowerCase().contains(query) ||
          faq.answer.toLowerCase().contains(query) ||
          faq.category.toLowerCase().contains(query);
    }).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    _listenToRequests();
  }

  void _listenToRequests() {
    errorMessage.value = '';
    try {
      _subscription = _repository.watchMyRequests().listen(
        (rows) {
          _receivedStreamValue = true;
          requests.assignAll(rows.map(HelpSupportRequest.fromMap));
          isLoading.value = false;
        },
        onError: (Object error) {
          isLoading.value = false;
          errorMessage.value = error.toString().replaceFirst('Exception: ', '');
        },
      );
    } catch (error) {
      isLoading.value = false;
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    }
  }

  void setSearch(String value) => searchQuery.value = value;

  void setCategory(String? value) {
    if (value == null) return;
    selectedCategory.value = value;
    requestError.value = '';
  }

  Future<void> refreshRequests() async {
    try {
      final rows = await _repository.fetchMyRequests();
      requests.assignAll(rows);
      errorMessage.value = '';
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> submitRequest() async {
    if (isSubmitting.value) return false;
    final subject = subjectController.text.trim();
    final message = messageController.text.trim();
    if (subject.length < 5 || subject.length > 140) {
      requestError.value = 'Subject must be between 5 and 140 characters.';
      return false;
    }
    if (message.length < 20 || message.length > 5000) {
      requestError.value = 'Please describe the issue in 20 to 5,000 characters.';
      return false;
    }
    final reference = referenceController.text.trim();
    if (reference.length > 100) {
      requestError.value = 'Project reference must be 100 characters or fewer.';
      return false;
    }

    isSubmitting.value = true;
    requestError.value = '';
    try {
      await _repository.submitRequest(
        category: selectedCategory.value,
        subject: subject,
        message: message,
        relatedReference: reference,
      );
      subjectController.clear();
      messageController.clear();
      referenceController.clear();
      Get.snackbar(
        'Support request submitted',
        'Your request has been saved. You can track its status below.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      if (!_receivedStreamValue) await refreshRequests();
      return true;
    } on HelpSupportException catch (error) {
      requestError.value = error.message;
      return false;
    } catch (_) {
      requestError.value = 'Unable to submit your request. Please try again.';
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    unawaited(_subscription?.cancel());
    searchController.dispose();
    subjectController.dispose();
    messageController.dispose();
    referenceController.dispose();
    super.onClose();
  }
}
