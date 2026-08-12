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

  factory PlanModel.fromJson(Map<String, dynamic> json) => PlanModel(
    id: json['id'] ?? 0,
    name: json['name'] ?? '',
    price: double.tryParse(json['price']?.toString() ?? '0') ?? 0,
    credits: json['credits'] ?? 0,
    features: (json['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
    isPopular: json['is_popular'] == true || json['is_popular'] == 1,
  );

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
