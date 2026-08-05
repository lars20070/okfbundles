# Agent Instructions

## Library documentation (Context7 MCP)

Before writing or modifying any code that uses a third-party library, package,
or framework, fetch its current docs via the Context7 MCP server — do not rely
on training data for external APIs.

- Call `resolve-library-id` with the library name to get its Context7 ID, then
  `query-docs` with that ID and a specific `topic` (e.g. "middleware",
  "query invalidation").
- If you already know the exact ID (e.g. `/vercel/next.js`), skip resolving and
  call `query-docs` directly. Match the version in our manifest
  (package.json / requirements.txt / go.mod) when the library moves fast.
- Verify the library ID and version reported in the tool output before trusting
  the result; Context7 falls back to "latest" if a pinned version isn't indexed.
- Prefer a focused `topic` query to keep the pull small (~5k tokens/call).

If Context7 has no entry for a library, say so and fall back to your best
knowledge — do not block. You can also trigger a lookup manually by adding
"use context7" to a request.

## Debugging third-party libraries (GitHub MCP)

When you hit an error, crash, or unexpected behavior that appears to come from
an external dependency (not our own code), check whether it's a known bug
BEFORE building a workaround.

1. Identify the upstream repo (`owner/repo`) from the manifest — the
   `repository` field in package.json, project URL in PyPI/pyproject.toml,
   the Go module path, or Cargo.toml. Do not guess the repo.
2. Use the GitHub MCP server (issues toolset) to search that repo:
   - `search_issues` with a distinctive substring of the error message plus
     `is:issue is:open` (or `state:open`). Search the key symbol/message, not
     the whole stack trace.
   - Open the best matches with `issue_read` (`method: "get"` for the issue
     body, then `method: "get_comments"` — a separate call — for maintainer
     replies and any linked fix or workaround; `get` alone won't surface
     comments).
3. Also skim recently closed issues / merged PRs with `search_pull_requests`.
   A fix may exist in a newer release.
4. Report back: whether it's a known issue, the issue number + status, the full
   URL (`https://github.com/<owner>/<repo>/issues/<number>`), and any suggested
   workaround. Only then implement a local fix, and reference the issue number
   in a code comment.
