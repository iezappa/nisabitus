import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../release_notes/presentation/release_notes_providers.dart';
import '../data/asset_legal_documents.dart';
import '../domain/legal_document.dart';

/// A legal document in one language.
final legalDocumentProvider = FutureProvider.autoDispose
    .family<LegalDocument, (LegalDocumentKind, String)>(
      (ref, key) =>
          AssetLegalDocuments(ref.watch(assetBundleProvider))
              .load(key.$1, key.$2),
    );
