import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:permit_plans/models/admin_support_ticket_model.dart';
import 'package:permit_plans/repositries/admin_support_inbox_repository.dart';

class AdminSupportInboxController extends GetxController {
  AdminSupportInboxController({required AdminSupportInboxRepository repository})
      : _repository = repository;

  final AdminSupportInboxRepository _repository;

  final tickets = <AdminSupportTicket>[].obs;
  final Rxn<AdminSupportTicket> selectedTicket = Rxn<AdminSupportTicket>();
  final searchQuery = ''.obs;
  final statusFilter = 'all'.obs;
  final categoryFilter = 'all'.obs;
  final priorityFilter = 'all'.obs;
  final selectedStatus = 'open'.obs;
  final selectedPriority = 'normal'.obs;
  final isLoading = true.obs;
  final isRefreshing = false.obs;
  final isSaving = false.obs;
  final errorMessage = ''.obs;
  final saveError = ''.obs;

  final searchController = TextEditingController();
  final replyController = TextEditingController();

  Timer? _searchTimer;

  int get openCount => tickets.where((t) => t.status == 'open').length;
  int get inReviewCount => tickets.where((t) => t.status == 'in_review').length;
  int get urgentCount => tickets.where((t) => t.priority == 'urgent').length;
  int get resolvedCount => tickets.where((t) => t.status == 'resolved').length;

  @override
  void onInit() {
    super.onInit();
    _repository.subscribeToChanges(() => unawaited(loadTickets(silent: true)));
    loadTickets();
  }

  void search(String value) {
    searchQuery.value = value;
    _searchTimer?.cancel();
    _searchTimer = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(loadTickets()),
    );
  }

  void setStatusFilter(String value) {
    statusFilter.value = value;
    loadTickets();
  }

  void setCategoryFilter(String value) {
    categoryFilter.value = value;
    loadTickets();
  }

  void setPriorityFilter(String value) {
    priorityFilter.value = value;
    loadTickets();
  }

  Future<void> loadTickets({bool silent = false}) async {
    if (silent) {
      isRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    errorMessage.value = '';
    try {
      final result = await _repository.fetchTickets(
        search: searchQuery.value,
        status: statusFilter.value,
        category: categoryFilter.value,
        priority: priorityFilter.value,
      );
      tickets.assignAll(result);
      final currentId = selectedTicket.value?.id;
      if (currentId != null) {
        final updated = result.where((ticket) => ticket.id == currentId);
        if (updated.isNotEmpty) {
          _select(updated.first, resetReply: false);
        } else {
          selectedTicket.value = null;
          replyController.clear();
        }
      } else if (result.isNotEmpty) {
        _select(result.first);
      }
    } catch (error) {
      errorMessage.value = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  void selectTicket(AdminSupportTicket ticket) => _select(ticket);

  void _select(AdminSupportTicket ticket, {bool resetReply = true}) {
    selectedTicket.value = ticket;
    selectedStatus.value = ticket.status;
    selectedPriority.value = ticket.priority;
    if (resetReply) replyController.text = ticket.adminNote ?? '';
  }

  void setSelectedStatus(String? value) {
    if (value == null) return;
    selectedStatus.value = value;
    saveError.value = '';
  }

  void setSelectedPriority(String? value) {
    if (value == null) return;
    selectedPriority.value = value;
    saveError.value = '';
  }

  Future<void> saveUpdate() async {
    final ticket = selectedTicket.value;
    if (ticket == null || isSaving.value) return;
    final reply = replyController.text.trim();
    if (reply.length > 3000) {
      saveError.value = 'Support response must be 3,000 characters or fewer.';
      return;
    }

    isSaving.value = true;
    saveError.value = '';
    try {
      await _repository.updateTicket(
        requestId: ticket.id,
        status: selectedStatus.value,
        priority: selectedPriority.value,
        adminNote: reply,
      );
      await loadTickets();
      Get.snackbar(
        'Ticket updated',
        'The status, priority and support update have been saved.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } on AdminSupportInboxException catch (error) {
      saveError.value = error.message;
    } catch (_) {
      saveError.value = 'Unable to update this ticket. Please try again.';
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    _searchTimer?.cancel();
    unawaited(_repository.dispose());
    searchController.dispose();
    replyController.dispose();
    super.onClose();
  }
}
