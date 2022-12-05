import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'custom_image.dart';
import 'webview_tab.dart';

List<WebViewTab> webViewTabs = [];
int currentTabIndex = 0;
const kHomeUrl = 'https://google.com';

Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb &&
      kDebugMode &&
      defaultTargetPlatform == TargetPlatform.android) {
    await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
  }
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool showWebViewTabsViewer = false;

  @override
  void initState() {
    super.initState();

    webViewTabs.add(createWebViewTab());
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Scaffold(
          appBar: showWebViewTabsViewer
              ? _buildWebViewTabViewerAppBar()
              : _buildWebViewTabAppBar(),
          body: IndexedStack(
            index: showWebViewTabsViewer ? 1 : 0,
            children: [_buildWebViewTabs(), _buildWebViewTabsViewer()],
          )),
      onWillPop: () async {
        if (showWebViewTabsViewer) {
          setState(() {
            showWebViewTabsViewer = false;
          });
        } else if (await webViewTabs[currentTabIndex].canGoBack()) {
          webViewTabs[currentTabIndex].goBack();
        } else {
          return true;
        }
        return false;
      },
    );
  }

  WebViewTab createWebViewTab({String? url, int? windowId}) {
    WebViewTab? webViewTab;

    if (url == null && windowId == null) {
      url = kHomeUrl;
    }

    webViewTab = WebViewTab(
      key: GlobalKey(),
      url: url,
      windowId: windowId,
      onStateUpdated: () {
        setState(() {});
      },
      onCloseTabRequested: () {
        if (webViewTab != null) {
          _closeWebViewTab(webViewTab);
        }
      },
      onCreateTabRequested: (createWindowAction) {
        _addWebViewTab(windowId: createWindowAction.windowId);
      },
    );
    return webViewTab;
  }

  AppBar _buildWebViewTabAppBar() {
    return AppBar(
      leading: IconButton(
          onPressed: () {
            _addWebViewTab();
          },
          icon: const Icon(Icons.add)),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            webViewTabs[currentTabIndex].title ?? '',
            overflow: TextOverflow.fade,
          ),
          Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              webViewTabs[currentTabIndex].isSecure != null
                  ? Icon(
                      webViewTabs[currentTabIndex].isSecure == true
                          ? Icons.lock
                          : Icons.lock_open,
                      color: webViewTabs[currentTabIndex].isSecure == true
                          ? Colors.green
                          : Colors.red,
                      size: 12)
                  : Container(),
              const SizedBox(
                width: 5,
              ),
              Flexible(
                  child: Text(
                webViewTabs[currentTabIndex].currentUrl ??
                    webViewTabs[currentTabIndex].url ??
                    '',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
                overflow: TextOverflow.fade,
              )),
            ],
          )
        ],
      ),
      actions: _buildWebViewTabActions(),
    );
  }

  Widget _buildWebViewTabs() {
    return IndexedStack(index: currentTabIndex, children: webViewTabs);
  }

  List<Widget> _buildWebViewTabActions() {
    return [
      IconButton(
        onPressed: () async {
          await webViewTabs[currentTabIndex].updateScreenshot();
          setState(() {
            showWebViewTabsViewer = true;
          });
        },
        icon: Container(
          margin: const EdgeInsets.only(top: 5, bottom: 5),
          decoration: BoxDecoration(
              border: Border.all(width: 2.0, color: Colors.white),
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(5.0)),
          constraints: const BoxConstraints(minWidth: 25.0),
          child: Center(
              child: Text(
            webViewTabs.length.toString(),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14.0),
          )),
        ),
      ),
    ];
  }

  AppBar _buildWebViewTabViewerAppBar() {
    return AppBar(
      leading: IconButton(
          onPressed: () {
            setState(() {
              showWebViewTabsViewer = false;
            });
          },
          icon: const Icon(Icons.arrow_back)),
      title: const Text('WebView Tab Viewer'),
      actions: _buildWebViewTabsViewerActions(),
    );
  }

  Widget _buildWebViewTabsViewer() {
    return GridView.count(
      crossAxisCount: 2,
      children: webViewTabs.map((webViewTab) {
        return _buildWebViewTabGrid(webViewTab);
      }).toList(),
    );
  }

  Widget _buildWebViewTabGrid(WebViewTab webViewTab) {
    final webViewIndex = webViewTabs.indexOf(webViewTab);
    final screenshotData = webViewTab.screenshot;
    final favicon = webViewTab.favicon;

    return Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(
            side: currentTabIndex == webViewIndex
                ? const BorderSide(
                    // border color
                    color: Colors.black,
                    // border thickness
                    width: 2)
                : BorderSide.none,
            borderRadius: const BorderRadius.all(
              Radius.circular(5),
            )),
        child: InkWell(
          onTap: () {
            _selectWebViewTab(webViewTab);
          },
          child: Column(
            children: [
              ListTile(
                tileColor: Colors.black12,
                selected: currentTabIndex == webViewIndex,
                selectedColor: Colors.white,
                selectedTileColor: Colors.black,
                contentPadding: const EdgeInsets.only(left: 10),
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                title: Row(mainAxisSize: MainAxisSize.max, children: [
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    child: favicon != null
                        ? CustomImage(
                            url: favicon.url, maxWidth: 20.0, height: 20.0)
                        : null,
                  ),
                  Expanded(
                      child: Text(
                    webViewTab.title ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ))
                ]),
                trailing: IconButton(
                    onPressed: () {
                      _closeWebViewTab(webViewTab);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 16,
                    )),
              ),
              Expanded(
                  child: Ink(
                decoration: screenshotData != null
                    ? BoxDecoration(
                        image: DecorationImage(
                        image: MemoryImage(screenshotData),
                        fit: BoxFit.fitWidth,
                        alignment: Alignment.topCenter,
                      ))
                    : null,
              ))
            ],
          ),
        ));
  }

  List<Widget> _buildWebViewTabsViewerActions() {
    return [
      IconButton(
          onPressed: () {
            _closeAllWebViewTabs();
          },
          icon: const Icon(Icons.clear_all))
    ];
  }

  void _addWebViewTab({String? url, int? windowId}) {
    webViewTabs.add(createWebViewTab(url: url, windowId: windowId));
    setState(() {
      currentTabIndex = webViewTabs.length - 1;
    });
  }

  void _selectWebViewTab(WebViewTab webViewTab) {
    final webViewIndex = webViewTabs.indexOf(webViewTab);
    webViewTabs[currentTabIndex].pause();
    webViewTab.resume();
    setState(() {
      currentTabIndex = webViewIndex;
      showWebViewTabsViewer = false;
    });
  }

  void _closeWebViewTab(WebViewTab webViewTab) {
    final webViewIndex = webViewTabs.indexOf(webViewTab);
    webViewTabs.remove(webViewTab);
    if (currentTabIndex > webViewIndex) {
      currentTabIndex--;
    }
    if (webViewTabs.isEmpty) {
      webViewTabs.add(createWebViewTab());
      currentTabIndex = 0;
    }
    setState(() {
      currentTabIndex = max(0, min(webViewTabs.length - 1, currentTabIndex));
    });
  }

  void _closeAllWebViewTabs() {
    webViewTabs.clear();
    webViewTabs.add(createWebViewTab());
    setState(() {
      currentTabIndex = 0;
    });
  }
}
