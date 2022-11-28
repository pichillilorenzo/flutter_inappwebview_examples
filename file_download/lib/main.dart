import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }

  // Plugin must be initialized before using
  await FlutterDownloader.initialize(
      debug: true,
      // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl:
          false // option: set to false to disable working with http links (default: false)
      );

  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;

  final ReceivePort _port = ReceivePort();

  @override
  void initState() {
    super.initState();

    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    _port.listen((dynamic data) {
      String id = data[0];
      DownloadTaskStatus status = data[1];
      int progress = data[2];
      if (kDebugMode) {
        print("Download progress: $progress%");
      }
      if (status == DownloadTaskStatus.complete) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Download $id completed!"),
        ));
      }
    });
    FlutterDownloader.registerCallback(downloadCallback);
  }

  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }

  @pragma('vm:entry-point')
  static void downloadCallback(
      String id, DownloadTaskStatus status, int progress) {
    final SendPort? send =
        IsolateNameServer.lookupPortByName('downloader_send_port');
    send?.send([id, status, progress]);
  }

  void handleClick(int item) async {
    switch (item) {
      case 0:
        await webViewController?.loadUrl(
            urlRequest: URLRequest(
                url: WebUri("https://proof.ovh.net/files/10Mb.dat")));
        break;
      case 1:
        await webViewController?.loadUrl(
            urlRequest: URLRequest(
                url: WebUri(
                    "https://www.w3schools.com/tags/tryit.asp?filename=tryhtml5_a_download")));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("InAppWebView Download"),
          actions: [
            PopupMenuButton<int>(
              onSelected: (item) => handleClick(item),
              itemBuilder: (context) => [
                const PopupMenuItem<int>(
                    value: 0, child: Text('Download file 1')),
                const PopupMenuItem<int>(
                    value: 1, child: Text('Download file 2')),
              ],
            ),
          ],
        ),
        body: Column(children: <Widget>[
          Expanded(
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(url: WebUri("https://flutter.dev")),
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              shouldOverrideUrlLoading: (controller, navigationAction) async {
                if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
                  final shouldPerformDownload =
                      navigationAction.shouldPerformDownload ?? false;
                  final url = navigationAction.request.url;
                  if (shouldPerformDownload && url != null) {
                    await downloadFile(url.toString());
                    return NavigationActionPolicy.DOWNLOAD;
                  }
                }
                return NavigationActionPolicy.ALLOW;
              },
              onDownloadStartRequest: (controller, downloadStartRequest) async {
                await downloadFile(downloadStartRequest.url.toString(),
                    downloadStartRequest.suggestedFilename);
              },
            ),
          ),
        ]));
  }

  Future<void> downloadFile(String url, [String? filename]) async {
    var hasStoragePermission = await Permission.storage.isGranted;
    if (!hasStoragePermission) {
      final status = await Permission.storage.request();
      hasStoragePermission = status.isGranted;
    }
    if (hasStoragePermission) {
      final taskId = await FlutterDownloader.enqueue(
          url: url,
          headers: {},
          // optional: header send with url (auth token etc)
          savedDir: (await getTemporaryDirectory()).path,
          saveInPublicStorage: true,
          fileName: filename);
    }
  }
}
