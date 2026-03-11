import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';

class QuoteService {
  static List<String> _quotes = [];

  static Future<void> load() async {
    if (_quotes.isNotEmpty) return;
    final str = await rootBundle.loadString('assets/quotes.json');
    final List data = json.decode(str);
    _quotes = data.map((e) => e.toString()).toList();
  }

  static String random() {
    if (_quotes.isEmpty) return 'Work hard, stay consistent. 🌟';
    return _quotes[Random().nextInt(_quotes.length)];
  }
}
