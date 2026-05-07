# AGENTS.md

Repository-specific instructions for contributors and coding agents working in `sendbird-ios-distribution`.

## Project overview

This repository is Sendbird's **private CocoaPods spec source** for iOS. Consumers add it as a `source` in their `Podfile` and pull pods from it. The repo bundles two roles:

1. **CocoaPods spec repository** — versioned `*.podspec` files under `Specs/` that CocoaPods reads.
2. **Source distribution** — Swift sources (and one downloaded XCFramework) for the pods themselves under `Sources/`.

The repo additionally exposes a Swift Package (`Package.swift`) that publishes a *subset* of the pods (`SendbirdMarkdownUI`, `SendbirdNetworkImage`) as SwiftPM libraries.

Pods served from this repo:

| Pod | Type | License | Role |
|---|---|---|---|
| `SendbirdAIAgentMessenger` | Swift sources | Commercial | Public integration entrypoint for Delight AI Agent |
| `SendbirdAIAgentCore` | Vendored XCFramework (downloaded by `prepare_command`) | Commercial | Internal core; not integrated directly |
| `SendbirdMarkdownUI` | Swift + bundled `cmark-gfm` C sources | MIT (fork) | SwiftUI Markdown rendering |
| `SendbirdNetworkImage` | Swift sources | MIT (fork) | SwiftUI async image loading |
| `SendbirdSplash` | Swift sources | MIT (fork) | Swift syntax highlighting (module name `Splash`) |

## Repository layout

```
Sources/                                    # Source code + canonical podspec per pod
  MarkdownUI/
    SendbirdMarkdownUI.podspec              # Canonical (HEAD) podspec
    Sources/MarkdownUI/...                  # Swift sources
    ThirdParty/cmark-gfm{,-extensions}/...  # Vendored C sources
  NetworkImage/
    SendbirdNetworkImage.podspec
    Sources/NetworkImage/...
  Splash/
    SendbirdSplash.podspec
    Sources/Splash/...                      # Plus SplashHTMLGen, SplashImageGen, SplashMarkdown, SplashTokenizer
  SendbirdAIAgentCore/
    SendbirdAIAgentCore.podspec             # XCFramework spec — no source files in repo
    LICENSE, README.md
  SendbirdAIAgentMessenger/
    SendbirdAIAgentMessenger.podspec
    Sources/MainModule.swift                # Public-API entrypoint (re-exports SendbirdAIAgentCore)

Specs/                                      # CocoaPods spec mirror — what `pod install` reads
  <PodName>/<version>/<PodName>.podspec     # One file per published version

Package.swift                               # SwiftPM manifest (MarkdownUI + NetworkImage only)
```

`Sources/<Pod>/<Pod>.podspec` is the **HEAD/working** podspec for each pod. `Specs/<Pod>/<version>/<Pod>.podspec` is the **immutable, version-tagged copy** that CocoaPods clients resolve. Both must agree for the active version.

## Toolchain and platform requirements

- Swift: `5.7` (declared in every podspec and `Package.swift`).
- iOS deployment target: `14.0` (every pod). Consumer apps in the README use `platform :ios, '15.0'`.
- SwiftPM platforms: `iOS 14`, `macOS 12`, `tvOS 14`, `watchOS 7`, `macCatalyst 15` — applies only to `SendbirdMarkdownUI` and `SendbirdNetworkImage`. The other pods are iOS-only.
- CocoaPods is the primary distribution channel; there is no Xcode project or workspace at the repo root.

## Adding a new release

A release ships exactly one or more pods at a new version. The repeating pattern from history (`Release - X.Y.Z` merge commits on `main`) is:

1. Branch `release/<version>` from `main`.
2. Bump `s.version` in `Sources/<Pod>/<Pod>.podspec` for every pod that is changing.
3. If a dependency between pods is part of the bump, update the `s.dependency` lines too. The Messenger pod pins `SendbirdAIAgentCore` to an exact version (e.g. `'1.13.0'`), so every Core release implies a Messenger release.
4. Copy the bumped podspec into `Specs/<Pod>/<version>/<Pod>.podspec` (do not move — the canonical copy in `Sources/` must remain in sync).
5. Update README install snippets if the recommended version moved.
6. Open the release PR. Merge commits follow the form `Release - X.Y.Z` (see `git log`).
7. Tag each pod that was published using the form `<PodName>-v<version>` (e.g. `SendbirdAIAgentCore-v1.13.0`, `SendbirdAIAgentMessenger-v1.13.0`). The tag name is referenced by `s.source[:tag]` in every podspec, so a missing tag breaks `pod install` for that version.

