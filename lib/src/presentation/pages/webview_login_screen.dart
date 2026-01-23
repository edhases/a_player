import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get_it/get_it.dart';
import '../../core/services/google_auth_service.dart';

class WebViewLoginScreen extends StatefulWidget {
  const WebViewLoginScreen({super.key});

  @override
  State<WebViewLoginScreen> createState() => _WebViewLoginScreenState();
}

class _WebViewLoginScreenState extends State<WebViewLoginScreen> {
  final CookieManager _cookieManager = CookieManager.instance();
  final _authService = GetIt.I<GoogleAuthService>();

  final String _targetUrl = 'https://music.youtube.com';
  InAppWebViewController? _webViewController;
  bool _isCheckingCookies = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in to YouTube Music'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _webViewController?.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(_targetUrl)),
            initialSettings: InAppWebViewSettings(
              userAgent:
                  "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36",
              javaScriptEnabled: true,
              domStorageEnabled: true,
              thirdPartyCookiesEnabled: true,
              cacheEnabled: true,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller;
            },
            onLoadStop: (controller, url) async {
              if (url != null && url.toString().contains('music.youtube.com')) {
                await _checkCookies(url);
              }
            },
            onReceivedError: (controller, request, error) {
              debugPrint('[WebViewLogin] Load error: $error');
            },
          ),
          if (_isCheckingCookies)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Збереження cookies...',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _checkCookies(WebUri url) async {
    if (_isCheckingCookies) return;

    try {
      final cookies = await _cookieManager.getCookies(url: url);

      // Шукаємо ключові cookies для авторизації
      final hasAuth = cookies.any((c) =>
          c.name == 'SAPISID' ||
          c.name == '__Secure-3PAPISID' ||
          c.name == '__Secure-1PAPISID');

      if (hasAuth) {
        setState(() => _isCheckingCookies = true);

        // Формуємо Cookie header
        final cookieHeader =
            cookies.map((c) => '${c.name}=${c.value}').join('; ');

        debugPrint('[WebViewLogin] ✅ Auth cookies found!');
        debugPrint(
            '[WebViewLogin] Cookies: ${cookies.map((c) => c.name).join(', ')}');

        // Зберігаємо через GoogleAuthService
        await _authService.saveCookies(cookieHeader);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Успішний вхід!'),
              backgroundColor: Colors.green,
            ),
          );

          // Повертаємось з результатом true
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      debugPrint('[WebViewLogin] Error checking cookies: $e');
      if (mounted) {
        setState(() => _isCheckingCookies = false);
      }
    }
  }

  @override
  void dispose() {
    _webViewController = null;
    super.dispose();
  }
}
