import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = 'e2af77d94d4a46385a180381ded080ee';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5/weather';

  Future<String?> getCurrentWeather(double lat, double lon) async {
    try {
      final url = '$baseUrl?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=pt_br';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = data['main']['temp'].toStringAsFixed(1);
        final desc = data['weather'][0]['description'];
        return '$temp°C, $desc';
      }
    } catch (e) {
      return null;
    }
    return null;
  }
}