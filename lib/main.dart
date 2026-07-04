import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SEVEN WebView',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const WebViewScreen(),
    );
  }
}

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  InAppWebViewController? _controller;
  bool _isLoading = true;

  static const String _siteUrl = 'https://alamir-1.github.io/SEVEN1/';

  Uri _freshUri() {
    return Uri.parse(
      '$_siteUrl?_t=${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _reload() async {
    await _controller?.loadUrl(
      urlRequest: URLRequest(url: WebUri.uri(_freshUri())),
    );
  }

  Future<bool> _onWillPop() async {
    if (_controller != null && await _controller!.canGoBack()) {
      _controller!.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              InAppWebView(
                initialUrlRequest: URLRequest(url: WebUri.uri(_freshUri())),
                initialSettings: InAppWebViewSettings(
                  javaScriptEnabled: true,
                  useOnDownloadStart: true,
                  useShouldOverrideUrlLoading: true,
                  mixedContentMode:
                      MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
                ),
                onWebViewCreated: (controller) {
                  _controller = controller;
                },
                onLoadStart: (controller, url) {
                  setState(() => _isLoading = true);
                },
                onLoadStop: (controller, url) {
                  setState(() => _isLoading = false);
                },
                onReceivedError: (controller, request, error) {
                  debugPrint('WebView Error: ${error.description}');
                },
                // هنا بيتم التعامل مع أي محاولة تحميل ملف (PDF أو صورة)
                onDownloadStartRequest: (controller, downloadStartRequest) async {
                  final fileUrl = downloadStartRequest.url.toString();
                  final uri = Uri.parse(fileUrl);
                  // بيفتح الملف بمتصفح الجهاز (Chrome) اللي هيحمله وينزله
                  // على مجلد التنزيلات (Downloads) بشكل طبيعي وتلقائي
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(
                      uri,
                      mode: LaunchMode.externalApplication,
                    );
                  }
                },
                // لو الموقع فتح رابط ملف مباشرة (زي رابط PDF) بدل ما يبدأ تحميل
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url.toString();
                  final lower = url.toLowerCase();
                  if (lower.endsWith('.pdf') ||
                      lower.endsWith('.jpg') ||
                      lower.endsWith('.jpeg') ||
                      lower.endsWith('.png')) {
                    final uri = Uri.parse(url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                      return NavigationActionPolicy.CANCEL;
                    }
                  }
                  return NavigationActionPolicy.ALLOW;
                },
              ),
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _reload,
          tooltip: 'تحديث الصفحة',
          child: const Icon(Icons.refresh),
        ),
      ),
    );
  }
}
