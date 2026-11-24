import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_project_model.dart';
import 'package:permit_plans/repositries/engineer_projects_repository.dart';

class EngineerProjectsController extends GetxController {
  EngineerProjectsController({required EngineerProjectsRepository repository})
      : _repository = repository;

  final EngineerProjectsRepository _repository;

  final projects = <EngineerProjectModel>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;
  final selectedProjectId = RxnString();
  final selectedFilter = 'All projects'.obs;

  static const filters = <String>[
    'All projects',
    'Awaiting funding',
    'In progress',
    'In review',
    'Revisions',
    'Completed',
    'Other',
  ];

  List<EngineerProjectModel> get filteredProjects {
    final filter = selectedFilter.value;
    if (filter == 'All projects') return projects.toList(growable: false);

    final group = switch (filter) {
      'Awaiting funding' => 'awaiting',
      'In progress' => 'active',
      'In review' => 'review',
      'Revisions' => 'revision',
      'Completed' => 'completed',
      _ => 'other',
    };

    return projects
        .where((project) => project.statusGroup == group)
        .toList(growable: false);
  }

  EngineerProjectModel? get selectedProject {
    final visible = filteredProjects;
    if (visible.isEmpty) return null;

    final id = selectedProjectId.value;
    for (final project in visible) {
      if (project.contractId == id) return project;
    }
    return visible.first;
  }

  int get awaitingFundingCount =>
      projects.where((project) => project.statusGroup == 'awaiting').length;

  int get activeCount =>
      projects.where((project) => project.statusGroup == 'active').length;

  int get reviewCount =>
      projects.where((project) => project.statusGroup == 'review').length;

  int get completedCount =>
      projects.where((project) => project.statusGroup == 'completed').length;

  @override
  void onInit() {
    super.onInit();
    loadProjects();
  }

  Future<void> loadProjects({bool refresh = false}) async {
    if (isLoading.value || isRefreshing.value) return;

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final result = await _repository.fetchProjects();
      projects.assignAll(result);
      final selectedStillExists = result.any(
        (project) => project.contractId == selectedProjectId.value,
      );
      if (!selectedStillExists) {
        selectedProjectId.value = result.isEmpty ? null : result.first.contractId;
      }
      _ensureSelectionVisible();
    } on EngineerProjectsRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value =
          'Unable to load your projects right now. Please try again.';
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refresh() => loadProjects(refresh: true);

  void selectProject(EngineerProjectModel project) {
    selectedProjectId.value = project.contractId;
  }

  void selectFilter(String filter) {
    if (!filters.contains(filter)) return;
    selectedFilter.value = filter;
    _ensureSelectionVisible();
  }

  void _ensureSelectionVisible() {
    final visible = filteredProjects;
    if (visible.isEmpty) {
      selectedProjectId.value = null;
      return;
    }
    final stillVisible = visible.any(
      (project) => project.contractId == selectedProjectId.value,
    );
    if (!stillVisible) selectedProjectId.value = visible.first.contractId;
  }
}
