import 'package:flutter/material.dart';

class CategoryStyle {
  const CategoryStyle(this.label, this.icon, this.fg, this.bg);
  final String label;
  final IconData icon;
  final Color fg, bg;
}

const Map<String, CategoryStyle> kCategoryStyles = {
  'plumber': CategoryStyle('Plumber', Icons.plumbing_rounded, Color(0xFF11768F), Color(0xFFDCEBFA)),
  'electrician': CategoryStyle('Electrician', Icons.bolt_rounded, Color(0xFFB45309), Color(0xFFFFE7C7)),
  'cleaner': CategoryStyle('Cleaner', Icons.cleaning_services_rounded, Color(0xFF0369A1), Color(0xFFD3EEFB)),
  'carpenter': CategoryStyle('Carpenter', Icons.carpenter_rounded, Color(0xFF0E7490), Color(0xFFCFF3FA)),
  'painter': CategoryStyle('Painter', Icons.format_paint_rounded, Color(0xFF4338CA), Color(0xFFE0E4FB)),
  'appliance': CategoryStyle('Appliance Repair', Icons.home_repair_service_rounded, Color(0xFFB45309), Color(0xFFFFE7C7)),
  'other': CategoryStyle('Other', Icons.handyman_rounded, Color(0xFF475569), Color(0xFFE5E7EB)),
};

CategoryStyle categoryStyle(String key) =>
    kCategoryStyles[key] ?? kCategoryStyles['other']!;
