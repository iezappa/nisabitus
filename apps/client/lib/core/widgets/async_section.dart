import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';

/// Renders the three states of an [AsyncValue] the same way everywhere.
///
/// Extracted after the sixth identical spinner-or-red-text block: a screen
/// that invents its own loading state makes the app feel like six apps.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({required this.value, required this.builder, super.key});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const Padding(
      padding: EdgeInsets.all(Gap.xxl),
      child: Center(child: CircularProgressIndicator()),
    ),
    error: (error, _) => Padding(
      padding: const EdgeInsets.all(Gap.lg),
      child: Text(
        '$error',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
    data: builder,
  );
}
