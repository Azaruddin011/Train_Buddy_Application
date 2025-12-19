import 'package:flutter/material.dart';

/// Utility class for accessibility helpers
class AccessibilityUtils {
  /// Get appropriate font size based on system text scale factor
  static double getScaledFontSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return baseSize * textScaleFactor;
  }
  
  /// Get appropriate icon size based on system text scale factor
  static double getScaledIconSize(BuildContext context, double baseSize) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return baseSize * textScaleFactor;
  }
  
  /// Get appropriate padding based on system text scale factor
  static EdgeInsets getScaledPadding(BuildContext context, EdgeInsets basePadding) {
    final textScaleFactor = MediaQuery.of(context).textScaleFactor;
    return EdgeInsets.fromLTRB(
      basePadding.left * textScaleFactor,
      basePadding.top * textScaleFactor,
      basePadding.right * textScaleFactor,
      basePadding.bottom * textScaleFactor,
    );
  }
  
  /// Check if the device has large text enabled
  static bool hasLargeText(BuildContext context) {
    return MediaQuery.of(context).textScaleFactor > 1.3;
  }
  
  /// Check if the device has reduced motion enabled
  static bool hasReducedMotion(BuildContext context) {
    return MediaQuery.of(context).disableAnimations;
  }
  
  /// Check if the device has high contrast enabled
  static bool hasHighContrast(BuildContext context) {
    return MediaQuery.of(context).highContrast;
  }
  
  /// Get appropriate color based on high contrast setting
  static Color getAccessibleColor(BuildContext context, Color normalColor, Color highContrastColor) {
    return hasHighContrast(context) ? highContrastColor : normalColor;
  }
  
  /// Get appropriate duration for animations based on reduced motion setting
  static Duration getAccessibleAnimationDuration(BuildContext context, Duration normalDuration) {
    return hasReducedMotion(context) 
        ? const Duration(milliseconds: 0) 
        : normalDuration;
  }
  
  /// Get appropriate curve for animations based on reduced motion setting
  static Curve getAccessibleAnimationCurve(BuildContext context, Curve normalCurve) {
    return hasReducedMotion(context) 
        ? Curves.linear
        : normalCurve;
  }
  
  /// Create semantic label for a card or button
  static String createSemanticLabel({
    required String title,
    String? description,
    String? action,
  }) {
    String label = title;
    
    if (description != null && description.isNotEmpty) {
      label += ', $description';
    }
    
    if (action != null && action.isNotEmpty) {
      label += '. $action';
    }
    
    return label;
  }
}
