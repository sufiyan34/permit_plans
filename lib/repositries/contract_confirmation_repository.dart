import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:permit_plans/models/contract_confirmation_model.dart';

class ContractConfirmationException implements Exception {
  const ContractConfirmationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ContractConfirmationRepository {
  ContractConfirmationRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<ContractConfirmationModel> fetchPreview(String quoteId) async {
    if (_client.auth.currentUser == null) {
      throw const ContractConfirmationException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'get_client_contract_preview',
        params: {'p_quote_id': quoteId},
      );
      final rows = response as List<dynamic>? ?? const <dynamic>[];
      if (rows.isEmpty) {
        throw const ContractConfirmationException(
          'This quote is not accepted yet, or it does not belong to your account.',
        );
      }
      final first = rows.first;
      if (first is! Map<String, dynamic>) {
        throw const ContractConfirmationException(
          'The contract preview returned an unexpected response.',
        );
      }
      return ContractConfirmationModel.fromJson(first);
    } on ContractConfirmationException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[ContractConfirmationRepository.fetchPreview] '
        '${error.code}: ${error.message}',
      );
      throw ContractConfirmationException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[ContractConfirmationRepository.fetchPreview] $error');
      throw const ContractConfirmationException(
        'Unable to load the contract summary. Please try again.',
      );
    }
  }

  Future<String> confirmContract(String quoteId) async {
    if (_client.auth.currentUser == null) {
      throw const ContractConfirmationException(
        'Your session has expired. Please sign in again.',
      );
    }

    try {
      final response = await _client.rpc(
        'confirm_accepted_quote_contract',
        params: {'p_quote_id': quoteId},
      );
      if (response == null || response.toString().isEmpty) {
        throw const ContractConfirmationException(
          'The contract was not confirmed. Please try again.',
        );
      }
      return response.toString();
    } on ContractConfirmationException {
      rethrow;
    } on PostgrestException catch (error) {
      // ignore: avoid_print
      print(
        '[ContractConfirmationRepository.confirmContract] '
        '${error.code}: ${error.message}',
      );
      throw ContractConfirmationException(_friendlyError(error));
    } catch (error) {
      // ignore: avoid_print
      print('[ContractConfirmationRepository.confirmContract] $error');
      throw const ContractConfirmationException(
        'Unable to confirm the contract. Please try again.',
      );
    }
  }

  String _friendlyError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (error.code == '42883' ||
        message.contains('get_client_contract_preview') ||
        message.contains('confirm_accepted_quote_contract')) {
      return 'Contract confirmation is not installed yet. Run migration 010 in Supabase SQL Editor.';
    }
    if (error.code == '42501' || error.code == '28000') {
      return 'Only the Client who owns this accepted quote can confirm its contract.';
    }
    if (message.contains('not accepted') || message.contains('awaiting_payment')) {
      return 'This quote is not ready for contract confirmation. Refresh your quotes and try again.';
    }
    if (message.contains('already has a contract')) {
      return 'A contract already exists for this task. Refresh the page to view it.';
    }
    return 'We could not complete this step. ${error.message}';
  }
}
