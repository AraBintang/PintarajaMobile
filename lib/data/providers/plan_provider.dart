// ============================================================
// PLAN PROVIDER
// ============================================================

import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../services/api_service.dart';

class PlanModel {
  final int id;
  final String name;
  final double price;
  final int credits;
  final List<String> features;
  final bool isPopular;

  PlanModel({
    required this.id,
    required this.name,
    required this.price,
    required this.credits,
    required this.features,
    this.isPopular = false,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    // Backend mengirim price sebagai map per periode:
    // {weekly, weekly_discount, weekly_final, monthly, ..., yearly_final}
    double price = 0;
    final rawPrice = json['price'];
    if (rawPrice is Map) {
      final monthly =
          rawPrice['monthly_final'] ?? rawPrice['monthly'] ?? 0;
      price = double.tryParse(monthly.toString()) ?? 0;
    } else if (rawPrice != null) {
      price = double.tryParse(rawPrice.toString()) ?? 0;
    }

    final popularRaw = json['isPopular'] ?? json['is_popular'];

    return PlanModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      price: price,
      credits: json['quota'] ?? json['credits'] ?? 0,
      features:
          (json['features'] as List?)?.map((e) => e.toString()).toList() ??
              [],
      isPopular: popularRaw == true ||
          popularRaw == 1 ||
          popularRaw.toString().toUpperCase() == 'Y',
    );
  }

  bool get isFree => price == 0;
}

class PlanProvider extends ChangeNotifier {
  List<PlanModel> _plans = [];
  bool _isLoading = false;
  String? _error;

  List<PlanModel> get plans => _plans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadPlans() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await ApiService.instance.get(ApiConstants.plans);
      final list = data['data'] ?? data;
      _plans = (list as List).map((e) => PlanModel.fromJson(e)).toList();
    } on ApiException catch (e) {
      _error = e.message;
    }

    _isLoading = false;
    notifyListeners();
  }
}
