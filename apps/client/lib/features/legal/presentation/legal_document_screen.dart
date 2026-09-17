import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/centered_content.dart';
import '../domain/legal_document.dart';
import 'legal_providers.dart';

/// Shows a bundled legal document, readable without a connection.
class LegalDocumentScreen extends ConsumerWidget {
  const LegalDocumentScreen({
    required this.kind,
    required this.title,
    super.key,
  });

  final LegalDocumentKind kind;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = Localizations.localeOf(context).languageCode;
    final document = ref.watch(legalDocumentProvider((kind, language)));
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: CenteredContent(
          child: document.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (document) => SelectionArea(
              child: ListView(
                padding: const EdgeInsets.all(Gap.lg),
                children: [
                  for (final block in document.blocks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Gap.sm),
                      child: switch (block.type) {
                        LegalBlockType.heading => Padding(
                          padding: const EdgeInsets.only(top: Gap.md),
                          child: Text(
                            block.text,
                            style: block.level == 1
                                ? theme.textTheme.headlineSmall
                                : theme.textTheme.titleMedium,
                          ),
                        ),
                        LegalBlockType.bullet => Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('•  '),
                            Expanded(child: Text(block.text)),
                          ],
                        ),
                        LegalBlockType.paragraph => Text(block.text),
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
