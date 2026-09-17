/// Which published document the user asked to read.
enum LegalDocumentKind { privacy, terms }

/// What a line of a legal document is, once the markdown is read.
enum LegalBlockType { heading, paragraph, bullet }

/// One block of a legal document: a heading, a paragraph or a list item.
class LegalBlock {
  const LegalBlock.heading(this.text, {required this.level})
    : type = LegalBlockType.heading;
  const LegalBlock.paragraph(this.text)
    : type = LegalBlockType.paragraph,
      level = 0;
  const LegalBlock.bullet(this.text) : type = LegalBlockType.bullet, level = 0;

  final LegalBlockType type;
  final String text;

  /// Heading depth (1 for `#`); zero for anything else.
  final int level;

  @override
  bool operator ==(Object other) =>
      other is LegalBlock &&
      other.type == type &&
      other.text == text &&
      other.level == level;

  @override
  int get hashCode => Object.hash(type, text, level);

  @override
  String toString() => 'LegalBlock.${type.name}($level, "$text")';
}

/// A privacy policy or terms of use, read from the markdown that is
/// published at the repository root.
///
/// Only the handful of constructs those documents use are understood:
/// headings, bullets, paragraphs, bold and inline code. A markdown package
/// would render more and would be one more dependency to audit, for two
/// files the project writes itself.
class LegalDocument {
  const LegalDocument(this.blocks);

  factory LegalDocument.parse(String markdown) {
    final text = markdown.replaceAll(_comment, '\n');
    final blocks = <LegalBlock>[];
    final paragraph = <String>[];

    void flush() {
      if (paragraph.isEmpty) return;
      blocks.add(LegalBlock.paragraph(paragraph.join(' ')));
      paragraph.clear();
    }

    for (final raw in text.split('\n')) {
      final line = raw.trim();
      final heading = _heading.firstMatch(line);
      if (line.isEmpty) {
        flush();
      } else if (heading != null) {
        flush();
        blocks.add(
          LegalBlock.heading(
            _inline(heading.group(2)!),
            level: heading.group(1)!.length,
          ),
        );
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        flush();
        blocks.add(LegalBlock.bullet(_inline(line.substring(2))));
      } else {
        paragraph.add(_inline(line));
      }
    }
    flush();

    return LegalDocument(blocks);
  }

  static final _comment = RegExp(r'<!--.*?-->', dotAll: true);
  static final _heading = RegExp(r'^(#{1,6})\s+(.*)$');

  static String _inline(String text) =>
      text.replaceAll('**', '').replaceAll('`', '').trim();

  final List<LegalBlock> blocks;

  /// The first heading, used as the screen title.
  String? get title {
    for (final block in blocks) {
      if (block.type == LegalBlockType.heading) return block.text;
    }
    return null;
  }
}
