// The driver half of a web integration run.
//
// `flutter test integration_test -d linux` needs nothing of the sort: on a
// native platform the test and the app share a process. On the web they do
// not — the app runs in a browser and the test drives it over WebDriver — so
// this file is what `flutter drive` runs on its side of the wire.
//
// See `tool/test_web.sh` for the whole invocation, chromedriver included.
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
