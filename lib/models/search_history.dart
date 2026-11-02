/// Model untuk riwayat pencarian (local database)
class SearchHistory {
  final int? id;
  final String query;
  final int timestamp;
  final int resultCount;

  SearchHistory({
    this.id,
    required this.query,
    required this.timestamp,
    this.resultCount = 0,
  });

  factory SearchHistory.fromJson(Map<String, dynamic> json) {
    return SearchHistory(
      id: json['id'] as int?,
      query: json['query'] as String,
      timestamp: json['timestamp'] as int,
      resultCount: json['result_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'query': query,
      'timestamp': timestamp,
      'result_count': resultCount,
    };
  }

  @override
  String toString() =>
      'SearchHistory(id: $id, query: $query, results: $resultCount)';
}
