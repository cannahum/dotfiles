# sourcekit-lsp setup notes (iOS / macOS / watchOS)

Context for the `sourcekit` block in `lspconfig.lua`. sourcekit-lsp ships with
Xcode itself (not Mason), and it doesn't natively understand `.xcodeproj` /
`.xcworkspace` projects — only bare `Package.swift` targets. For anything
built through Xcode (which includes almost every real iOS/macOS/watchOS app,
especially with CocoaPods or mixed local-package setups), you need
[xcode-build-server](https://github.com/SolaWing/xcode-build-server) as a
translation layer: it watches Xcode's own build logs and hands sourcekit-lsp
the real per-file compiler flags.

## Filetypes: why `c`/`cpp` are dropped

`nvim-lspconfig`'s built-in default for `sourcekit` is
`filetypes = { 'swift', 'objc', 'objcpp', 'c', 'cpp' }` — sourcekit-lsp does
understand plain C/C++ (needed for ObjC bridging-header / module-map interop
in mixed Swift+ObjC Xcode projects). `lspconfig.lua` overrides this down to
just `swift`, `objc`, `objcpp`. Nothing here configures `clangd` today, so
there's no active conflict, but leaving `c`/`cpp` in would mean the moment
clangd gets added for C/C++ work, both servers attach to every `.c`/`.cpp`
buffer and race each other (duplicate diagnostics, competing hover/format).
Narrowing it now costs nothing for the Swift/SPM use case and avoids that
footgun later.

## One-time machine setup (per machine, not per project)

1. Point `xcode-select` at full Xcode, not just CommandLineTools:

   ```
   sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
   ```

   Check with `xcode-select -p`. If it says `CommandLineTools`, iOS/watchOS
   SDKs won't resolve at all (`xcrun --sdk iphonesimulator --show-sdk-path`
   fails outright).

2. Run Xcode's first-launch setup once after switching/installing:

   ```
   xcodebuild -runFirstLaunch
   ```

   Skipping this causes a `DVTPlugInLoading`/`IDESimulatorFoundation` dlopen
   error on any `xcodebuild -list`/`-showBuildSettings` call.

3. Make sure at least one relevant simulator runtime is installed
   (`xcrun simctl list runtimes`). For watchOS you need a _paired_ watch
   simulator, not just the runtime. Xcode's GUI will offer to download these
   when you open a project — expect ~8GB for a full iOS runtime.

4. `brew install xcode-build-server` — this is a brew-only tool. mise can't
   install it: not in mise's core registry, and its GitHub releases ship no
   binary assets, so there's nothing for a generic release-fetching backend
   to grab either.

## Per-project setup

1. From the project root (same dir the LSP root_dir will resolve to):

   ```
   xcode-build-server config -workspace YourApp.xcworkspace -scheme YourScheme
   ```

   (`-project YourApp.xcodeproj` if there's no workspace.) This writes
   `buildServer.json` — check it's gitignored, don't commit it, it's
   machine-local (points at your local DerivedData path).

2. **Actually build the scheme once, successfully, from scratch.** This is
   the step that's easy to skip and causes the most confusing failure mode.
   Opening the project in Xcode and letting it "index" is _not_ the same
   thing — background indexing populates `DerivedData/.../Index.noindex`,
   which xcode-build-server does not use. It needs
   `DerivedData/.../Build/Products/...` to exist, which only a real build
   produces.

   From the CLI:

   ```
   xcodebuild build -workspace YourApp.xcworkspace -scheme YourScheme \
     -destination '<see platform notes below>' \
     -resultBundlePath .bundle \
     -skipPackagePluginValidation
   ```
   - `-skipPackagePluginValidation`: needed because SPM build-tool plugins
     (e.g. a SwiftLint plugin) normally require one-time interactive
     approval in Xcode's GUI; a headless CLI build can't satisfy that
     prompt and will otherwise fail immediately at plugin validation.
   - `-resultBundlePath .bundle`: per xcode-build-server's own README, this
     is what makes a CLI-driven build log equivalent to (and reliably
     parseable as) one Xcode itself would generate. Without it the log
     parser can silently fall back to near-useless data.
   - The exact destination doesn't have to match whatever
     `xcodebuild -showBuildSettings` would default to on its own (that tool
     has a known unfixed gap here — it doesn't pin a destination when
     asked for build settings). What matters is that _a_ real build for
     _some_ destination succeeded and got logged.

3. **After the first successful build, restart/reopen the LSP session —
   don't just wait for it to pick up the change live.** xcode-build-server
   parses the newest build log into an on-disk cache
   (`~/Library/Caches/xcode-build-server/...`) via a background thread that
   polls once a second. If sourcekit-lsp asks for compiler flags before that
   cache exists (e.g. right after generating `buildServer.json`, before any
   build has ever run), it seems to get stuck on that empty/wrong answer and
   doesn't reliably self-heal even after later builds succeed. A fresh
   sourcekit-lsp/xcode-build-server process loads the cache synchronously at
   startup if it's already on disk, so once it exists once, everything
   after "just works" with no delay.

   **Symptom if you skip this:** diagnostics show `No such module 'X'` for
   real dependencies that clearly exist and build fine via `xcodebuild`
   directly, and cross-file/cross-module go-to-definition returns nothing,
   persistently — even though the actual build is 100% fine. If you ever
   see this, the fix is almost never "fix the build," it's "close the file,
   make sure a real build has succeeded at least once, reopen."

## Platform notes for `-destination`

Only iOS was actually verified end-to-end in this debugging session
(2026-07-22, activehours/ios repo). macOS and watchOS should follow the same
overall procedure — xcode-build-server's log-parsing mechanism doesn't care
about platform — but the destination string differs and wasn't tested here:

- iOS Simulator: `-destination 'platform=iOS Simulator,name=iPhone 17'` (or
  `'generic/platform=iOS Simulator'`)
- iOS device (no signing needed just to produce build products for
  indexing): `-destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO`
- macOS: `-destination 'platform=macOS'`
- watchOS Simulator: `-destination 'platform=watchOS Simulator,name=<paired watch sim>'`
  — needs a paired watch simulator to exist, not just the runtime.

## If it's still broken after all this

Talk to sourcekit-lsp directly over its BSP stdio protocol to see the real
`sourceKitOptions` response (bypasses whatever nvim is or isn't displaying).
Minimal Python: spawn `/opt/homebrew/bin/xcode-build-server`, send
Content-Length-framed JSON-RPC `build/initialize` → `build/initialized` →
wait ~15s → `textDocument/sourceKitOptions` with
`target: {uri: "dummy://dummy"}` (this implementation always returns a
single dummy placeholder target from `workspace/buildTargets`, it does not
do real per-Xcode-target BSP modeling — don't waste time trying to discover
"the right" target URI). If the returned `compilerArguments` look wrong,
save them and run `xcrun swiftc -typecheck <args>` directly — if that comes
back clean, the build/config layer is fine and the bug is sourcekit-lsp's
integration/caching, not your project.
