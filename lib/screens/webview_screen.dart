import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../config/app_config.dart';

const _locationServiceChannel = MethodChannel('shoppulse/location_service');

/// The entire app is this one screen: a full-screen WebView loading the
/// web-based technician app. All business logic (login, today's task,
/// checklist, proof capture) lives on the website, so shipping a feature
/// or bug fix there reaches every technician on their next page load — no
/// new APK, no reinstall. This wrapper's only job is bridging two things
/// the mobile web page can't do on its own inside a WebView: opening the
/// device camera (not gallery) when the page's file input is tapped, and
/// granting GPS access.
class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

// A brief background/resume round-trip — most notably taking a photo,
// which hands off to the native camera UI and back — must NOT trigger a
// reload, or it would wipe out an in-progress checklist/captured photo
// before the technician submits. Only reload after genuinely leaving the
// app for a while, so "always show the latest deployed version" doesn't
// come at the cost of losing in-progress proof capture.
const _reloadAfterBackgroundDuration = Duration(minutes: 2);

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _primeLocationPermission();
    _controller = _buildController();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _pausedAt ??= DateTime.now();
      return;
    }

    if (state != AppLifecycleState.resumed) return;

    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (pausedAt != null &&
        DateTime.now().difference(pausedAt) > _reloadAfterBackgroundDuration) {
      _controller.reload();
    }
  }

  Future<void> _primeLocationPermission() async {
    // Android must hold the OS-level permission before the WebView's JS
    // geolocation calls can succeed, regardless of what the in-page
    // permission prompt callback below allows.
    try {
      if (await Geolocator.isLocationServiceEnabled()) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          await Geolocator.requestPermission();
        }
      }
    } catch (_) {
      // Non-fatal: the page's own GPS capture step will surface a clear
      // error if location still isn't available when it's actually needed.
    }
  }

  WebViewController _buildController() {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {
            _loading = true;
            _error = null;
          }),
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (error) => setState(() {
            _loading = false;
            _error = error.description;
          }),
        ),
      )
      ..addJavaScriptChannel(
        'ShopPulseNative',
        onMessageReceived: _handleNativeBridgeMessage,
      )
      ..loadRequest(Uri.parse(AppConfig.techAppUrl));

    final platform = controller.platform;
    if (platform is AndroidWebViewController) {
      platform.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(allow: true, retain: true);
        },
      );

      platform.setOnShowFileSelector((params) async {
        final picker = ImagePicker();
        final photo = await picker.pickImage(
          source: ImageSource.camera, // Hardware-enforced: no gallery picking.
          imageQuality: 80,
          maxWidth: 1280,
        );
        if (photo == null) return [];
        return ['file://${photo.path}'];
      });
    }

    return controller;
  }

  /// Messages from the /tech web page after sign-in / sign-out (see
  /// lib/tech/nativeBridge.ts on the web side), routed to the native
  /// LocationTrackingService via MethodChannel.
  void _handleNativeBridgeMessage(JavaScriptMessage message) {
    try {
      final data = jsonDecode(message.message) as Map<String, dynamic>;
      switch (data['type']) {
        case 'startTracking':
          final apiUrl = Uri.parse(AppConfig.techAppUrl)
              .replace(path: '/api/staff/live-location')
              .toString();
          _locationServiceChannel.invokeMethod('startTracking', {
            'token': data['token'],
            'apiUrl': apiUrl,
          });
          break;
        case 'stopTracking':
          _locationServiceChannel.invokeMethod('stopTracking');
          break;
      }
    } catch (_) {
      // Malformed bridge message — ignore rather than crash the WebView.
    }
  }

  void _retry() {
    setState(() {
      _error = null;
      _loading = true;
    });
    _controller.reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Stack(
          children: [
            if (_error == null) WebViewWidget(controller: _controller),
            if (_loading && _error == null)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFFF97316)),
              ),
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load ShopPulse',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _retry,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
