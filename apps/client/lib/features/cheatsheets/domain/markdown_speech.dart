String speechTextFromMarkdown(String markdown) {
  final lines = markdown.split('\n');
  final spoken = <String>[];
  var inCode = false;

  for (final rawLine in lines) {
    var line = rawLine.trim();
    if (line.startsWith('```')) {
      inCode = !inCode;
      continue;
    }
    if (inCode || line.isEmpty) continue;

    line = line
        .replaceFirst(RegExp(r'^#{1,6}\s+'), '')
        .replaceFirst(RegExp(r'^[-*+]\s+'), '')
        .replaceFirst(RegExp(r'^\d+\.\s+'), '')
        .replaceAllMapped(RegExp(r'`([^`]+)`'), (match) => match[1] ?? '')
        .replaceAllMapped(
          RegExp(r'!\[([^\]]*)\]\([^)]*\)'),
          (match) => match[1] ?? '',
        )
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]*\)'),
          (match) => match[1] ?? '',
        )
        .replaceAll(RegExp(r'[*_~>#]'), '')
        .trim();

    if (line.isNotEmpty) spoken.add(line);
  }

  return spoken.join('. ');
}
