// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nutrient_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabelNutrients _$LabelNutrientsFromJson(Map<String, dynamic> json) =>
    LabelNutrients(
      fat: json['fat'] == null
          ? null
          : NutrientValue.fromJson(json['fat'] as Map<String, dynamic>),
      saturatedFat: json['saturatedFat'] == null
          ? null
          : NutrientValue.fromJson(
              json['saturatedFat'] as Map<String, dynamic>),
      transFat: json['transFat'] == null
          ? null
          : NutrientValue.fromJson(json['transFat'] as Map<String, dynamic>),
      cholesterol: json['cholesterol'] == null
          ? null
          : NutrientValue.fromJson(json['cholesterol'] as Map<String, dynamic>),
      sodium: json['sodium'] == null
          ? null
          : NutrientValue.fromJson(json['sodium'] as Map<String, dynamic>),
      carbohydrates: json['carbohydrates'] == null
          ? null
          : NutrientValue.fromJson(
              json['carbohydrates'] as Map<String, dynamic>),
      fiber: json['fiber'] == null
          ? null
          : NutrientValue.fromJson(json['fiber'] as Map<String, dynamic>),
      sugars: json['sugars'] == null
          ? null
          : NutrientValue.fromJson(json['sugars'] as Map<String, dynamic>),
      protein: json['protein'] == null
          ? null
          : NutrientValue.fromJson(json['protein'] as Map<String, dynamic>),
      calcium: json['calcium'] == null
          ? null
          : NutrientValue.fromJson(json['calcium'] as Map<String, dynamic>),
      iron: json['iron'] == null
          ? null
          : NutrientValue.fromJson(json['iron'] as Map<String, dynamic>),
      potassium: json['potassium'] == null
          ? null
          : NutrientValue.fromJson(json['potassium'] as Map<String, dynamic>),
      calories: json['calories'] == null
          ? null
          : NutrientValue.fromJson(json['calories'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LabelNutrientsToJson(LabelNutrients instance) =>
    <String, dynamic>{
      'fat': instance.fat,
      'saturatedFat': instance.saturatedFat,
      'transFat': instance.transFat,
      'cholesterol': instance.cholesterol,
      'sodium': instance.sodium,
      'carbohydrates': instance.carbohydrates,
      'fiber': instance.fiber,
      'sugars': instance.sugars,
      'protein': instance.protein,
      'calcium': instance.calcium,
      'iron': instance.iron,
      'potassium': instance.potassium,
      'calories': instance.calories,
    };

NutrientValue _$NutrientValueFromJson(Map<String, dynamic> json) =>
    NutrientValue(
      value: (json['value'] as num).toDouble(),
    );

Map<String, dynamic> _$NutrientValueToJson(NutrientValue instance) =>
    <String, dynamic>{
      'value': instance.value,
    };