Older `Specs/<Pod>/<version>/` directories are immutable history — never edit a published version's podspec in place. To fix a broken release, publish a new patch version.

## Cross-pod version coupling

These coupling rules are enforced by `s.dependency` lines, not by tooling — read them before changing any version:

- `SendbirdAIAgentMessenger` → `SendbirdAIAgentCore` is pinned **exactly** (`'1.13.0'`). Bump together.
- `SendbirdAIAgentMessenger` → `SendbirdMarkdownUI` is `~> 1.0.4`, `SendbirdSplash` is `'1.0.0'` exact, `SendbirdNetworkImage` is `'1.0.0'` exact. Bumping any of these requires re-evaluating the Messenger pin.
- `SendbirdMarkdownUI` → `SendbirdNetworkImage` is `~> 1.0`.
- `SendbirdAIAgentCore` depends on the **public CocoaPods trunk** pods `SendbirdUIMessageTemplate` (`>= 3.35.1, < 4.0`) and `SendbirdChatSDK` (`>= 4.39.2, < 5.0`). Releasing a new Core version means re-checking those ranges against current trunk releases.

## SendbirdAIAgentCore: XCFramework download

`SendbirdAIAgentCore` ships **no binary in this repo**. Its podspec uses `prepare_command` to download `SendbirdAIAgentCore.xcframework.zip` from `https://github.com/sendbird/delight-ai-agent-core-ios/releases/download/<version>/...` at `pod install` time and unpack it into `Sources/SendbirdAIAgentCore/SendbirdAIAgentCore.xcframework`. Implications:

- A `SendbirdAIAgentCore` release in this repo only works if the matching `<version>` GitHub release exists in `sendbird/delight-ai-agent-core-ios` with the correct asset name. Confirm the upstream release before bumping the spec.
- `s.ios.vendored_frameworks` points at the path that `prepare_command` produces; do not check the XCFramework into git.
- Consumer apps must keep `ENABLE_USER_SCRIPT_SANDBOXING = NO` (see the `post_install` block in the README) or the download script is killed by Xcode's sandbox.

## Public API surface

- `SendbirdAIAgentMessenger` is the only customer-facing integration point for the AI Agent. The repo contains a single Swift file (`Sources/SendbirdAIAgentMessenger/Sources/MainModule.swift`) that:
  - Imports `SendbirdAIAgentCore` with `@_spi(SendbirdInternal)` for the SPI surface.
  - Re-exports `SendbirdAIAgentCore` via `@_exported import` so consumers see Core's public types through the Messenger module.
  - Adds the public `AIAgentMessenger.initialize(appId:paramsBuilder:completionHandler:)` extension that wraps `baseInitialize`.
  - Treat changes here as **public API changes**: signatures, the `@_exported` re-export, and the `@_spi` import are all part of what consumers compile against.
- `SendbirdAIAgentCore` is documented in `Sources/SendbirdAIAgentCore/README.md` as an "internal dependency" — consumers should not depend on it directly. Internal SPI symbols flow through the `@_spi(SendbirdInternal)` import in Messenger.
- The MIT-forked pods (`MarkdownUI`, `NetworkImage`, `Splash`) are namespaced with `Sendbird*` pod names but keep the original module structure. `SendbirdSplash` deliberately exposes the upstream module name `Splash` (`s.module_name = 'Splash'`); changing it is a breaking change for consumers that import `Splash`.

## SwiftPM package

`Package.swift` exposes only `SendbirdMarkdownUI` and `SendbirdNetworkImage`. Notes that matter when editing it:

- `swift-tools-version:5.7`.
- Depends on the upstream `swift-cmark` Swift package (not the bundled `ThirdParty/cmark-gfm` C sources used by the CocoaPods build). The two builds resolve cmark differently — keep both in mind when changing MarkdownUI parser code.
- The `SendbirdMarkdownUI` SwiftPM target excludes `Documentation.docc` to avoid pulling DocC sources into the package build.
- `SendbirdAIAgentMessenger`, `SendbirdAIAgentCore`, and `SendbirdSplash` are intentionally **not** SwiftPM products. Do not add them without owner sign-off — Core is an XCFramework, Messenger depends on the trunk-only `SendbirdChatSDK`/`SendbirdUIMessageTemplate`, and Splash has not been validated for SwiftPM distribution.

## MarkdownUI build settings

`SendbirdMarkdownUI.podspec` carries non-default settings that exist for real reasons; do not strip them when editing:

- C headers under `ThirdParty/cmark-gfm{,-extensions}/**/*.h` are listed as `private_header_files` to avoid umbrella-header conflicts.
- `*.modulemap` files are kept via `preserve_paths`.
- `OTHER_CFLAGS` sets `-DCMARK_GFM_STATIC_DEFINE -DCMARK_THREADING`.
- `SWIFT_INCLUDE_PATHS` points at the cmark include dirs so Swift can see the C module.

