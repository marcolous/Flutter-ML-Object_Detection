import 'package:flutter/material.dart';
import 'package:test_lyna_cam2/models/nutrient_model.dart';
import 'package:test_lyna_cam2/services/nutritions_service.dart';

class AppProvider with ChangeNotifier {
  List<LabelNutrients> labelNutrients = [];
  bool isLoading = false;

  Future<void> getNutritionsFdcId(List<String> predictions) async {
    isLoading = true;
    labelNutrients.clear();
    notifyListeners();

    for (final pred in predictions) {
      final result = await NutritionsService.getNutritionsFdcId(pred);
      labelNutrients.add(result);
    }

    isLoading = false;
    notifyListeners();
  }

  void clearLabelNutrients() {
    labelNutrients.clear();
    notifyListeners();
  }
}
