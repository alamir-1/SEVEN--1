import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

final GlobalKey<ScaffoldMessengerState> _messengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // خلي الشريط العلوي (شريط الحالة) شفاف والتطبيق ياخد الشاشة كاملة
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      scaffoldMessengerKey: _messengerKey,
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

  static const String _siteUrl = 'https://alamir-1.github.io/SEVEN-27-3/';

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

  // بتحدد امتداد الملف المناسب حسب نوعه القادم من الموقع
  String _extensionFromMime(String mime) {
    if (mime.contains('spreadsheetml') || mime.contains('ms-excel')) {
      return 'xlsx';
    }
    if (mime.contains('pdf')) return 'pdf';
    if (mime.contains('csv')) return 'csv';
    if (mime.contains('wordprocessingml') || mime.contains('msword')) {
      return 'docx';
    }
    return 'bin';
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
          top: false,
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

                  if (fileUrl.startsWith('data:')) {
                    try {
                      final commaIndex = fileUrl.indexOf(',');
                      final header = fileUrl.substring(5, commaIndex);
                      final isImage = header.contains('image');
                      final base64Str = fileUrl.substring(commaIndex + 1);
                      final bytes = base64Decode(base64Str);

                      if (isImage) {
                        // الصور بتتحفظ مباشرة في معرض الصور
                        await Gal.requestAccess();
                        await Gal.putImageBytes(
                          bytes,
                          name:
                              'SEVEN_${DateTime.now().millisecondsSinceEpoch}',
                        );
                        _messengerKey.currentState?.showSnackBar(
                          const SnackBar(
                              content: Text('تم حفظ الصورة في معرض الصور ✅')),
                        );
                      } else {
                        // أي نوع تاني (إكسل، PDF، وورد...) بيتحفظ في ملف مؤقت
                        // وبعدين بيتفتح شاشة "مشاركة/حفظ" عشان تختار فين تحفظه
                        final ext = _extensionFromMime(header);
                        final tempDir = await getTemporaryDirectory();
                        final fileName =
                            'SEVEN_${DateTime.now().millisecondsSinceEpoch}.$ext';
                        final filePath = '${tempDir.path}/$fileName';
                        final file = File(filePath);
                        await file.writeAsBytes(bytes);

                        await Share.shareXFiles(
                          [XFile(filePath)],
                          text: 'ملف من تطبيق SEVEN',
                        );
                      }
                    } catch (e) {
                      debugPrint('Error saving file: $e');
                      _messengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('حصل خطأ أثناء الحفظ ❌')),
                      );
                    }
                  } else {
                    final uri = Uri.parse(fileUrl);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(
                        uri,
                        mode: LaunchMode.externalApplication,
                      );
                    }
                  }
                },
                // لو الموقع فتح رابط ملف مباشرة (زي رابط PDF) بدل ما يبدأ تحميل
                shouldOverrideUrlLoading: (controller, navigationAction) async {
                  final url = navigationAction.request.url.toString();
                  final lower = url.toLowerCase();
                  final isDownloadable = lower.contains('.pdf') ||
                      lower.contains('.jpg') ||
                      lower.contains('.jpeg') ||
                      lower.contains('.png') ||
                      lower.contains('.webp');
                  if (isDownloadable) {
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
      ),
    );
  }
}
