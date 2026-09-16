import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current moment, injectable so logic that ages — how long since the
/// last backup — can be tested at any distance without waiting for it.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
