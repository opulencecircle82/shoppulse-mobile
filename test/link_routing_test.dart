import 'package:flutter_test/flutter_test.dart';
import 'package:shoppulse_mobile/config/link_routing.dart';

void main() {
  const appHost = 'shoppulse-web.vercel.app';
  bool stays(String url) => linkStaysInApp(Uri.parse(url), appHost: appHost);

  test('the technician app and its own pages stay in the WebView', () {
    expect(stays('https://shoppulse-web.vercel.app/tech'), isTrue);
    expect(stays('https://shoppulse-web.vercel.app/customer/messages/abc'), isTrue);
    expect(stays('https://SHOPPULSE-WEB.vercel.app/tech'), isTrue);
  });

  test('the backend and Google sign-in may be passed through', () {
    expect(stays('https://ghbmcepnjrviinseiwqr.supabase.co/auth/v1/callback'), isTrue);
    expect(stays('https://accounts.google.com/o/oauth2/v2/auth'), isTrue);
  });

  test('Google Maps and other websites go to the phone, not the WebView', () {
    expect(stays('https://www.google.com/maps/dir/?api=1&destination=Singao%2C%20Kidapawan'), isFalse);
    expect(stays('https://maps.app.goo.gl/abc123'), isFalse);
    expect(stays('https://example.com/'), isFalse);
    // A look-alike must not pass for the app.
    expect(stays('https://shoppulse-web.vercel.app.evil.example/tech'), isFalse);
  });

  test('calls, texts, maps and app links go to the phone', () {
    expect(stays('tel:+639171234567'), isFalse);
    expect(stays('sms:+639171234567'), isFalse);
    expect(stays('geo:0,0?q=Singao'), isFalse);
    expect(stays('mailto:office@example.com'), isFalse);
    expect(stays('intent://maps.google.com/maps?daddr=Singao#Intent;scheme=https;package=com.google.android.apps.maps;end'), isFalse);
    expect(stays('comgooglemaps://?daddr=Singao'), isFalse);
  });

  test('blank and inline pages stay put', () {
    expect(stays('about:blank'), isTrue);
    expect(stays('data:text/html;base64,PGgxPmhpPC9oMT4='), isTrue);
    expect(stays('blob:https://shoppulse-web.vercel.app/1234'), isTrue);
  });
}
