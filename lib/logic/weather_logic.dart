import 'package:flutter/material.dart';

class WeatherLogic {

  static Map<String, dynamic> evaluate(String? weatherInfo) {
    if (weatherInfo == null) {
      return {'status': 'Sem dados', 'color': Colors.grey, 'icon': Icons.help_outline};
    }

    final lowerInfo = weatherInfo.toLowerCase();


    double temp = 0;
    try {
      final tempPart = weatherInfo.split('°')[0];
      temp = double.parse(tempPart);
    } catch (_) {

    }


    if (lowerInfo.contains('chuva') || lowerInfo.contains('tempestade')) {
      return {
        'status': 'Melhor treinar indoor ☔',
        'color': Colors.orange,
        'icon': Icons.umbrella
      };
    } else if (temp > 35) {
      return {
        'status': 'Muito quente! Hidrate-se 🥵',
        'color': Colors.deepOrange,
        'icon': Icons.wb_sunny
      };
    } else if (temp < 5) {
      return {
        'status': 'Muito frio! Agasalhe-se ❄️',
        'color': Colors.blue,
        'icon': Icons.ac_unit
      };
    } else {
      return {
        'status': 'Clima perfeito para treino! 🏃',
        'color': Colors.green,
        'icon': Icons.check_circle
      };
    }
  }
}