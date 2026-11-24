import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_earnings_currency_summary.dart';
import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/repositries/engineer_projects_repository.dart';

/// Screen 26 — read-only earnings summary derived from completed contracts.
/// It does not claim that funds have settled or are available to withdraw.
class EngineerEarningsController extends GetxController {
  EngineerEarningsController({required EngineerProjectsRepository repository})
      : _repository = repository;

  final EngineerProjectsRepository _repository;
  final projects = <EngineerProjectModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final searchQuery = ''.obs;
  final searchController = TextEditingController();
  final lastUpdatedAt = Rxn<DateTime>();

  List<EngineerProjectModel> get completedProjects {
    final result = projects
        .where((project) => project.contractStatus == 'completed')
        .toList(growable: false);
    return result;
  }

  List<EngineerProjectModel> get filteredCompletedProjects {
    final query = searchQuery.value.trim().toLowerCase();
    final result = completedProjects.where((project) {
      if (query.isEmpty) return true;
      return project.taskTitle.toLowerCase().contains(query) ||
          project.clientDisplayName.toLowerCase().contains(query) ||
          project.currency.toLowerCase().contains(query) ||
          project.contractShortId.toLowerCase().contains(query);
    }).toList(growable: false);

    return result;
  }

  Map<String, EngineerEarningsCurrencySummary> get currencySummaries {
    final summaries = EngineerEarningsCurrencySummary.fromCompletedProjects(
      completedProjects,
    );
    return Map<String, EngineerEarningsCurrencySummary>.fromEntries(
      summaries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  int get activeProjectCount => projects.where((project) => const {
        'funded',
        'in_progress',
        'submitted',
        'revision_requested',
      }.contains(project.contractStatus)).length;

  int get awaitingFundingCount => projects
      .where((project) => project.contractStatus == 'awaiting_payment')
      .length;

  int get completedProjectCount => completedProjects.length;

  @override
  void onInit() {
    super.onInit();
    loadEarnings();
  }

  Future<void> loadEarnings({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) return;

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final allProjects = <EngineerProjectModel>[];
      const pageSize = 100;
      var offset = 0;
      while (true) {
        final page = await _repository.fetchProjects(
          limit: pageSize,
          offset: offset,
        );
        allProjects.addAll(page);
        if (page.length < pageSize) break;
        offset += page.length;
      }
      projects.assignAll(allProjects);
      lastUpdatedAt.value = DateTime.now();
    } on EngineerProjectsRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'We could not load your earnings. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadEarnings(refresh: true);

  void updateSearch(String value) => searchQuery.value = value;

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
