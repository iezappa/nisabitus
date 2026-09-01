import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Opens a link outside the app. Injectable so the flow can be tested
/// without touching the platform channel.
typedef UrlOpener = Future<bool> Function(Uri url);

Future<bool> _launchExternally(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Voluntary support links.
///
/// Both platforms are always shown side by side and the user chooses. An
/// offline-first app must not open a connection just to guess a country, so
/// there is no geolocation here on purpose.
class SupportProjectsCard extends StatelessWidget {
  const SupportProjectsCard({
    this.opener = _launchExternally,
    this.compact = false,
    super.key,
  });

  final UrlOpener opener;

  /// Drops the surrounding card, for use inside the tutorial.
  final bool compact;

  static final cafecito = Uri.parse('https://cafecito.app/iezappa');
  static final patreon = Uri.parse('https://patreon.com/cw/iezappa');

  Future<void> _open(BuildContext context, Uri url) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);

    var ok = false;
    try {
      ok = await opener(url);
    } catch (_) {
      ok = false;
    }

    // Fail quietly and recoverably: no retries, no blocking dialog.
    if (!ok) {
      messenger?.showSnackBar(SnackBar(content: Text(l10n.supportLinkFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final body = Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The heading only belongs to the compact copy. In settings the
        // section label above already names the block, and printing both
        // would announce it twice.
        if (compact) ...[
          Text(
            l10n.supportTitle.toUpperCase(),
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: Gap.sm),
        ],
        Text(
          l10n.supportBody,
          style: theme.textTheme.bodyMedium,
          textAlign: compact ? TextAlign.center : TextAlign.start,
        ),
        const SizedBox(height: Gap.lg),
        // Both platforms get the identical treatment: the user picks by
        // country, not by which button looks more like the real one.
        Row(
          children: [
            Expanded(
              child: _SupportButton(
                icon: Icons.local_cafe_outlined,
                label: l10n.supportCafecito,
                onPressed: () => _open(context, cafecito),
              ),
            ),
            const SizedBox(width: Gap.md),
            Expanded(
              child: _SupportButton(
                icon: Icons.favorite_outline,
                label: l10n.supportPatreon,
                onPressed: () => _open(context, patreon),
              ),
            ),
          ],
        ),
      ],
    );

    if (compact) return body;

    return Card(
      child: Padding(padding: const EdgeInsets.all(Gap.lg), child: body),
    );
  }
}

/// One of the two support buttons. They are deliberately indistinguishable
/// apart from their label.
class _SupportButton extends StatelessWidget {
  const _SupportButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 18),
    label: Text(label, overflow: TextOverflow.ellipsis),
  );
}
