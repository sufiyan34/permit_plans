import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/engineer_directory_model.dart';
import 'package:permit_plans/repositries/engineer_directory_repository.dart';

class EngineerDirectoryController extends GetxController {
  EngineerDirectoryController({required EngineerDirectoryRepository repository})
      : _repository = repository;

  final EngineerDirectoryRepository _repository;

  final searchController = TextEditingController();
  final searchText = ''.obs;
  final engineers = <EngineerDirectoryProfile>[].obs;
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final isLoadingMore = false.obs;
  final errorMessage = ''.obs;
  final totalCount = 0.obs;

  final countryFilter = ''.obs;
  final skillFilter = ''.obs;
  final experienceFilter = 'all'.obs;
  final availabilityFilter = 'all'.obs;
  final sortBy = 'recent'.obs;

  static const int _pageSize = 20;
  Timer? _searchDebounce;
  int _requestToken = 0;

  bool get hasMore => engineers.length < totalCount.value;
  bool get hasActiveFilters =>
      countryFilter.value.isNotEmpty ||
      skillFilter.value.isNotEmpty ||
      experienceFilter.value != 'all' ||
      availabilityFilter.value != 'all' ||
      sortBy.value != 'recent';

  @override
  void onInit() {
    super.onInit();
    loadEngineers();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      loadEngineers();
    });
  }

  Future<void> loadEngineers({bool refresh = false}) async {
    // A newer search/filter request supersedes an older in-flight request.
    // The token prevents stale results from replacing the latest results.
    final token = ++_requestToken;

    if (refresh) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';

    try {
      final page = await _repository.browse(
        search: searchController.text,
        countryName: countryFilter.value,
        skill: skillFilter.value,
        experienceLevel: experienceFilter.value,
        availability: availabilityFilter.value,
        sortBy: sortBy.value,
        limit: _pageSize,
        offset: 0,
      );
      if (token != _requestToken) return;
      engineers.assignAll(page.engineers);
      totalCount.value = page.totalCount;
    } on EngineerDirectoryRepositoryException catch (error) {
      if (token == _requestToken) errorMessage.value = error.message;
    } catch (_) {
      if (token == _requestToken) {
        errorMessage.value = 'Unable to load engineers. Please try again.';
      }
    } finally {
      if (token == _requestToken) {
        isLoading.value = false;
        isRefreshing.value = false;
      }
    }
  }

  Future<void> loadMore() async {
    if (!hasMore || isLoadingMore.value || isLoading.value || isRefreshing.value) {
      return;
    }
    final token = _requestToken;
    isLoadingMore.value = true;
    try {
      final page = await _repository.browse(
        search: searchController.text,
        countryName: countryFilter.value,
        skill: skillFilter.value,
        experienceLevel: experienceFilter.value,
        availability: availabilityFilter.value,
        sortBy: sortBy.value,
        limit: _pageSize,
        offset: engineers.length,
      );
      if (token != _requestToken) return;
      engineers.addAll(page.engineers);
      totalCount.value = page.totalCount;
    } on EngineerDirectoryRepositoryException catch (error) {
      errorMessage.value = error.message;
    } catch (_) {
      errorMessage.value = 'Unable to load more engineers.';
    } finally {
      isLoadingMore.value = false;
    }
  }

  Future<void> applyFilters({
    required String country,
    required String skill,
    required String experience,
    required String availability,
  }) async {
    countryFilter.value = country.trim();
    skillFilter.value = skill.trim();
    experienceFilter.value = experience;
    availabilityFilter.value = availability;
    await loadEngineers();
  }

  Future<void> setSort(String value) async {
    sortBy.value = value;
    await loadEngineers();
  }

  Future<void> clearFilters() async {
    countryFilter.value = '';
    skillFilter.value = '';
    experienceFilter.value = 'all';
    availabilityFilter.value = 'all';
    sortBy.value = 'recent';
    searchController.clear();
    searchText.value = '';
    await loadEngineers();
  }
}
