import 'package:integration_test/integration_test_driver.dart';

// Enables `flutter drive --release` for integration_test/*.dart -- this is
// the only way to run an integration test in release mode on a real device
// (`flutter test integration_test/*.dart` doesn't support --release), which
// matters here specifically because the Android R8/ProGuard ONNX Runtime
// crash only reproduces in a release build.
Future<void> main() => integrationDriver();
