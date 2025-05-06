import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:test2/model/reservation.dart';

class ReservationService {
  static final String baseUrl = 'http://localhost:8080/api';

  static Future<List<String>> fetchTablesForDateTime(DateTime dateTime) async {
    try {
      String formattedDateTime = dateTime.toIso8601String();
      final response = await http.get(
        Uri.parse('$baseUrl/tables/status/available?datetime=$formattedDateTime'),
        headers: {'Content-Type': 'application/json'},
      );

      print("Fetch tables response: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<String> tables = data.map((table) => table['tableNumber'].toString()).toList();
        return tables;
      } else {
        print("Failed to fetch tables for datetime: $formattedDateTime");
        return [];
      }
    } catch (e) {
      print("Error fetching tables by datetime: $e");
      return [];
    }
  }

  static Future<Reservation?> createReservation(Reservation reservation) async {
    try {
      print("Creating reservation: ${jsonEncode(reservation.toJson())}");

      final response = await http.post(
        Uri.parse('$baseUrl/reservations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(reservation.toJson()),
      );

      print("Create reservation response: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Reservation.fromJson(data); // Trả về đối tượng đầy đủ có ID
      } else {
        return null;
      }
    } catch (e) {
      print("Error creating reservation: $e");
      return null;
    }
  }
}
