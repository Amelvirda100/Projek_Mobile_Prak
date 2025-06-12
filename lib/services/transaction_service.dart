import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:budgetlisting/models/transaction_model.dart';

class TransactionAPI {
  static const String url = "https://budget-listing.onrender.com/api";

  static Future<Map<String, dynamic>> getTransactions(String token) async {
    final response = await http.get(
      Uri.parse("$url/transactions"),
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(response.body);
  }

   static Future<Map<String, dynamic>> getTransactionById(String token, int id) async {
    final response = await http.get(
      Uri.parse('$url/transactions/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      return data['transaction'] ?? {};
    } else {
      throw Exception('Failed to load transaction data with id $id');
    }
  }

  static Future<Map<String, dynamic>> addTransaction(
    Transaction transaction,
    String token,
  ) async {
    final response = await http.post(
      Uri.parse("$url/transactions"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "type": transaction.type,
        "amount": transaction.amount,
        "category": transaction.category,
        "note": transaction.note,
        "date": transaction.date,
        "currency_code": transaction.currencyCode,
        "currency_rate": transaction.currencyRate,
        "time_zone": transaction.timeZone,
        "location_id": transaction.locationName,
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> updateTransaction(
    Transaction transaction,
    int id,
    String token,
  ) async {
    final response = await http.put(
      Uri.parse("$url/transactions/$id"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode({
        "type": transaction.type,
        "amount": transaction.amount,
        "category": transaction.category,
        "note": transaction.note,
        "date": transaction.date,
        "currency_code": transaction.currencyCode,
        "currency_rate": transaction.currencyRate,
        "time_zone": transaction.timeZone,
        "location_id": transaction.locationName
      }),
    );
    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> deleteTransaction(
    int id,
    String token,
  ) async {
    final response = await http.delete(
      Uri.parse("$url/transactions/$id"),
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> addLocation({
    required String token,
    required String name,
    required double latitude,
    required double longitude,
  }) async {
    final response = await http.post(
      Uri.parse("$url/locations"),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
      }),
    );

    if (response.statusCode == 201) {
      return {'success': true, 'message': 'Lokasi berhasil disimpan'};
    } else {
      final data = jsonDecode(response.body);
      return {
        'success': false,
        'message': data['error'] ?? 'Terjadi kesalahan saat menyimpan lokasi',
      };
    }
  }
}
