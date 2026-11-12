# Contributing

Read `ARCHITECTURE.md` first. `AGENTS.md` lists the facts for automated tools. It tells you where the code goes.

## Report a problem

Use the issue forms: [open a new issue](https://github.com/pulgueta/topway/issues/new/choose) and select **Crash report**, **Bug report** or **Feature request**. The forms are in `.github/ISSUE_TEMPLATE`.

- Do not paste a Railway token, a Workspace ID or variable values. Issues are public.
- For a security problem, [send a private report](https://github.com/pulgueta/topway/security/advisories/new). Do not open a public issue.

## Requirements

- Xcode 26.2 or later.
- A Mac with macOS 26.2 or later.

## Build

Open `topway.xcodeproj` in Xcode and select the `topway` scheme. Or use this command:

```sh
xcodebuild -project topway.xcodeproj -scheme topway -configuration Debug CODE_SIGNING_ALLOWED=NO build
```

## Test

Tests are in `Packages/TopwayCore/Tests`. They use Swift Testing. Do not use Xcode to run them. Use this command:

```sh
swift test --package-path Packages/TopwayCore
```

Write a test that fails first. Then write the code that makes the test pass.

## Format

The rules are in `.swift-format`. Run these commands before you commit:

```sh
swift format --in-place --recursive topway Packages
swift format lint --recursive --strict topway Packages
```

## Code rules

- One type in each file. The file has the name of the type.
- Do not add third-party packages.
- Keep SwiftUI out of `TopwayCore`.
- Make a type `public` only if the app uses it.
- Send all user input through GraphQL `variables`.
- Do not use `@unchecked Sendable` or `nonisolated(unsafe)` to stop compiler errors.
- Write UI text and docs in ASD-STE100 Simplified Technical English. Use short sentences and active voice. Use a verb on each button, such as "Restart" or "Delete project".

## Commits

Use this format, with no body:

```
type(scope): brief description
```

The types are `feat`, `fix`, `refactor`, `chore`, `docs`, `style` and `test`. Each commit has one purpose and must build.

Example: `fix(core): report HTTP failures as typed errors`

## Release

[docs/release.md](docs/release.md) gives the steps to upload a build to TestFlight.
