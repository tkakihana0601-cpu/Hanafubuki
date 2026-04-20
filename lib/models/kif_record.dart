class KifRecord {
  final String id;
  final String title;
  final String instructorName;
  final DateTime date;
  final List<String> tags;
  final String kif;
  final bool isCloudSynced;
  final String? shareUrl;

  const KifRecord({
    required this.id,
    required this.title,
    required this.instructorName,
    required this.date,
    required this.tags,
    required this.kif,
    required this.isCloudSynced,
    required this.shareUrl,
  });

  KifRecord copyWith({
    String? title,
    String? instructorName,
    DateTime? date,
    List<String>? tags,
    String? kif,
    bool? isCloudSynced,
    String? shareUrl,
  }) {
    return KifRecord(
      id: id,
      title: title ?? this.title,
      instructorName: instructorName ?? this.instructorName,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      kif: kif ?? this.kif,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
      shareUrl: shareUrl ?? this.shareUrl,
    );
  }
}
