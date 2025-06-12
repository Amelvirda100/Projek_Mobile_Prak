import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:budgetlisting/db/local_db.dart';
import 'package:budgetlisting/utils/enc_pass.dart';
import 'package:flutter/material.dart';
import 'package:budgetlisting/utils/check_conenction.dart';
import 'package:budgetlisting/pages/home_page.dart';

const String baseUrl = 'https://budget-listing.onrender.com/api';

Future<void> login(String email, String password, BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';
  final hashed = hashPassword(password);

  if (await isConnected()) {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (data['message'] == 'Login successful') {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);
      await prefs.setString('token', data['token']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      showSnackbar(context, data['message'] ?? 'Login gagal (online)');
    }
  } else {
    final valid = await DatabaseHelper.verifyUser(email, hashed);
    if (valid) {
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('email', email);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      showSnackbar(
        context,
        'Login gagal. Tidak ada koneksi dan user tidak ditemukan offline.',
      );
    }
  }
}

Future<void> register(
  String name,
  String email,
  String password,
  BuildContext context,
) async {
  if (!await isConnected()) {
    showSnackbar(context, 'Registrasi hanya dapat dilakukan saat online.');
    return;
  }

  final response = await http.post(
    Uri.parse('$baseUrl/register'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'name': name, 'email': email, 'password': password}),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 201) {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('email', email);
    await prefs.setString('token', data['token']);
    await DatabaseHelper.insertUser(email, hashPassword(password));

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  } else {
    showSnackbar(context, data['message'] ?? 'Registrasi gagal.');
  }
}

void showSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
