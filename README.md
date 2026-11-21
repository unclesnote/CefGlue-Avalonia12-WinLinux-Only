# CefGlue
.NET binding for The Chromium Embedded Framework (CEF). 

CefGlue lets you embed Chromium in .NET apps. It is a .NET wrapper control around the Chromium Embedded Framework ([CEF](https://bitbucket.org/chromiumembedded/cef/src/master/)). 
This fork targets **.NET 10** and **Avalonia 12**, and aims to support **Avalonia on Windows and Linux x64 only** (macOS, WPF and ARM64 are not targeted).

It was initially branched from `selway/CefGlue` (`feature-avaloniaui12` at commit `e204172`, [OutSystems/CefGlue#249](https://github.com/OutSystems/CefGlue/pull/249)), with subsequent upstream `OutSystems/CefGlue` fixes, PR #249 follow-ups, and `.NET 10` / Avalonia 12 updates applied on top.

Here's a table for supported architectures, frameworks and operating systems in this fork:

| OS      | x64 | ARM64 | WPF | Avalonia |
|---------|-----|-------|-----|----------|
| Windows | ✔️  | ❌    | ❌  | ✔️      |
| macOS   | ❌  | ❌    | ❌  | ❌      |
| Linux   | ✔️  | ❌    | ❌  | ✔️      |

✔️ Supported
❌ Not supported / not targeted in this fork

See [LINUX.md](./LINUX.md) for more information about issues and tested distribution list. 

Only the x64 architecture is supported in this fork; ARM64 is not supported.

## Differences from upstream
Compared with [`OutSystems/CefGlue`](https://github.com/OutSystems/CefGlue) `main` as of `4fdf9ce` (#255, 2026-09-25). The fork contains every upstream feature up to that commit: the latest upstream commits (#252, #253, #255) have been cherry-picked, with #252 adapted to the fork's timer-based message pump.

### Runtime and scope

| Area | Upstream `main` | This fork |
|---|---|---|
| .NET | net8.0 | **net10.0** |
| Avalonia | 11.0.9 | **12.1.6** |
| CEF | 120.1.8 | 120.1.8 (same) |
| OS in the packages | Windows, macOS, Linux | **Windows, Linux** |
| Architectures | x64, ARM64 | **x64 only** |
| WPF | Supported | Not targeted (code remains, not built by the fork's scripts) |
| Dependencies | Avalonia.ReactiveUI, System.Reactive.Linq, System.Text.Json, System.Runtime.Loader, Avalonia.Diagnostics | All five removed; **AvaloniaUI.DiagnosticsSupport 2.2.3** added (also a dependency of the CefGlue.Avalonia package) |

### Linux behaviour

| Area | Upstream `main` | This fork |
|---|---|---|
| CEF message loop | Runs on its own thread (`MultiThreadedMessageLoop`) | **Runs on the Avalonia UI thread**, polled at 60 Hz by default |
| IME (e.g. Korean) | No special handling | `LinuxImeEnvironment` fills in `GTK_IM_MODULE`, `XMODIFIERS` and `IBUS_ENABLE_SYNC_MODE` before CEF starts. IBus is verified end to end; Fcitx5 is detected and configured but not verified in a live session |
| Signal handlers | CEF initialization overwrites CoreCLR's handlers | Saved before and restored after initialization, so `NullReferenceException` and debugger breakpoints keep working |
| HarfBuzz symbol clash | Can crash with SIGSEGV unless started with `LD_PRELOAD` | `libHarfBuzzSharp.so` is preloaded automatically |

### Build and packaging

| Area | Upstream `main` | This fork |
|---|---|---|
| Builds without `Platform` (AnyCPU) | No CEF target platform or runtime packages | Resolved from the host architecture |
| Windows `editbin` | Only the path given in `VcvarsFile` | Falls back to `vswhere` when that path does not exist |
| Package version | 120.6099.215 | **999.6099.215** (major fixed at 999, the rest follows upstream) |
| `CefGlue.Common` package | Windows, Linux and macOS browser process, ~111 MB, depends on the macOS CEF runtime | **Windows and Linux only, ~72 MB**, no macOS dependency |
| Distribution | NuGet.org | Committed to this repository under `Nuget/output` |
| Developer tooling | None | `run_demo.sh`, `publish.sh`, VS Code tasks and launch configurations, `AGENT.md` |

### Tests

| Area | Upstream `main` | This fork |
|---|---|---|
| Time-related tests | Depend on the local time zone | Compared in UTC |
| `CustomRequestContext` test | Hard-coded Windows path fails on Linux | Uses a cache path valid on every OS |
| Linux-only tests | None | 10 IME unit tests, a signal-handler test, an `[Explicit]` IBus end-to-end test |

## Releases
This fork does not publish to NuGet.org. Its packages (`CefGlue.Common` and `CefGlue.Avalonia`, version `999.*`) are committed to [`Nuget/output`](Nuget/output); to rebuild them:
```bash
./publish.sh
```

## Documentation 
See the [Avalonia sample](CefGlue.Demo.Avalonia) project for an example web browser built with CefGlue.

To clean-build and launch the Avalonia demo for your current OS/architecture:
```bash
./run_demo.sh
# or for Release configuration:
CONFIGURATION=Release ./run_demo.sh
```
