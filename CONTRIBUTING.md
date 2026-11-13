# Contributing

Thank you for your help with Topway. Read [ARCHITECTURE.md](ARCHITECTURE.md) first: it tells you where the code goes. Read [DESIGN.md](DESIGN.md) before you change a screen. [AGENTS.md](AGENTS.md) has the rules that keep the app working.

## Requirements

- A Mac with macOS 26.2 or later
- Xcode 26.2 or later

## Build

Open `topway.xcodeproj` and run the `topway` scheme, or use this command:

```sh
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

To sign in from your build, follow [Build from source](README.md#build-from-source). To sign it with your own team, follow [Build and own Topway](docs/own-your-build.md).

## Test

The tests are in `Packages/TopwayCore/Tests` and use Swift Testing. Run them with this command, not in Xcode:

```sh
swift test --package-path Packages/TopwayCore
```

Write a test that fails first. Then write the code that makes it pass.

## Format

The rules are in `.swift-format`. Run these commands before you commit:

```sh
swift format --in-place --recursive topway Packages
swift format lint --recursive --strict topway Packages
```

## Code rules

- Put one type in each file, with the name of the type.
- Do not add third-party packages.
- Keep SwiftUI out of `TopwayCore`.
- Make a type `public` only if the app uses it.
- Send all user input through GraphQL `variables`.
- Do not use `@unchecked Sendable` or `nonisolated(unsafe)` to stop compiler errors.
- Write UI text and docs in ASD-STE100 Simplified Technical English: short sentences and active voice. Start each button label with a verb, such as "Restart" or "Delete project".

## Commits

Use `type(scope): brief description`, with no body. The types are `feat`, `fix`, `refactor`, `chore`, `docs`, `style` and `test`. Each commit has one purpose and must build. For example: `fix(core): report HTTP failures as typed errors`.

## Report a problem

Use the [issue forms](https://github.com/pulgueta/topway/issues/new/choose). Issues are public, so do not paste a Railway token, a Workspace ID or variable values. For a security problem, [send a private report](https://github.com/pulgueta/topway/security/advisories/new).
