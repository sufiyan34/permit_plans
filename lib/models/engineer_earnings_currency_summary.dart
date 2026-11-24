import 'package:intl/intl.dart';

import 'package:permit_plans/models/engineer_project_model.dart';

/// Earnings totals for one currency only.
///
/// WorkBridge is an international marketplace, so amounts in different
/// currencies must never be added together without an FX conversion record.
class EngineerEarningsCurrencySummary {
  const EngineerEarningsCurrencySummary({
    required this.currency,
    required this.projectCount,
    required this.grossMinor,
    required this.platformFeeMinor,
    required this.engineerNetMinor,
  });

  final String currency;
  final int projectCount;
  final int grossMinor;
  final int platformFeeMinor;
  final int engineerNetMinor;

  String formatMinor(int minor) {
    final digits = _fractionDigits(currency);
    final divisor = digits == 0 ? 1 : digits == 3 ? 1000 : 100;
    return NumberFormat.currency(name: currency, decimalDigits: digits)
        .format(minor / divisor);
  }

  String get formattedGross => formatMinor(grossMinor);
  String get formattedPlatformFee => formatMinor(platformFeeMinor);
  String get formattedEngineerNet => formatMinor(engineerNetMinor);

  static Map<String, EngineerEarningsCurrencySummary> fromCompletedProjects(
    Iterable<EngineerProjectModel> projects,
  ) {
    final totals = <String, _MutableCurrencyTotals>{};

    for (final project in projects) {
      if (project.contractStatus != 'completed') continue;
      final currency = project.currency.toUpperCase();
      final total = totals.putIfAbsent(currency, _MutableCurrencyTotals.new);
      total.projectCount++;
      total.grossMinor += project.amountMinor;
      total.platformFeeMinor += project.platformFeeMinor;
      total.engineerNetMinor += project.engineerNetMinor;
    }

    final result = <String, EngineerEarningsCurrencySummary>{};
    for (final entry in totals.entries) {
      final value = entry.value;
      result[entry.key] = EngineerEarningsCurrencySummary(
        currency: entry.key,
        projectCount: value.projectCount,
        grossMinor: value.grossMinor,
        platformFeeMinor: value.platformFeeMinor,
        engineerNetMinor: value.engineerNetMinor,
      );
    }
    return result;
  }

  static int _fractionDigits(String currency) {
    final code = currency.toUpperCase();
    if (const {
      'BIF', 'CLP', 'DJF', 'GNF', 'ISK', 'JPY', 'KMF', 'KRW', 'PYG',
      'RWF', 'UGX', 'VND', 'VUV', 'XAF', 'XOF', 'XPF',
    }.contains(code)) return 0;
    if (const {'BHD', 'IQD', 'JOD', 'KWD', 'LYD', 'OMR', 'TND'}
        .contains(code)) return 3;
    return 2;
  }
}

class _MutableCurrencyTotals {
  int projectCount = 0;
  int grossMinor = 0;
  int platformFeeMinor = 0;
  int engineerNetMinor = 0;
}
