# AGENT.md

Rules and plan for anyone (human or AI agent) changing this repository.

## What this repository is

A fork of CefGlue that targets **.NET 10 + Avalonia 12 on Windows and Linux only**
(x64; ARM64 builds as `*.ARM64` packages). macOS and WPF are not targeted: their code is
still in the tree because it comes from upstream, but it is not built into the packages or
maintained here.

- Upstream: `OutSystems/CefGlue`, branch `main` (https://github.com/OutSystems/CefGlue).
- Fork: `origin` = `unclesnote/CefGlue-Avalonia12-WinLinux-Only`, branch `main`.

## Rules

### 1. Package version: major is always `999`

The version lives in one place: `<Version>` in `Directory.Build.props`.

- The major part is fixed at **`999`** so these packages never collide with, and always
  sort above, the official `CefGlue.*` packages.
- The parts after it (`minor.patch`) follow upstream. When upstream's `<Version>` changes,
  keep `999` and take only upstream's remaining parts:

  | Upstream `<Version>` | Fork `<Version>` |
  |---|---|
  | `120.6099.215` | `999.6099.215` |
  | `120.6099.216` | `999.6099.216` |
  | `126.6478.1`   | `999.6478.1`   |

- Never change the `999` major, and never commit upstream's major into this fork.
- The CEF runtime version is separate (`CefRedistVersion`, `CefRedistLinuxVersion` in
  `Directory.Build.props`); take upstream's value for those as-is.

### 2. Keep changes to upstream files minimal

Cherry-picks from upstream must stay easy to apply, so:

- Put fork-only behaviour in **new files** and hook them in with as few lines as possible.
  Existing hooks:
  - `CefGlue.WinLinuxOnly.targets` (imported by one line in `Directory.Build.targets`):
    removes the macOS CEF redist dependencies, skips the macOS browser-process publish and
    drops `bin/osx-*` from the `CefGlue.Common` package.
  - `publish.sh`: builds the NuGet packages into `Nuget/output`.
  - `run_demo.sh`: clean-builds and launches the Avalonia demo.
- Don't delete or rewrite upstream macOS/WPF code just because the fork does not use it;
  exclude it from the build or the packages instead.
- When an upstream file has to change (a bug fix, Linux support), keep the diff small and
  self-contained so it is easy to re-apply after an upstream change, or to send upstream.

### 3. Commits

- Commit messages are in English: a short imperative subject, then a body that explains why.
- One feature per commit (e.g. IME, message loop, packaging, docs are separate commits).
- Cherry-picked upstream commits use `git cherry-pick -x` so the upstream hash is recorded.

### 4. Verify before committing

- Build and pack: `./publish.sh` (Release, host architecture). Both
  `CefGlue.Common.999.*.nupkg` and `CefGlue.Avalonia.999.*.nupkg` must be created, and the
  Common package must contain only `bin/linux-*` and `bin/win-*`.
- Tests: `dotnet test CefGlue.Tests/CefGlue.Tests.csproj -p:Platform=x64`.
  Known issue: a full run currently ends with 2 failures and a test-host crash
  ("Test Run Aborted") that also happen without the fork's changes; compare against the
  previous commit before treating a failure as new.
- Linux IME: `CefGlue.Tests/Platform/LinuxIBusEndToEndTests.cs` is `[Explicit]` and needs a
  live X11 + IBus Hangul session. IBus is verified end to end; Fcitx/Fcitx5 is detected and
  configured but has not been verified in a live session.

## Plan: syncing with upstream

Upstream changes are brought in by cherry-picking, not merging.

1. One-time setup:
   ```bash
   git remote add upstream https://github.com/OutSystems/CefGlue.git
   ```
2. Fetch and list what upstream has that the fork does not yet have:
   ```bash
   git fetch upstream
   git log --oneline --no-merges main..upstream/main
   ```
3. Cherry-pick the wanted commits onto a branch off `main`, oldest first:
   ```bash
   git switch -c sync-upstream main
   git cherry-pick -x <sha>...
   ```
   Skip commits that only touch macOS or WPF unless they also change shared code.
4. Resolve conflicts:
   - `<Version>` in `Directory.Build.props`: apply rule 1 (keep `999`, take upstream's
     `minor.patch`).
   - Files hooked by the fork (`Directory.Build.targets`, `Directory.Build.props`, the Linux
     files under `CefGlue.Avalonia/Platform/Linux` and `CefGlue.Common/Platform`): keep both
     sides; the fork's lines must survive.
   - If upstream changes a target the fork replaces (`PublishApp` in
     `CefGlue.BrowserProcess.csproj`, overridden in `CefGlue.WinLinuxOnly.targets`), port
     upstream's change into the override, minus the macOS publish.
5. Verify (rule 4), then fast-forward `main` and push to `origin`.
