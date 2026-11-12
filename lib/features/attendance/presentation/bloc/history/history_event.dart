import 'package:equatable/equatable.dart';

abstract class HistoryEvent extends Equatable {
  const HistoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadHistory extends HistoryEvent {
  const LoadHistory();
}

class RefreshHistory extends HistoryEvent {
  const RefreshHistory();
}

class HistoryFilterChanged extends HistoryEvent {
  final DateTime? date;

  const HistoryFilterChanged({this.date});

  @override
  List<Object?> get props => [date];
}