## Consumer integration (canonical)

When updating README snippets or onboarding instructions, the canonical Podfile fragment is in `README.md` and looks like:

```ruby
source 'https://github.com/sendbird/sendbird-ios-distribution.git'
source 'https://cdn.cocoapods.org/'

platform :ios, '15.0'

target 'YourApp' do
  use_frameworks!
  pod 'SendbirdAIAgentMessenger', '>= 1.13.0'
end

post_install do |installer|
  project = installer.aggregate_targets[0].user_project
  project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
    end
  end
  project.save
end
```

`use_frameworks!` and the `ENABLE_USER_SCRIPT_SANDBOXING = NO` override are both required (the override is for the `prepare_command` script in `SendbirdAIAgentCore`).

## Local testing

- `TestPod/`, `BAK/`, and `LocalTest/Pods/`/`LocalTest/Podfile.lock`/`LocalTest/*.xcworkspace` are gitignored and intended for local consumer-style smoke tests. `LocalTest/*.xcworkspace/contents.xcworkspacedata` is allow-listed so a workspace skeleton can still be committed.
- `pod lib lint Sources/<Pod>/<Pod>.podspec` validates a podspec against external sources; `--sources='https://github.com/sendbird/sendbird-ios-distribution.git,https://cdn.cocoapods.org/'` is required to resolve sibling private pods. **Unverified** — confirm against your local CocoaPods version before relying on it in CI.
- There is no test target in this repo. Validation is done by linting podspecs, building consumer apps against the bumped pods, and (for AIAgentCore) confirming the upstream XCFramework release exists.

## PR and commit conventions

From `git log`:

- Release commits on `main` use the literal subject `Release - X.Y.Z` and originate from `release/X.Y.Z` branches via merge PRs.
- Other commits use either `[TYPE] description` (e.g. `[MOD] modified dependency setting info`, `[MOD] Rebranding`) or Conventional-Commit style (`feat(...)`, `chore: ...`). Match whichever style adjacent commits use; do not normalize old history.
- Rollbacks are explicit (`rollback`, `rollback 1.9.0`) and re-cut the version from a clean point — do not amend or force-push a published release.

## Known gotchas

- **Two podspec copies per release.** Editing only the `Sources/<Pod>/<Pod>.podspec` does not change what consumers resolve. Always update the matching `Specs/<Pod>/<version>/<Pod>.podspec` and tag.
- **Tag naming is enforced by `s.source[:tag]`.** Use `<PodName>-v<version>`, not bare `vX.Y.Z`. Mistyped tags silently break `pod install`.
- **Messenger ↔ Core lockstep.** Because Messenger pins Core exactly, you cannot ship a Core-only fix without a Messenger release.
- **Trunk dependency drift.** AIAgentCore's `SendbirdChatSDK` / `SendbirdUIMessageTemplate` ranges must stay compatible with what's on CocoaPods trunk; bumping Core without re-checking can ship a podspec that fails to resolve.
- **XCFramework asset must exist upstream.** The `prepare_command` URL is constructed from `s.version`; if the matching release in `sendbird/delight-ai-agent-core-ios` is missing or has the wrong asset name, `pod install` fails after the spec is published.
- **`9.0` was rolled back.** History shows a `Release - 1.9.0` followed by a `rollback 1.9.0` commit and a re-cut `Release - 1.9.0`. Treat published versions as immutable and prefer a new patch over editing in place.
- **`SendbirdSplash`'s module name is `Splash`, not `SendbirdSplash`.** Consumers `import Splash`. Renaming the module is a breaking change.
- **Two cmark sources of truth.** CocoaPods builds MarkdownUI against the vendored C sources in `Sources/MarkdownUI/ThirdParty/`; SwiftPM builds it against `swiftlang/swift-cmark`. Behavior changes that depend on cmark internals must be tested in both build paths.

## Where to find things

- Canonical podspecs (HEAD): `Sources/<Pod>/<Pod>.podspec`
- Versioned podspecs (what consumers read): `Specs/<Pod>/<version>/<Pod>.podspec`
- Public Messenger entrypoint: `Sources/SendbirdAIAgentMessenger/Sources/MainModule.swift`
- Consumer-facing README and Podfile template: `README.md`
- Per-pod commercial/MIT licenses: `Sources/<Pod>/LICENSE` (Core, Messenger) and the OSS-fork sources for the rest
- Upstream XCFramework releases: `https://github.com/sendbird/delight-ai-agent-core-ios/releases`
