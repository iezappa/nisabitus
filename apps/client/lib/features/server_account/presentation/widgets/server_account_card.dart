import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../backup/presentation/backup_feedback.dart';
import '../../../backup/presentation/backup_providers.dart';
import '../server_account_providers.dart';

class ServerAccountCard extends ConsumerStatefulWidget {
  const ServerAccountCard({super.key});

  @override
  ConsumerState<ServerAccountCard> createState() => _ServerAccountCardState();
}

class _ServerAccountCardState extends ConsumerState<ServerAccountCard> {
  late final TextEditingController _urlController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    final account = ref.read(serverAccountProvider);
    _urlController = TextEditingController(text: account.baseUrl);
    _usernameController = TextEditingController(text: account.username);
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await action();
    } on Object catch (error) {
      if (mounted) setState(() => _message = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() => _run(() async {
    await ref
        .read(serverAccountActionsProvider)
        .connect(
          baseUrl: _urlController.text,
          username: _usernameController.text,
          password: _passwordController.text,
        );
    _passwordController.clear();
    if (mounted) {
      setState(() => _message = AppLocalizations.of(context).serverConnected);
    }
  });

  Future<void> _disconnect() => _run(() async {
    await ref.read(serverAccountActionsProvider).disconnect();
    if (mounted) {
      setState(
        () => _message = AppLocalizations.of(context).serverDisconnected,
      );
    }
  });

  Future<void> _upload() async {
    await _runBackup(
      ref.read(serverAccountActionsProvider).uploadLocalBackup,
      (l10n, rows) => l10n.serverUploaded(rows),
    );
  }

  Future<void> _download() async {
    if (!await _confirmReplace()) return;
    await _runBackup(
      ref.read(serverAccountActionsProvider).downloadServerBackup,
      (l10n, rows) => l10n.serverDownloaded(rows),
    );
  }

  Future<void> _runBackup(
    Future<BackupOutcome> Function() action,
    String Function(AppLocalizations l10n, int rows) succeeded,
  ) async {
    setState(() => _busy = true);
    try {
      final outcome = await action();
      if (!mounted) return;
      showBackupOutcome(context, outcome, succeeded: succeeded);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirmReplace() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.backupConfirmTitle),
        content: Text(l10n.serverDownloadConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.backupConfirmAction),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final account = ref.watch(serverAccountProvider);
    final connected = account.isConnected;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: EdgeInsets.zero,
      leading: Icon(
        connected ? Icons.cloud_done_outlined : Icons.cloud_sync_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(l10n.serverAccountTitle),
      subtitle: Text(
        connected
            ? l10n.serverConnectedAs(account.username, account.baseUrl)
            : l10n.serverAccountHint,
      ),
      children: [
        if (_message != null) ...[
          const SizedBox(height: Gap.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(_message!, style: theme.textTheme.bodySmall),
          ),
        ],
        const SizedBox(height: Gap.md),
        TextField(
          controller: _urlController,
          enabled: !_busy,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(labelText: l10n.serverUrl),
        ),
        const SizedBox(height: Gap.sm),
        TextField(
          controller: _usernameController,
          enabled: !_busy,
          decoration: InputDecoration(labelText: l10n.serverUsername),
        ),
        const SizedBox(height: Gap.sm),
        TextField(
          controller: _passwordController,
          enabled: !_busy,
          obscureText: true,
          decoration: InputDecoration(labelText: l10n.serverPassword),
        ),
        const SizedBox(height: Gap.md),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _busy ? null : _connect,
                icon: const Icon(Icons.login_outlined),
                label: Text(
                  connected ? l10n.serverReconnect : l10n.serverConnect,
                ),
              ),
            ),
            if (connected) ...[
              const SizedBox(width: Gap.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _disconnect,
                  icon: const Icon(Icons.logout_outlined),
                  label: Text(l10n.serverDisconnect),
                ),
              ),
            ],
          ],
        ),
        if (connected) ...[
          const SizedBox(height: Gap.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              l10n.serverManualSyncHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: Gap.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _upload,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text(l10n.serverUpload),
                ),
              ),
              const SizedBox(width: Gap.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _busy ? null : _download,
                  icon: const Icon(Icons.cloud_download_outlined),
                  label: Text(l10n.serverDownload),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
