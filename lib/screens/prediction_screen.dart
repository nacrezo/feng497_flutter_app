import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import '../services/mock_glucose_service.dart';

class PredictionScreen extends ConsumerWidget {
  const PredictionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glucoseAsync = ref.watch(glucoseProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Glucose Prediction', style: GoogleFonts.outfit()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: glucoseAsync.when(
        data: (readings) {
          final current = readings.where((r) => !r.isPrediction).last;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildCurrentValueIndicator(current),
                const SizedBox(height: 30),
                Expanded(child: _buildChart(readings)),
                const SizedBox(height: 20),
                _buildPredictionCard(readings),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildCurrentValueIndicator(GlucoseReading current) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5), width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              current.value.toStringAsFixed(0),
              style: GoogleFonts.outfit(
                fontSize: 60,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'mg/dL',
              style: GoogleFonts.outfit(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<GlucoseReading> readings) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      blur: 10,
      border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: false),
            titlesData: const FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              // Historical Data
              LineChartBarData(
                spots: readings
                    .where((r) => !r.isPrediction)
                    .map((r) => FlSpot(
                          r.timestamp.millisecondsSinceEpoch.toDouble(),
                          r.value,
                        ))
                    .toList(),
                isCurved: true,
                color: Colors.cyanAccent,
                barWidth: 3,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: Colors.cyanAccent.withOpacity(0.1),
                ),
              ),
              // Prediction Data
              LineChartBarData(
                spots: readings
                    .where((r) => r.isPrediction || r == readings.where((e) => !e.isPrediction).last)
                    .map((r) => FlSpot(
                          r.timestamp.millisecondsSinceEpoch.toDouble(),
                          r.value,
                        ))
                    .toList(),
                isCurved: true,
                color: Colors.purpleAccent,
                barWidth: 3,
                dashArray: [5, 5], // Dashed line for prediction
                dotData: const FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPredictionCard(List<GlucoseReading> readings) {
    final predicted = readings.last.value;
    return GlassContainer(
      height: 100,
      width: double.infinity,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.purpleAccent, size: 30),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'AI Prediction (30 min)',
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${predicted.toStringAsFixed(0)} mg/dL',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
