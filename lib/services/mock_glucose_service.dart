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

final emergencyAckProvider = StateProvider<bool>((ref) => false);

final glucoseProvider = StreamProvider<List<GlucoseReading>>((ref) async* {
  final random = Random();
  double currentValue = 110.0;
  
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    
    // Force rapid drop for testing
    double change = -10.0; 
    
    // 5% chance to start a trend
    if (random.nextDouble() < 0.05) {
       change += (random.nextDouble() - 0.5) * 20; 
    }

    currentValue += change;
    
    // Allow critical values for testing (Hypo < 70, Hyper > 250)
    // Constrain to "survivable" but critical limits
    if (currentValue < 40) currentValue = 40;
    if (currentValue > 400) currentValue = 400;

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
