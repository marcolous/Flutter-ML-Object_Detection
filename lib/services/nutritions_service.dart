import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:test_lyna_cam2/models/nutrient_model.dart';

class NutritionsService {
  static final dio = Dio();
  static final apiKey = dotenv.env['NUTRITIONS_API_KEY'] ?? 'no key';
  static const baseUrl = 'https://api.nal.usda.gov/fdc/v1';

  static Future<LabelNutrients> getNutritionsFdcId(String prediction) async {
    try {
      final searchUrl =
          '$baseUrl/foods/search?query=$prediction&api_key=$apiKey';
      final result = await dio.get(searchUrl);
      final foods = result.data['foods'];
      if (foods == null || foods.isEmpty) {
        debugPrint('No food results found');
        return LabelNutrients();
      }
      final fdcId = foods[0]['fdcId'];
      final labels = await getNutritionsResult(fdcId);
      return labels;
    } catch (e) {
      debugPrint('Something went wrong getting nutritions $e');
      return LabelNutrients();
    }
  }

  static Future<LabelNutrients> getNutritionsResult(int fdcId) async {
    try {
      final fdcUrl = '$baseUrl/food/$fdcId?api_key=$apiKey';
      final result = await dio.get(fdcUrl);

      return LabelNutrients.fromJson(result.data['labelNutrients']);
    } catch (e) {
      debugPrint('Something went wrong getting nutritions: $e');
      return LabelNutrients();
    }
  }
}
