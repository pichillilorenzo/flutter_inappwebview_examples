# Web Automation Framework

An example implementation of a headless web automation framework similar
to [Puppeteer](https://github.com/puppeteer/puppeteer)
or [Playwright](https://github.com/microsoft/playwright).

## Example

The following example (based on [https://pptr.dev/#example](https://pptr.dev/#example)) searches
[developers.google.com/web](https://developers.google.com/web) for articles tagged "Headless Chrome"
and scrape results from the results page.

```dart
Future main() async {
  final browser = await WebAutomationFramework.launch();
  final page = await browser.newPage();

  await page.goto(url: 'https://developers.google.com/web/');

  // Type into search box.
  await page.type(
      selector: '.devsite-search-field', text: 'Headless Chrome');

  // Wait for suggest overlay to appear and click "show all results".
  const allResultsSelector = '.devsite-suggest-all-results';
  await page.waitForSelector(selector: allResultsSelector);
  await page.click(selector: allResultsSelector);

  // Wait for the results page to load and display the results.
  const resultsSelector = '.gsc-results .gsc-thumbnail-inside a.gs-title';
  await page.waitForSelector(selector: resultsSelector);

  // Extract the results from the page.
  final List<String>? links = (await page.evaluate(source: """
      [...document.querySelectorAll('$resultsSelector')].map(anchor => {
        const title = anchor.textContent.split('|')[0].trim();
        return `\${title} - \${anchor.href}`;
      });
    """))?.cast<String>();

  if (kDebugMode) {
    // Print all the links.
    print(links?.join('\n'));
  }

  await browser.close();
}
```