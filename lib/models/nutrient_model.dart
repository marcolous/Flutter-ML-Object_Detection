// lib/models/nutrient_model.dart

import 'package:json_annotation/json_annotation.dart';

part 'nutrient_model.g.dart';

@JsonSerializable()
class LabelNutrients {
  final NutrientValue? fat;
  final NutrientValue? saturatedFat;
  final NutrientValue? transFat;
  final NutrientValue? cholesterol;
  final NutrientValue? sodium;
  final NutrientValue? carbohydrates;
  final NutrientValue? fiber;
  final NutrientValue? sugars;
  final NutrientValue? protein;
  final NutrientValue? calcium;
  final NutrientValue? iron;
  final NutrientValue? potassium;
  final NutrientValue? calories;

  LabelNutrients({
    this.fat,
    this.saturatedFat,
    this.transFat,
    this.cholesterol,
    this.sodium,
    this.carbohydrates,
    this.fiber,
    this.sugars,
    this.protein,
    this.calcium,
    this.iron,
    this.potassium,
    this.calories,
  });

  factory LabelNutrients.fromJson(Map<String, dynamic> json) =>
      _$LabelNutrientsFromJson(json);
  Map<String, dynamic> toJson() => _$LabelNutrientsToJson(this);
}

@JsonSerializable()
class NutrientValue {
  final double value;

  NutrientValue({required this.value});

  factory NutrientValue.fromJson(Map<String, dynamic> json) =>
      _$NutrientValueFromJson(json);
  Map<String, dynamic> toJson() => _$NutrientValueToJson(this);
}

extension LabelNutrientsExtension on LabelNutrients {
  List<MapEntry<String, String>> toLabelList() {
    final items = <MapEntry<String, String>>[];
    String setDecimalNum(double value) {
      return value.toStringAsFixed(2);
    }

    void addIfNotNull(String label, NutrientValue? nutrient) {
      if (nutrient != null && nutrient.value > 0) {
        final value = setDecimalNum(nutrient.value);
        items.add(MapEntry(label, value));
      }
    }

    addIfNotNull('Fat', fat);
    addIfNotNull('Saturated Fat', saturatedFat);
    addIfNotNull('Trans Fat', transFat);
    addIfNotNull('Cholesterol', cholesterol);
    addIfNotNull('Sodium', sodium);
    addIfNotNull('Carbohydrates', carbohydrates);
    addIfNotNull('Fiber', fiber);
    addIfNotNull('Sugars', sugars);
    addIfNotNull('Protein', protein);
    addIfNotNull('Calcium', calcium);
    addIfNotNull('Iron', iron);
    addIfNotNull('Potassium', potassium);
    addIfNotNull('Calories', calories);

    items
        .sort((a, b) => double.parse(b.value).compareTo(double.parse(a.value)));

    return items;
  }
}
