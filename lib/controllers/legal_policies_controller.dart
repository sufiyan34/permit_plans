import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permit_plans/models/legal_policy_model.dart';

class LegalPoliciesController extends GetxController {
  final selectedPolicyId = 'terms'.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();

  LegalPolicyDocument get selectedDocument =>
      LegalPolicyDocuments.byId(selectedPolicyId.value);

  List<LegalPolicySection> get visibleSections {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return selectedDocument.sections;

    return selectedDocument.sections.where((section) {
      final titleMatches = section.title.toLowerCase().contains(query);
      final bodyMatches = section.paragraphs.any(
        (paragraph) => paragraph.toLowerCase().contains(query),
      );
      return titleMatches || bodyMatches;
    }).toList(growable: false);
  }

  @override
  void onInit() {
    super.onInit();
    final requestedPolicy = Get.parameters['policy'];
    selectedPolicyId.value = LegalPolicyDocuments.byId(requestedPolicy).id;
  }

  void selectPolicy(String id) {
    selectedPolicyId.value = LegalPolicyDocuments.byId(id).id;
    clearSearch();
  }

  void setSearch(String value) => searchQuery.value = value;

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
