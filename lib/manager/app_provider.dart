import 'package:flutter/material.dart';
import 'package:test_lyna_cam2/models/nutrient_model.dart';
import 'package:test_lyna_cam2/services/nutritions_service.dart';

class AppProvider with ChangeNotifier {
  LabelNutrients? labelNutrients;
  bool isLoading = false;

  Future<void> getNutritionsFdcId(String prediction) async {
    isLoading = true;
    notifyListeners();

    labelNutrients = await NutritionsService.getNutritionsFdcId(prediction);

    isLoading = false;
    notifyListeners();
  }

  void clearLabelNutrients() {
    labelNutrients = null;
    notifyListeners();
  }
}
