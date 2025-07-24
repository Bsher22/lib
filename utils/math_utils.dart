// lib/utils/math_utils.dart
import 'package:flutter/material.dart';

/// Linear regression calculation helper
/// Used by visualization components to calculate trend lines
class LinearRegression {
  /// The slope of the regression line
  final double? slope;
  
  /// The y-intercept of the regression line
  final double? intercept;
  
  /// The coefficient of determination (R²)
  final double? rSquared;
  
  /// Creates a linear regression object with pre-calculated values
  const LinearRegression({
    this.slope,
    this.intercept,
    this.rSquared,
  });
  
  /// Creates a linear regression from x and y data points
  factory LinearRegression.calculate(List<double> xValues, List<double> yValues) {
    if (xValues.length != yValues.length || xValues.isEmpty) {
      return const LinearRegression();
    }
    
    int n = xValues.length;
    
    // Calculate means
    double sumX = 0;
    double sumY = 0;
    
    for (int i = 0; i < n; i++) {
      sumX += xValues[i];
      sumY += yValues[i];
    }
    
    double meanX = sumX / n;
    double meanY = sumY / n;
    
    // Calculate slope
    double numerator = 0;
    double denominator = 0;
    
    for (int i = 0; i < n; i++) {
      numerator += (xValues[i] - meanX) * (yValues[i] - meanY);
      denominator += (xValues[i] - meanX) * (xValues[i] - meanX);
    }
    
    if (denominator == 0) {
      return const LinearRegression();
    }
    
    final slope = numerator / denominator;
    final intercept = meanY - slope * meanX;
    
    // Calculate R-squared
    double totalSumSquares = 0;
    double residualSumSquares = 0;
    
    for (int i = 0; i < n; i++) {
      double predictedY = slope * xValues[i] + intercept;
      totalSumSquares += (yValues[i] - meanY) * (yValues[i] - meanY);
      residualSumSquares += (yValues[i] - predictedY) * (yValues[i] - predictedY);
    }
    
    double? rSquared;
    if (totalSumSquares != 0) {
      rSquared = 1 - (residualSumSquares / totalSumSquares);
    }
    
    return LinearRegression(
      slope: slope,
      intercept: intercept,
      rSquared: rSquared,
    );
  }
  
  /// Predicts a y value for a given x using the regression equation
  double? predict(double x) {
    if (slope == null || intercept == null) {
      return null;
    }
    return slope! * x + intercept!;
  }
  
  /// Returns whether this regression has valid coefficients
  bool get isValid => slope != null && intercept != null;
  
  @override
  String toString() => 'LinearRegression(slope: $slope, intercept: $intercept, r²: $rSquared)';
}