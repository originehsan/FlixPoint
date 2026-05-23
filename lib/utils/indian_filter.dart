import 'package:flutter/material.dart';

// Indian language codes supported by TMDb
// These are the most reliable way to filter
// Indian origin movies — more consistent than
// with_origin_country=IN which TMDb tags poorly
const List<String> indianLanguages = [
  'hi', // Hindi
  'ta', // Tamil
  'te', // Telugu
  'ml', // Malayalam
  'kn', // Kannada
  'bn', // Bengali
  'mr', // Marathi
  'pa', // Punjabi
  'gu', // Gujarati
];

// Preloaded languages — fetched on app start
// Others load on first tab tap then cache
const List<String> preloadLanguages = [
  'hi',
  'ta',
  'te',
];

// Check if a movie is Indian origin
// Uses original_language field from TMDb
bool isIndianMovie(Map<String, dynamic> movie) {
  return indianLanguages.contains(
    movie['original_language'],
  );
}

// Filter a list to Indian movies only
List<Map<String, dynamic>> filterIndian(
  List<Map<String, dynamic>> movies,
) {
  return movies.where(isIndianMovie).toList();
}

// Language display name
String languageName(String code) {
  switch (code) {
    case 'hi': return 'Hindi';
    case 'ta': return 'Tamil';
    case 'te': return 'Telugu';
    case 'ml': return 'Malayalam';
    case 'kn': return 'Kannada';
    case 'bn': return 'Bengali';
    case 'mr': return 'Marathi';
    case 'pa': return 'Punjabi';
    case 'gu': return 'Gujarati';
    default: return code.toUpperCase();
  }
}

// Accent color per language
// Used for tab highlight + section header
Color languageColor(String code) {
  switch (code) {
    case 'hi': return const Color(0xFFFF6B35);
    case 'ta': return const Color(0xFFE63946);
    case 'te': return const Color(0xFF2EC4B6);
    case 'ml': return const Color(0xFF8338EC);
    case 'kn': return const Color(0xFFF7B731);
    case 'bn': return const Color(0xFF3A86FF);
    case 'mr': return const Color(0xFFFB5607);
    case 'pa': return const Color(0xFF06D6A0);
    case 'gu': return const Color(0xFFFFB703);
    default: return const Color(0xFFC9A84C);
  }
}