import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DOMAIN – Recommendation Entities
// ─────────────────────────────────────────────────────────────────────────────
class RoutineStep extends Equatable {
  final String step;
  final String product;
  final String instruction;
  final String icon;

  const RoutineStep({
    required this.step,
    required this.product,
    required this.instruction,
    required this.icon,
  });

  factory RoutineStep.fromJson(Map<String, dynamic> j) => RoutineStep(
    step       : j['step']        as String,
    product    : j['product']     as String,
    instruction: j['instruction'] as String,
    icon       : j['icon']        as String,
  );

  Map<String, dynamic> toJson() =>
      {'step': step, 'product': product, 'instruction': instruction, 'icon': icon};

  @override
  List<Object?> get props => [step, product];
}

class RecommendationResult extends Equatable {
  final String id;
  final String detectionId;
  final List<RoutineStep> morningRoutine;
  final List<RoutineStep> eveningRoutine;
  final List<String> dietTips;
  final String duration;
  final DateTime createdAt;

  const RecommendationResult({
    required this.id,
    required this.detectionId,
    required this.morningRoutine,
    required this.eveningRoutine,
    required this.dietTips,
    required this.duration,
    required this.createdAt,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> j) => RecommendationResult(
    id            : j['id']          as String,
    detectionId   : j['detectionId'] as String,
    morningRoutine: (j['morningRoutine'] as List).map((s) => RoutineStep.fromJson(s as Map<String, dynamic>)).toList(),
    eveningRoutine: (j['eveningRoutine'] as List).map((s) => RoutineStep.fromJson(s as Map<String, dynamic>)).toList(),
    dietTips      : List<String>.from(j['dietTips']),
    duration      : j['duration'] as String,
    createdAt     : DateTime.parse(j['createdAt'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'detectionId': detectionId,
    'morningRoutine': morningRoutine.map((s) => s.toJson()).toList(),
    'eveningRoutine': eveningRoutine.map((s) => s.toJson()).toList(),
    'dietTips': dietTips,
    'duration': duration,
    'createdAt': createdAt.toIso8601String(),
  };

  @override
  List<Object?> get props => [id];
}
