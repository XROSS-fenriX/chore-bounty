import 'package:flutter/material.dart';

class RpgTheme {
  // Guild RPG Palette
  static const Color primaryGreen = Color(0xFF1E8E4E);
  static const Color boardBackground = Color(0xFF14141E);
  static const Color cardSurface = Color(0xFF1F1F2E);
  static const Color cardSurfaceLight = Color(0xFF2A2A3D);
  static const Color parchmentGold = Color(0xFFFFD166);
  static const Color legendaryPurple = Color(0xFFA855F7);
  static const Color epicOrange = Color(0xFFFF7A00);
  static const Color emeraldVictory = Color(0xFF10B981);
  static const Color crimsonAlert = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF9CA3AF);

  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'epic':
        return legendaryPurple;
      case 'hard':
        return crimsonAlert;
      case 'medium':
      case 'moderate':
        return epicOrange;
      case 'easy':
      default:
        return emeraldVictory;
    }
  }

  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return emeraldVictory;
      case 'submitted':
        return parchmentGold;
      case 'claimed':
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'cancelled':
        return Colors.grey;
      case 'open':
      case 'available':
      default:
        return primaryGreen;
    }
  }

  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return 'Completed';
      case 'submitted':
        return 'Pending Review';
      case 'claimed':
      case 'in_progress':
        return 'In Progress';
      case 'cancelled':
        return 'Cancelled';
      case 'open':
      case 'available':
      default:
        return 'Available';
    }
  }
}
