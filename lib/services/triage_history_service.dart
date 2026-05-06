import 'package:flutter/foundation.dart';

class TriageHistoryItem {
  final DateTime createdAt;
  final int probability;
  final String condition;
  final String specialist;
  final String location;

  const TriageHistoryItem({
    required this.createdAt,
    required this.probability,
    required this.condition,
    required this.specialist,
    required this.location,
  });
}

class TriageHistoryService {
  TriageHistoryService._();
  static final TriageHistoryService instance = TriageHistoryService._();

  final ValueNotifier<List<TriageHistoryItem>> history =
      ValueNotifier<List<TriageHistoryItem>>([]);

  void add(TriageHistoryItem item) {
    history.value = [item, ...history.value].take(20).toList();
  }
}
