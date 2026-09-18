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

  // A `uses: owner/action@v4` resolves whatever the v4 tag points at on the
  // day the workflow runs, and a tag is mutable: whoever controls the action
  // repository — or anyone who takes that account over — can move it onto new
  // code, which then runs here with the token that writes releases and pushes
  // to GHCR. A commit SHA cannot be moved. The version stays in a trailing
  // comment so the pin is still readable and Dependabot can still bump it.
  test('every action is pinned to a commit SHA', () {
    final dir = Directory('../../.github/workflows');
    expect(dir.existsSync(), isTrue, reason: 'run from apps/client');

    final files = dir.listSync().whereType<File>().where(
      (f) => f.path.endsWith('.yml') || f.path.endsWith('.yaml'),
    );
    expect(files, isNotEmpty);

    // `uses: owner/repo@ref` or `owner/repo/path@ref`. A `./local` action is
    // this repository's own commit and `docker://` has no tag to move, so
    // neither is a supply-chain hop; both are left alone.
    final uses = RegExp(r'uses:\s*([^\s#]+)');
    final pinned = RegExp(r'^[^./][^@]*@[0-9a-f]{40}$');
    final unpinned = <String>[];

    for (final file in files) {
      for (final line in file.readAsLinesSync()) {
        final ref = uses.firstMatch(line)?.group(1);
        if (ref == null) continue;
        if (ref.startsWith('./') || ref.startsWith('docker://')) continue;
        if (!pinned.hasMatch(ref)) {
          unpinned.add('${file.uri.pathSegments.last}: $ref');
        }
      }
    }

    expect(
      unpinned,
      isEmpty,
      reason: 'pin these to a full commit SHA with a trailing # vX.Y.Z',
    );
  });
}
