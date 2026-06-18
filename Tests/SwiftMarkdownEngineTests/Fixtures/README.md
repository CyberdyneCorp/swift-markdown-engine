# Test fixtures

This directory holds conformance fixtures bundled into the test target.

- `commonmark-examples.json` — a small seed subset in the CommonMark spec format
  (`[{ "markdown": …, "html": …, "section": … }]`).

Task 3.8 replaces/extends this with the full CommonMark spec suite (~650 cases) and
the GFM example set once they are vendored into the repo. The conformance test driver
reads every `*.json` file in this directory, so dropping the full suites here requires
no test-code changes.
