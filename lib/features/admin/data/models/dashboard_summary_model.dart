import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel extends DashboardSummary {
  const DashboardSummaryModel({
    required super.totalEmployees,
    required super.presentToday,
    required super.checkedOutToday,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
      presentToday: (json['presentToday'] as num?)?.toInt() ?? 0,
      checkedOutToday: (json['checkedOutToday'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalEmployees': totalEmployees,
      'presentToday': presentToday,
      'checkedOutToday': checkedOutToday,
    };
  }
}
