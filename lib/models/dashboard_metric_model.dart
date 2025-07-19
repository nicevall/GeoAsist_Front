// lib/models/dashboard_metric_model.dart
class DashboardMetric {
  final String id;
  final String metric;
  final num value;
  final DateTime createdAt;
  final DateTime updatedAt;

  DashboardMetric({
    required this.id,
    required this.metric,
    required this.value,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DashboardMetric.fromJson(Map<String, dynamic> json) {
    return DashboardMetric(
      id: json['_id'] ?? '',
      metric: json['metric'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metric': metric,
      'value': value,
    };
  }
}
