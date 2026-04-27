import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Prediction Entities
// ─────────────────────────────────────────────────────────────────────────────
enum RiskLevel { low, medium, high }
enum TrendDirection { increasing, stable, decreasing }

class PredictionResult extends Equatable {
  final String id;
  final double riskScore;           // 0.0 → 1.0
  final RiskLevel riskLevel;
  final TrendDirection trend;
  final List<String> factors;
  final List<String> preventionTips;
  final DateTime predictedAt;

  const PredictionResult({
    required this.id,
    required this.riskScore,
    required this.riskLevel,
    required this.trend,
    required this.factors,
    required this.preventionTips,
    required this.predictedAt,
  });

  factory PredictionResult.fromJson(Map<String, dynamic> j) => PredictionResult(
    id            : j['id']       as String,
    riskScore     : (j['riskScore'] as num).toDouble(),
    riskLevel     : RiskLevel.values.firstWhere((e) => e.name == j['riskLevel']),
    trend         : TrendDirection.values.firstWhere((e) => e.name == j['trend']),
    factors       : List<String>.from(j['factors']),
    preventionTips: List<String>.from(j['preventionTips']),
    predictedAt   : DateTime.parse(j['predictedAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'riskScore': riskScore,
    'riskLevel': riskLevel.name,
    'trend': trend.name,
    'factors': factors,
    'preventionTips': preventionTips,
    'predictedAt': predictedAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id, riskScore];
}
