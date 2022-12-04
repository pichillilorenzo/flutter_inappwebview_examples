import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }
  runApp(const MaterialApp(home: MyApp()));
}

enum ProgressIndicatorType { circular, linear }

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  double progress = 0;
  ProgressIndicatorType type = ProgressIndicatorType.linear;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Progress Indicator: ${type.name}",
              style: const TextStyle(fontSize: 18)),
          actions: [
            IconButton(
                onPressed: () async {
                  await webViewController?.loadUrl(
                      urlRequest:
                          URLRequest(url: WebUri("https://flutter.dev")));
                },
                icon: const Icon(Icons.home)),
            IconButton(
                onPressed: () async {
                  await webViewController?.clearCache();
                  await webViewController?.reload();
                },
                icon: const Icon(Icons.refresh)),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Text(ProgressIndicatorType.linear.name),
                  onTap: () {
                    setState(() {
                      type = ProgressIndicatorType.linear;
                    });
                  },
                ),
                PopupMenuItem(
                  child: Text(ProgressIndicatorType.circular.name),
                  onTap: () {
                    setState(() {
                      type = ProgressIndicatorType.circular;
                    });
                  },
                ),
              ],
            ),
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
              child: Stack(children: [
            InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri("https://flutter.dev")),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onProgressChanged: (controller, progress) {
                setState(() {
                  this.progress = progress / 100;
                });
              },
            ),
            progress < 1.0 ? getProgressIndicator(type) : Container(),
          ])),
        ]));
  }

  Widget getProgressIndicator(ProgressIndicatorType type) {
    switch (type) {
      case ProgressIndicatorType.circular:
        return Center(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: Colors.white.withAlpha(70),
            ),
            child: const CircularProgressIndicator(),
          ),
        );
      case ProgressIndicatorType.linear:
      default:
        return LinearProgressIndicator(
          value: progress,
        );
    }
  }
}
