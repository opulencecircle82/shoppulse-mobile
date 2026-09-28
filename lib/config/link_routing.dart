/// Which links belong inside the technician app's WebView and which belong to
/// another app on the phone (Google Maps, the dialer, messages...).
///
/// Left inside the WebView, a link like `tel:0917...` or a Google Maps address
/// either loads a page nobody asked for or fails with net::ERR_UNKNOWN_URL_SCHEME —
/// which used to replace the whole app with "Could not load ShopPulse" when a
/// technician tapped "I'm On My Way".
bool linkStaysInApp(Uri uri, {required String appHost}) {
  final scheme = uri.scheme.toLowerCase();

  // Not real destinations: blank pages, inline content, scripts.
  const inPageSchemes = {'about', 'data', 'blob', 'javascript', 'file'};
  if (inPageSchemes.contains(scheme)) return true;

  if (scheme == 'http' || scheme == 'https') {
    final host = uri.host.toLowerCase();
    // The app itself, plus the backend and Google sign-in it may redirect through.
    return host == appHost.toLowerCase() ||
        host.endsWith('.supabase.co') ||
        host == 'accounts.google.com';
  }

  // tel:, sms:, geo:, intent:, mailto:, market:, comgooglemaps: ... — another app's job.
  return false;
}
