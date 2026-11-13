# Build and own Topway

This guide is for you if you want to build Topway from source and own your copy fully. When you finish, your build uses your Apple team, your bundle ID, your Railway OAuth app and your own sign-in callback. It does not depend on the author's domain (`topway.pulgueta.com`), team (`7QNFW3929Z`) or bundle ID (`com.pulgueta.topway`).

Topway is open source under the [MIT license](../LICENSE), so you can do this at no cost. It takes more steps than the short build in the [README](../README.md#build-from-source), because the sign-in callback must belong to you.

## Choose how the sign-in comes back

After you sign in on the Railway page, Railway sends you back to the app at a callback address. Today that address is on the author's domain, and only an app that the author's team signs can get it. Choose one of these options to replace it:

|                | Option A: your own HTTPS domain                                    | Option B: a custom URL scheme                     |
| -------------- | ------------------------------------------------------------------ | ------------------------------------------------- |
| Callback       | `https://topway.example.com/oauth/callback`                        | `com.example.topway://oauth/callback`             |
| You need       | A domain with HTTPS and a paid Apple Developer Program membership  | A free Apple Account                              |
| Who can get it | Only an app that your team signs                                   | Another app on the Mac can claim the same scheme  |
| Good for       | A build that other people use                                      | A build for you only                              |

We recommend option A. Option B needs no domain and fewer steps, and it is fine for a personal build.

## What you need

- A Mac with macOS 26.2 or later.
- Xcode 26.2 or later, signed in with your Apple Account (**Xcode > Settings**).
- A Railway account that is an admin of a workspace. Only an admin can make an OAuth app.
- For option B: the free Personal Team of your Apple Account is enough.
- For option A: a paid [Apple Developer Program](https://developer.apple.com/programs/) membership, and a domain where you can serve a file over HTTPS. Option A uses Associated Domains, which a free account cannot use. See Apple's [supported capabilities for macOS](https://developer.apple.com/help/account/reference/supported-capabilities-macos).

The examples use these placeholders. Replace them with your values:

| Placeholder          | Your value                                                                        |
| -------------------- | --------------------------------------------------------------------------------- |
| `ABCDE12345`         | Your Team ID. [Step 1](#1-use-your-own-team-and-bundle-id) tells where to find it. |
| `com.example.topway` | Your bundle ID. Use a reverse domain name that you own or that is unique to you.  |
| `topway.example.com` | Your domain (option A only).                                                      |

## The files that you change

| File                                                               | Option A               | Option B                          |
| ------------------------------------------------------------------ | ---------------------- | --------------------------------- |
| `topway.xcodeproj/project.pbxproj`                                 | Team and bundle ID     | Team and bundle ID                |
| `Config/OAuth.local.xcconfig` (new; never commit it)               | Client ID              | Client ID                         |
| `Packages/TopwayCore/Sources/TopwayCore/OAuth/RailwayOAuth.swift`  | Callback host          | Callback scheme                   |
| `topway/SignIn/WebSignIn.swift`                                    | No change              | Session callback                  |
| `topway/topway.entitlements`                                       | Your domain            | Remove Associated Domains         |
| 3 test files in `Packages/TopwayCore/Tests/TopwayCoreTests`        | Expected callback URL  | Expected callback URL             |
| `/.well-known/apple-app-site-association` on your domain          | New file               | Not used                          |

Some comments in `RailwayOAuth.swift`, `AuthorizationCallback.swift` and `WebSignIn.swift` still name `topway.pulgueta.com`. They do not change the build. Update them when you like.

## 1. Use your own team and bundle ID

1. Open `topway.xcodeproj` in Xcode.
2. Select the **topway** project, then the **topway** target, then **Signing & Capabilities**.
3. For **Team**, select your team.
4. For **Bundle Identifier**, type your bundle ID, for example `com.example.topway`.

Xcode writes these values for the target into `topway.xcodeproj/project.pbxproj`. To see your Team ID, read `DEVELOPMENT_TEAM` in that file, or open the Membership page of your Apple Developer account.

The project level of the file still names the author's team. To change all of the values at once, run this command from the root of the repository:

```sh
sed -i '' -e 's/7QNFW3929Z/ABCDE12345/g' -e 's/com\.pulgueta\.topway/com.example.topway/g' \
  topway.xcodeproj/project.pbxproj
```

This command must print nothing:

```sh
git grep -n -e 7QNFW3929Z -e com.pulgueta.topway -- topway.xcodeproj
```

If you use a Personal Team (option B), Xcode shows a signing error about Associated Domains until you remove that entitlement in [option B](#option-b-a-custom-url-scheme). This is expected.

### Change the display name (optional)

To give the app a different name, change `INFOPLIST_KEY_CFBundleDisplayName = Topway;` in `topway.xcodeproj/project.pbxproj`. It is in 2 places, for Debug and Release. You can also change it in Xcode, in the **General** tab of the target. The text in the app still says "Topway".

### What follows the bundle ID

These items read the bundle ID when the app runs. You do not edit them, but they change with your bundle ID:

- `Packages/TopwayCore/Sources/TopwayCore/Storage/KeychainStore.swift`: the Keychain service is `Bundle.main.bundleIdentifier`. Your build does not see the sign-in of another build, so you sign in one time. The fallback `"com.pulgueta.topway"` is for code that runs with no bundle ID. The app always has one.
- `topway/Settings/AlertsSettingsSection.swift`: **Open System Settings** opens the notification settings for the current bundle ID.
- Settings in `UserDefaults.standard`: Topway uses no suite name, so macOS keeps them in a file named for your bundle ID, for example `~/Library/Containers/com.example.topway/Data/Library/Preferences/com.example.topway.plist`.
- The `apple-app-site-association` file of option A names `ABCDE12345.com.example.topway`.

No logger subsystem, app group or URL type uses the bundle ID. Your build and the App Store build can stay on the same Mac. Each one keeps its own sign-in and settings.

### Send problem reports to your fork (optional)

**Settings > Help > Report a problem** opens an issue form in the author's repository. To use your fork, change the path in 2 files. Your fork must keep the forms in `.github/ISSUE_TEMPLATE`.

`Packages/TopwayCore/Sources/TopwayCore/Reports/IssueReportLink.swift`:

```diff
         components.host = "github.com"
-        components.path = "/pulgueta/topway/issues/new"
+        components.path = "/your-github-user/topway/issues/new"
```

`Packages/TopwayCore/Tests/TopwayCoreTests/IssueReportLinkTests.swift`:

```diff
         #expect(url.host() == "github.com")
-        #expect(url.path() == "/pulgueta/topway/issues/new")
+        #expect(url.path() == "/your-github-user/topway/issues/new")
```

## 2. Make your Railway OAuth app

1. In Railway, open the settings of your workspace, then **Developer > New OAuth App**.
2. For the type, select **Native (Public)**. A native app has no client secret, and Topway sends none.
3. Add one redirect URI. It must be the same text as `RailwayOAuth.redirectURI` after your edit:
   - Option A: `https://topway.example.com/oauth/callback`
   - Option B: `com.example.topway://oauth/callback`
4. Do not add other redirect URIs. With option A, an extra custom-scheme URI brings back the risk that option A removes.
5. Copy the client ID.
6. Make the file `Config/OAuth.local.xcconfig` with this line:

   ```text
   RAILWAY_OAUTH_CLIENT_ID = your_client_id
   ```

Git ignores `Config/OAuth.local.xcconfig`. Never commit it, and never put the client ID in `Config/OAuth.xcconfig`.

## 3. Set the callback

Do option A or option B, not both.

### Option A: your own HTTPS domain

With Associated Domains, macOS gives the HTTPS callback only to the app that your `apple-app-site-association` file names. This is how the App Store build works.

1. On your domain, serve this file at `https://topway.example.com/.well-known/apple-app-site-association`, with no file extension:

   ```json
   {
     "webcredentials": {
       "apps": ["ABCDE12345.com.example.topway"]
     }
   }
   ```

   The server must send it over HTTPS with a valid certificate, with status 200, as `application/json`, and with no redirect.

2. Check the file:

   ```sh
   curl -I https://topway.example.com/.well-known/apple-app-site-association
   ```

   The answer must show status `200` and `content-type: application/json`, and no `location` header.

   macOS gets the file from the content delivery network (CDN) of Apple, not from your server. Apple can take up to 24 hours to get a new or changed file. To see the copy that Apple has, run this command:

   ```sh
   curl https://app-site-association.cdn-apple.com/a/v1/topway.example.com
   ```

3. Change the host in `Packages/TopwayCore/Sources/TopwayCore/OAuth/RailwayOAuth.swift`. You can keep `callbackPath`. If you change it, use the same path in the redirect URI on Railway.

   ```diff
   -    public static let callbackHost = "topway.pulgueta.com"
   +    public static let callbackHost = "topway.example.com"
        public static let callbackPath = "/oauth/callback"
   ```

4. Change the domain in `topway/topway.entitlements`:

   ```diff
    	<array>
   -		<string>webcredentials:topway.pulgueta.com</string>
   +		<string>webcredentials:topway.example.com</string>
    	</array>
   ```

5. Turn on Associated Domains for your App ID. In Xcode, open **Signing & Capabilities** and make sure that **Associated Domains** shows `webcredentials:topway.example.com`. If it is not there, select **+ Capability**, add **Associated Domains**, then add that domain. With automatic signing, Xcode turns on the capability for your App ID. If you sign manually, turn it on for the App ID in **Certificates, Identifiers & Profiles** on the Apple Developer website.

6. Change the expected callback in the tests. This command changes the host in the 3 test files:

   ```sh
   sed -i '' 's/topway\.pulgueta\.com/topway.example.com/g' \
     Packages/TopwayCore/Tests/TopwayCoreTests/AuthorizationCallbackTests.swift \
     Packages/TopwayCore/Tests/TopwayCoreTests/AuthorizationRequestTests.swift \
     Packages/TopwayCore/Tests/TopwayCoreTests/RailwayOAuthClientTests.swift
   ```

   For example, in `AuthorizationRequestTests.swift`:

   ```diff
   -        #expect(items["redirect_uri"] == "https://topway.pulgueta.com/oauth/callback")
   +        #expect(items["redirect_uri"] == "https://topway.example.com/oauth/callback")
   ```

   The tests that check other addresses, such as `https://topway.example.com.evil.example`, then use your host too.

### Option B: a custom URL scheme

With a custom scheme, you need no domain and no paid membership. But a custom scheme does not belong to one app: another app on the same Mac can claim the same scheme.

Two things limit the harm. `ASWebAuthenticationSession` watches for the redirect itself, and PKCE (Proof Key for Code Exchange) makes a stolen code useless without the code verifier, a one-time secret that only your app has. This is fine for a build that only you use. Do not give a build with option B to other people; use option A for that.

Use a scheme that is unique to you, such as your bundle ID in lowercase: `com.example.topway`. Another app is more likely to use a short scheme such as `topway`. A reverse domain name is the form that [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252#section-7.1) recommends. Also, one test makes sure that `topway://` fails, so the scheme `topway` breaks that test.

1. Change the callback in `Packages/TopwayCore/Sources/TopwayCore/OAuth/RailwayOAuth.swift`:

   ```diff
   -    /// `ASWebAuthenticationSession` gets the redirect to this HTTPS host and path. The
   -    /// Associated Domains entitlement has `webcredentials:topway.pulgueta.com`, and the
   -    /// `apple-app-site-association` file of the host names only the app of team 7QNFW3929Z.
   -    /// Thus only an app with the Topway signature gets the redirect (RFC 8252, section 8.6).
   -    public static let callbackHost = "topway.pulgueta.com"
   -    public static let callbackPath = "/oauth/callback"
   +    /// `ASWebAuthenticationSession` gets the redirect to this custom scheme.
   +    public static let callbackScheme = "com.example.topway"
        /// Must be the same text as a redirect URI of the OAuth app on Railway.
   -    public static let redirectURI = "https://\(callbackHost)\(callbackPath)"
   +    public static let redirectURI = "\(callbackScheme)://oauth/callback"
   ```

2. Change the session callback in `topway/SignIn/WebSignIn.swift`:

   ```diff
                let session = ASWebAuthenticationSession(
   -                url: url,
   -                callback: .https(host: RailwayOAuth.callbackHost, path: RailwayOAuth.callbackPath)
   +                url: url, callback: .customScheme(RailwayOAuth.callbackScheme)
                ) { @Sendable callbackURL, error in
   ```

   `ASWebAuthenticationSession` gets the redirect itself. You do not register the scheme in `Info.plist`.

3. Do not change `Packages/TopwayCore/Sources/TopwayCore/OAuth/AuthorizationCallback.swift`. It compares the callback with `RailwayOAuth.redirectURI`, so it accepts your new address and still refuses all others.

4. Remove Associated Domains from `topway/topway.entitlements`:

   ```diff
    <dict>
   -	<key>com.apple.developer.associated-domains</key>
   -	<array>
   -		<string>webcredentials:topway.pulgueta.com</string>
   -	</array>
    	<key>com.apple.security.app-sandbox</key>
   ```

5. Change the expected callback in the tests. This command changes the full callback address in the 3 test files:

   ```sh
   sed -i '' 's|https://topway\.pulgueta\.com/oauth/callback|com.example.topway://oauth/callback|g' \
     Packages/TopwayCore/Tests/TopwayCoreTests/AuthorizationCallbackTests.swift \
     Packages/TopwayCore/Tests/TopwayCoreTests/AuthorizationRequestTests.swift \
     Packages/TopwayCore/Tests/TopwayCoreTests/RailwayOAuthClientTests.swift
   ```

   For example, in `AuthorizationCallbackTests.swift`:

   ```diff
   -        let callback = try url("https://topway.pulgueta.com/oauth/callback?code=abc123&state=s1")
   +        let callback = try url("com.example.topway://oauth/callback?code=abc123&state=s1")
   ```

   Without this step, these tests fail: in `AuthorizationCallbackTests`, "A callback with the same state gives the code", "A callback with no issuer gives the code", "A user who does not give access gets the denied error" and "Another error keeps the description of Railway"; in `AuthorizationRequestTests`, "The URL asks for a code with PKCE S256, the state and the redirect URI"; and "The code exchange sends the code and the verifier, with no secret" in `RailwayOAuthClientTests`.

## 4. Build and check

1. Run the tests:

   ```sh
   swift test --package-path Packages/TopwayCore
   ```

2. In Xcode, select **Product > Run**.
3. Click the Topway icon in the menu bar, then select **Sign in with Railway**.
4. Sign in on the Railway page, then select the workspaces that Topway can use.
5. Make sure that Topway shows your projects.

### If something does not work

- **Railway shows an error about the redirect URI.** The redirect URI in your Railway OAuth app must be the same text as `RailwayOAuth.redirectURI`: the same scheme, host and path, with no slash at the end.
- **Option A: the sign-in window does not come back to Topway.** macOS does not have your `apple-app-site-association` file yet. Check the file with the two `curl` commands in option A, and wait up to 24 hours for the CDN of Apple.

  A copy of the app with the same bundle ID and no signature can also hide your signed copy. A build with `CODE_SIGNING_ALLOWED=NO` makes such a copy. List the copies that macOS knows, remove the unsigned ones, then register the signed one again:

  ```sh
  LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
  "$LSREGISTER" -dump | awk '/^path:/{p=$0} /^identifier:.*com\.example\.topway$/{print p}'
  "$LSREGISTER" -u /path/to/unsigned/topway.app
  "$LSREGISTER" -f /path/to/signed/topway.app
  ```

- **Topway offers only sample data.** The build has no client ID. Check that `Config/OAuth.local.xcconfig` has the line `RAILWAY_OAUTH_CLIENT_ID = your_client_id`, then select **Product > Clean Build Folder** and build again.
- **Option B: Xcode shows a signing error about Associated Domains.** The entitlement is still in `topway/topway.entitlements`. Do step 4 of option B.

## 5. Keep your fork up to date

Your changes are in a small set of files:

- `topway.xcodeproj/project.pbxproj`
- `Packages/TopwayCore/Sources/TopwayCore/OAuth/RailwayOAuth.swift`
- `topway/topway.entitlements`
- `topway/SignIn/WebSignIn.swift` (option B)
- `AuthorizationCallbackTests.swift`, `AuthorizationRequestTests.swift` and `RailwayOAuthClientTests.swift` in `Packages/TopwayCore/Tests/TopwayCoreTests`
- `IssueReportLink.swift` and `IssueReportLinkTests.swift`, if you changed the report link

`Config/OAuth.local.xcconfig` stays on your Mac only.

Tip: keep all of these changes in one commit. Then put that commit on top of each new version:

```sh
git remote add upstream https://github.com/pulgueta/topway.git
git fetch upstream
git rebase upstream/main
```

If the rebase stops with a conflict in `project.pbxproj`, take the upstream version of the file, run the `sed` command from [step 1](#1-use-your-own-team-and-bundle-id) again, then continue:

```sh
git checkout --ours topway.xcodeproj/project.pbxproj
sed -i '' -e 's/7QNFW3929Z/ABCDE12345/g' -e 's/com\.pulgueta\.topway/com.example.topway/g' \
  topway.xcodeproj/project.pbxproj
git add topway.xcodeproj/project.pbxproj
git rebase --continue
```

In a rebase, `--ours` is the upstream side. If you changed the display name, change it again before `git add`.

## License

Topway uses the [MIT license](../LICENSE). You can use, change, publish and sell your copy. Keep the copyright notice and the permission notice of the `LICENSE` file in all copies or substantial portions of the software.

The license does not make you remove the author's name or the app icon. Change them only if you want to. The icon is `topway/Appicon.icon`. The copyright line of the app is `INFOPLIST_KEY_NSHumanReadableCopyright` in `topway.xcodeproj/project.pbxproj`.
