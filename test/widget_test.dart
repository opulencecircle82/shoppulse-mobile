// WebViewScreen can't be widget-tested here: WebViewPlatform.instance is
// only registered on a real device/emulator, not in the plain widget-test
// environment. The technician flow itself (login, today's task,
// checklist, proof capture) lives on the website this wrapper loads, so
// it's covered by the web app's own checks — this just confirms the
// wrapper points at the right place.

import 'package:flutter_test/flutter_test.dart';
import 'package:shoppulse_mobile/config/app_config.dart';

void main() {
  test('AppConfig.techAppUrl defaults to the production tech app', () {
    expect(AppConfig.techAppUrl, 'https://shoppulse-web.vercel.app/tech');
  });
}
