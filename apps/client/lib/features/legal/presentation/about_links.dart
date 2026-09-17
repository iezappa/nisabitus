import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../shared/support_actions.dart';
import '../domain/legal_document.dart';
import 'legal_document_screen.dart';

Future<bool> _launchExternally(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// The About rows the compliance checklist asks for: privacy policy, terms,
/// who made the app and how to reach them, and the open source licenses.
///
/// The policy and the terms are bundled and rendered in the app, so they can
/// be read offline; only contacting the developer needs a connection.
class AboutLinks extends StatelessWidget {
  const AboutLinks({this.opener = _launchExternally, super.key});

  final UrlOpener opener;

  static const developerName = 'Zeke Zappa Developments (iezappa)';
  static final contactUrl = Uri.parse(
    'https://github.com/iezappa/nisabitus/issues',
  );

  void _openDocument(
    BuildContext context,
    LegalDocumentKind kind,
    String title,
  ) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => LegalDocumentScreen(kind: kind, title: title),
    ),
  );

  Future<void> _contact(BuildContext context) async {
    final message = AppLocalizations.of(context).supportLinkFailed;
    final messenger = ScaffoldMessenger.maybeOf(context);
    var ok = false;
    try {
      ok = await opener(contactUrl);
    } catch (_) {
      ok = false;
    }
    if (!ok) messenger?.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text(l10n.privacyPolicy),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _openDocument(
            context,
            LegalDocumentKind.privacy,
            l10n.privacyPolicy,
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l10n.termsOfUse),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              _openDocument(context, LegalDocumentKind.terms, l10n.termsOfUse),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.mail_outline),
          title: Text(l10n.developerContact),
          subtitle: Text(l10n.developerContactBody(developerName)),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _contact(context),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.description_outlined),
          title: Text(l10n.openSourceLicenses),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'Nisabitus',
            applicationLegalese: developerName,
          ),
        ),
      ],
    );
  }
}
