import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'web_automation_framework.dart';

Future main() async {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey webViewKey = GlobalKey();
  Browser? browser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Web Automation Framework'),
        ),
        body: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                if (browser == null || browser!.isClosed()) {
                  browser = await WebAutomationFramework.launch();
                }

                final page = await browser!.newPage();
                if (kDebugMode) {
                  print(browser?.pages());
                }
                page.onConsole = (consoleMessage) async {
                  if (kDebugMode) {
                    print(consoleMessage);
                  }
                };

                page.exposeFunction(
                  name: 'hash',
                  function: (arguments) {
                    return Object.hashAll(arguments).toString();
                  },
                );

                final response =
                    await page.goto(url: 'https://developers.google.com/web/');
                if (kDebugMode) {
                  print(response);
                }

                // Type into search box.
                await page.type(
                    selector: '.devsite-search-field', text: 'Headless Chrome');

                // Wait for suggest overlay to appear and click "show all results".
                const allResultsSelector = '.devsite-suggest-all-results';
                await page.waitForSelector(selector: allResultsSelector);
                await page.click(selector: allResultsSelector);

                // Wait for the results page to load and display the results.
                const resultsSelector =
                    '.gsc-results .gsc-thumbnail-inside a.gs-title';
                await page.waitForSelector(selector: resultsSelector);

                // Extract the results from the page.
                final List<String>? links = (await page.evaluate(source: """
                  [...document.querySelectorAll('$resultsSelector')].map(anchor => {
                    const title = anchor.textContent.split('|')[0].trim();
                    return `\${title} - \${anchor.href}`;
                  });
                """))?.cast<String>();

                if (kDebugMode) {
                  print(links?.join('\n'));
                }

                final result = await page.evaluateAsync(functionBody: """
                  return await window.hash('test');
                """);
                if (kDebugMode) {
                  print(result?.value);
                }

                final response2 =
                    await page.goto(url: 'https://github.com/flutter/');
                if (kDebugMode) {
                  print(response2);
                }

                final response3 = await page.goBack();
                if (kDebugMode) {
                  print(response3);
                }

                page.waitForRequest(predicate: (request) async {
                  return request.url?.toString().startsWith(
                          'https://googledevelopers.blogspot.com/') ??
                      false;
                }).then((request) {
                  if (kDebugMode) {
                    print(request);
                  }
                });
                await page.click(selector: '.devsite-footer-linkbox-link');
              },
              child: const Text('Start test'),
            ),
            ElevatedButton(
              onPressed: () async {
                await browser?.close();
              },
              child: const Text('Stop test'),
            ),
          ],
        )));
  }
}
