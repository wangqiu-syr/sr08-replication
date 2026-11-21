# report/pdf/

The PDF build for [report/report.md](../report.md).

- `build.sh`: pandoc writes a standalone HTML page from `report.md`, and Chromium (Playwright) prints it to `report/report.pdf`, with a footer giving the author, the version and the page number.
- `filter.lua`: points relative links to the files on GitHub, and builds APA 7 tables and figures: a bold "Table N" or "Figure N" line and an italic title become the caption, and the *Note.* paragraph that follows is kept on the same page.
- `print.js`: prints the HTML page with Playwright's Chromium (US Letter, footer, margins).
- `style.css`: the print style.

Run from anywhere:

```sh
bash report/pdf/build.sh
```

It needs pandoc 3 or later and Node with Playwright. `REF` sets the GitHub ref that the PDF's relative links point to (default: the version in `CITATION.cff`, as a tag, e.g. v1.1.0).

## How the committed report.pdf was built

The committed `report/report.pdf` was built on Windows without Node or Playwright. The pandoc step was the same as in `build.sh` (same options, `filter.lua` and `style.css`; pandoc 3.4). Headless Chrome then printed the page, with the footer and margins of `print.js` given as print CSS (`@page` margin boxes). Liberation Serif was not installed, so the text is set in Times New Roman.

On a machine with Node and Playwright, `bash report/pdf/build.sh` reproduces the same report; the font may differ (Liberation Serif where it is installed).
