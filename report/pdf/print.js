// Print an HTML file to PDF with the pre-installed Chromium (Playwright).
// Usage: node print.js in.html out.pdf "footer text"
const path = require('path');
const { chromium } = require('playwright');

const [, , html, pdf, footer] = process.argv;
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;');

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  await page.goto('file://' + path.resolve(html), { waitUntil: 'load' });
  await page.pdf({
    path: pdf,
    format: 'Letter',
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: '<span></span>',
    footerTemplate:
      '<div style="font-family:\'Liberation Serif\',serif;font-size:8pt;color:#555;' +
      'width:100%;margin:0 1in;display:flex;justify-content:space-between">' +
      '<span>' + esc(footer || '') + '</span>' +
      '<span><span class="pageNumber"></span> / <span class="totalPages"></span></span></div>',
    margin: { top: '0.9in', bottom: '0.9in', left: '1in', right: '1in' },
  });
  await browser.close();
})();
