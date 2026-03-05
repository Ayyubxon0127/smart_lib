import 'package:flutter/material.dart';

class AppColors {
  static const accent     = Color(0xFFE8A045);
  static const accentLight= Color(0xFFF0B865);
  static const blue       = Color(0xFF4A9EFF);
  static const green      = Color(0xFF4CAF82);
  static const red        = Color(0xFFEF5350);
  static const purple     = Color(0xFF9C6FDE);
  static const teal       = Color(0xFF26C6DA);
  static const orange     = Color(0xFFFF7043);

  // Dark theme
  static const darkBg     = Color(0xFF0F1923);
  static const darkSurface= Color(0xFF162032);
  static const darkCard   = Color(0xFF1A2637);
  static const darkBorder = Color(0xFF243347);

  // Light theme
  static const lightBg    = Color(0xFFF4F6FA);
  static const lightCard  = Colors.white;
}

const List<String> kFacultyNames = [
  'Kompyuter injiniringi fakulteti',
  'Dasturiy injiniring fakulteti',
  'Telekommunikatsiya texnologiyalari fakulteti',
  'Axborot xavfsizligi fakulteti',
  'Televizion texnologiyalar fakulteti',
];

const Map<String, List<String>> kFacultyDirections = {
  'Kompyuter injiniringi fakulteti':           ['Kompyuter injiniringi', 'AT-servis'],
  'Dasturiy injiniring fakulteti':             ['Dasturiy injiniring', 'Web va mobil dasturlash'],
  'Telekommunikatsiya texnologiyalari fakulteti': ['Telekommunikatsiya', 'Mobil aloqa', 'Teleradioeshittirish'],
  'Axborot xavfsizligi fakulteti':             ['Axborot xavfsizligi'],
  'Televizion texnologiyalar fakulteti':       ['Teleradioeshittirish', 'Multimedia'],
};

const List<String> kMagistrDirections = [
  'Kompyuter injiniringi',
  'Dasturiy injiniring',
  'Axborot xavfsizligi',
  'Telekommunikatsiya texnologiyalari',
  'Radioelektron qurilmalar va tizimlar',
  'Televizion texnologiyalar',
  "Sun'iy intellekt",
  "Ma'lumotlar ilmi (Data Science)",
  'Axborot tizimlari va texnologiyalari',
  'Raqamli iqtisodiyot',
  'Elektron tijorat',
  "IT-ta'lim texnologiyalari",
];

const List<String> kBookCategories = [
  'Adabiyot', 'Texnologiya', 'Fan', 'Psixologiya',
  'Iqtisod', 'Til', 'Tarix', "San'at", 'Tibbiyot',
];
