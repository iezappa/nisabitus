// A release that is built without running the tests is a release nobody
// checked. `ci.yml` runs format, analysis and tests on every push and pull
// request, but a tag goes straight to `release.yml`, and a tag is exactly the
// commit that reaches users — including a tag pushed from a branch CI never
// saw, or one pushed while CI was still red.
//
// This test reads the workflow rather than trusting it: a build job added
// later without the gate fails here, in the suite the author is already
// running.
@TestOn('vm')
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  late YamlMap workflow;

  setUpAll(() {
    final file = File('../../.github/workflows/release.yml');
    expect(file.existsSync(), isTrue, reason: 'run from apps/client');
    workflow = loadYaml(file.readAsStringSync()) as YamlMap;
  });

  /// Everything the job named [name] needs, directly or through the jobs it
  /// needs — a gate reached through `release` counts as reached.
  Set<String> gatesOf(String name) {
    final jobs = workflow['jobs'] as YamlMap;
    final needs = jobs[name]?['needs'];
    final direct = <String>[
      if (needs is String) needs,
      if (needs is YamlList) ...needs.cast<String>(),
    ];
    return {
      for (final n in direct) ...[n, ...gatesOf(n)],
    };
  }

  test('every job that builds or publishes waits for the checks', () {
    final jobs = (workflow['jobs'] as YamlMap).keys.cast<String>();
    final gates = {'version-check', 'check'};

    for (final job in jobs.where((j) => !gates.contains(j))) {
      expect(
        gatesOf(job),
        containsAll(gates),
        reason: '$job runs before the release is checked',
      );
    }
  });

  test('the checks are the same ones CI runs', () {
    final steps = (workflow['jobs']['check']['steps'] as YamlList)
        .map((step) => '${(step as YamlMap)['run'] ?? ''}')
        .join('\n');

    expect(steps, contains('dart format'));
    expect(steps, contains('--set-exit-if-changed'));
    expect(steps, contains('analyze'));
    expect(steps, contains('flutter test'));
  });
}
