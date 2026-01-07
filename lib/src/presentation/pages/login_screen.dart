import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _storage = const FlutterSecureStorage();
  final CookieManager _cookieManager = CookieManager.instance();
  
  // URL для входу в Google, який перенаправить на YouTube Music після успіху
  final WebUri _loginUrl = WebUri("https://accounts.google.com/ServiceLogin?service=youtube&continue=https://music.youtube.com");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sign in to YouTube Music"),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(url: _loginUrl),
        initialSettings: InAppWebViewSettings(
          userAgent: 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Mobile Safari/537.36', // Mobile user agent
          javaScriptEnabled: true,
          domStorageEnabled: true,
        ),
        onLoadStop: (controller, url) async {
          if (url == null) return;
          
          final urlString = url.toString();

          // Перевіряємо, чи ми вже на головній сторінці YouTube Music
          if (urlString.startsWith("https://music.youtube.com")) {
            // Отримуємо кукі
            final cookies = await _cookieManager.getCookies(url: url);
            
            if (cookies.isNotEmpty) {
              // Формуємо рядок Cookie, який потрібен для HTTP заголовків
              final cookieString = cookies
                  .map((e) => "${e.name}=${e.value}")
                  .join("; ");
              
              // Зберігаємо безпечно
              await _storage.write(key: 'user_cookies', value: cookieString);
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Successfully logged in!")),
                );
                Navigator.pop(context, true); // Повертаємо true як ознаку успіху
              }
            }
          }
        },
      ),
    );
  }
}
