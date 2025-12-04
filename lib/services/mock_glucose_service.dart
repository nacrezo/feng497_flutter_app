import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class GlucoseReading {
  final DateTime timestamp;
  final double value;
  final bool isPrediction;

  GlucoseReading({
    required this.timestamp,
    required this.value,
    this.isPrediction = false,
  });
}

final glucoseProvider = StreamProvider<List<GlucoseReading>>((ref) async* {
  final random = Random();
  double currentValue = 110.0;
  
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    
    // Simulate slight fluctuations
    currentValue += (random.nextDouble() - 0.5) * 5;
    if (currentValue < 70) currentValue = 70;
    if (currentValue > 250) currentValue = 250;

    final now = DateTime.now();
    final history = List.generate(20, (index) {
      return GlucoseReading(
        timestamp: now.subtract(Duration(minutes: (20 - index) * 5)),
        value: currentValue + sin(index) * 10, // Fake wave
      );
    });

    // Add predictions
    final predictions = List.generate(5, (index) {
      return GlucoseReading(
        timestamp: now.add(Duration(minutes: (index + 1) * 5)),
        value: currentValue + (index * 2), // Slight upward trend prediction
        isPrediction: true,
      );
    });

    yield [...history, ...predictions];
  }
});
