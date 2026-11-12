import 'package:equatable/equatable.dart';

/// Pure Dart entity representing high-level attendance KPI counts.
class DashboardSummary extends Equatable {
  final int totalEmployees;
  final int presentToday;
  final int checkedOutToday;

  const DashboardSummary({
    required this.totalEmployees,
    required this.presentToday,
    required this.checkedOutToday,
  });

  int get absentToday {
    final absent = totalEmployees - (presentToday + checkedOutToday);
    return absent > 0 ? absent : 0;
  }

  @override
  List<Object?> get props => [totalEmployees, presentToday, checkedOutToday];
}
