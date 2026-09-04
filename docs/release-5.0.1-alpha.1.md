# Aerox 5.0.1-alpha.1

Integrates canonical `miuuyy/codex-chatgpt-web` through
`9a7428a9d1fced9baaa85112994c02c011a3b7c9` (5.0.1), retaining the Aerox
runtime, authentication, attachment, broker, and release-packaging fixes.

Windows now embeds hash-pinned official Bun 1.4.0 (`34cbb9a40`). Its ancestry
includes the streaming-abort fix from Bun PR #32120. The previous canary stalls
the retained-compaction deadline regression test; the official release passes it.

This is an alpha release, not a stable-release acceptance claim. Automated
verification and packaging smoke tests do not prove interactive account flows.
The manual Windows and macOS scenarios in `docs/release-validation.md` have
not been executed for this release, including login, native full mode,
compaction, cancellation, route restoration, and upgrade recovery.

In agent-system this project remains catalog-only; integration does not install
the launcher or change a live Codex route. Keep the previously working release
available. Before opting into this alpha, back up the affected configuration;
if account or routing behavior regresses, stop the alpha and restore that
configuration and the previous working release.
