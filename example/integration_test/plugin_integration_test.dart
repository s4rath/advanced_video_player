import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('setSecure channel test', (WidgetTester tester) async {
    const channel = MethodChannel('advanced_video_player');
    // Verify that calling setSecure via method channel executes successfully
    await expectLater(
      channel.invokeMethod('setSecure', true),
      completes,
    );
  });
}
