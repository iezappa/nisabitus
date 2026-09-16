import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Starts the app over from a clean provider tree.
///
/// Wiping or replacing the whole store leaves every provider holding state
/// read from a store that no longer exists — cached rows, preferences read at
/// startup, a database connection that failed to open. Invalidating each one
/// by hand is a list that goes stale the day a module is added; throwing the
/// whole scope away cannot.
final restartAppProvider = Provider<VoidCallback>(
  (ref) => throw UnimplementedError(
    'restartAppProvider must be overridden by AppRestartScope',
  ),
);

/// Owns the [ProviderScope], so it can replace it.
class AppRestartScope extends StatefulWidget {
  const AppRestartScope({
    required this.overrides,
    required this.child,
    super.key,
  });

  final List<Override> overrides;
  final Widget child;

  @override
  State<AppRestartScope> createState() => _AppRestartScopeState();
}

class _AppRestartScopeState extends State<AppRestartScope> {
  Key _generation = UniqueKey();

  void _restart() {
    if (mounted) setState(() => _generation = UniqueKey());
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
    // A new key disposes the old container — closing the database with it —
    // and builds every provider again from nothing.
    key: _generation,
    overrides: [
      ...widget.overrides,
      restartAppProvider.overrideWithValue(_restart),
    ],
    child: widget.child,
  );
}
