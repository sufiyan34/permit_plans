import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_earnings_currency_summary.dart';
import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/repositries/engineer_projects_repository.dart';

/// Screen 27 — provider-pending payout overview.
///
/// This controller only reads completed contract snapshots. It deliberately
/// does not create withdrawal requests, collect bank/card credentials, or
/// claim that contract earnings have settled or are withdrawable.
class EngineerPayoutManagementController extends GetxController {
  EngineerPayoutManagementController({
    required EngineerProjectsRepository repository,
  }) : _repository = repository;

  final EngineerProjectsRepository _repository;

  final projects = <EngineerProjectModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final lastUpdatedAt = Rxn<DateTime>();

  List<EngineerProjectModel> get completedProjects => projects
      .where((project) => project.contractStatus == 'completed')
      .toList(growable: false);

  Map<String, EngineerEarningsCurrencySummary> get currencySummaries {
    final summaries = EngineerEarningsCurrencySummary.fromCompletedProjects(
      completedProjects,
    );
    return Map<String, EngineerEarningsCurrencySummary>.fromEntries(
      summaries.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  int get completedProjectCount => completedProjects.length;

  int get activeProjectCount => projects.where((project) => const {
        'funded',
        'in_progress',
        'submitted',
        'revision_requested',
      }.contains(project.contractStatus)).length;

  int get awaitingFundingCount => projects
      .where((project) => project.contractStatus == 'awaiting_payment')
      .length;

  @override
  void onInit() {
    super.onInit();
    loadOverview();
  }

  Future<void> loadOverview({bool refresh = false}) async {
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
          'Payout information could not be loaded. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadOverview(refresh: true);
}
