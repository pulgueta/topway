# Release to TestFlight

This checklist is for the person who uploads a build. Do the steps in sequence. The app target is ready: the checks at the end show how to make sure.

## Before the first upload

### 1. App icon

Done. The app icon is `topway/Appicon.icon`, made in Icon Composer. The build setting `ASSETCATALOG_COMPILER_APPICON_NAME` is `Appicon`. If you rename the file, change the setting to the same name (Xcode: **General > App Icons and Launch Screen > App Icon**).

Topway has no Dock icon (`LSUIElement`). The icon shows in Finder, in Apps, in the App Store and in notifications.

### 2. App record

1. Make sure that the Apple Developer account has the bundle ID `com.pulgueta.topway`.
2. In [App Store Connect](https://appstoreconnect.apple.com), select **Apps > + > New App**.
3. Set these values:

| Field | Value |
|---|---|
| Platform | macOS |
| Name | Topway |
| Primary language | English (U.S.) |
| Bundle ID | `com.pulgueta.topway` |
| SKU | `topway` |
| Category (App Information) | Developer Tools |

### 3. Privacy

1. In **App Information > Privacy Policy URL**, enter `https://github.com/pulgueta/topway/blob/main/PRIVACY.md`.
2. In **App Privacy**, select **Get Started**. Answer **No, we do not collect data from this app**. The result is **Data Not Collected**.

The app declares the same in `topway/PrivacyInfo.xcprivacy`. The export compliance answer is in the build (`ITSAppUsesNonExemptEncryption` is `NO`), because Topway uses only HTTPS and secure WebSockets from the system. The sign-in also calculates a SHA-256 hash (CryptoKit) for PKCE. It encrypts no data.

### 4. Accessibility

1. Do the manual checks in [accessibility.md](accessibility.md).
2. In App Store Connect, add the Accessibility Nutrition Labels for Mac that [accessibility.md](accessibility.md) recommends. Declare a label only when its check passes. Do not select Captions or Audio Descriptions. Apple gives the steps in [Manage Accessibility Nutrition Labels](https://developer.apple.com/help/app-store-connect/manage-app-accessibility/manage-accessibility-nutrition-labels).
3. For the accessibility URL, enter `https://github.com/pulgueta/topway/blob/main/docs/accessibility.md`.

### 5. Sign in with Railway

Users see the name of the Railway OAuth app on the Railway consent page. The development app is "Topway Development".

1. Before the App Store release, rename the OAuth app to "Topway", or make a production OAuth app with the name "Topway". Use the type **Native (Public)** and the redirect URI `topway://oauth/callback`. Railway shows each OAuth app in **Workspace settings > Developer**.
2. On the Mac that makes the archive, put the client ID of the production app in `Config/OAuth.local.xcconfig`. Never commit it.
3. After the archive, check that the app has a client ID. The command shows only the number of characters, and it must be more than 0:

   ```sh
   plutil -extract RailwayOAuthClientID raw \
     ~/Library/Developer/Xcode/Archives/*/topway*.xcarchive/Products/Applications/topway.app/Contents/Info.plist | tr -d '\n' | wc -c
   ```

   An archive with no client ID offers only sample data.

4. **Blocker for the App Store release (not for TestFlight):** change the callback from `topway://oauth/callback` to an HTTPS callback. Any app on the same Mac can use the `topway` scheme and the public client ID, so a malicious local app can show the real Topway consent page and get the tokens (RFC 8252, section 8.6). An HTTPS callback through Associated Domains goes only to an app with the Topway signing identity. It needs a domain with an `apple-app-site-association` file, the redirect URI `https://<domain>/oauth/callback` in Railway, the Associated Domains entitlement, and `ASWebAuthenticationSession.Callback.https(host:path:)`.

## For each upload

1. Increase `CURRENT_PROJECT_VERSION` (target **General > Identity > Build**). App Store Connect accepts each build number only one time for a version.
2. In Xcode, set the destination to **Any Mac**.
3. Select **Product > Archive**. The archive uses the Release configuration.
4. In the Organizer, select the archive, then **Distribute App > App Store Connect > Upload**. Let Xcode manage the signing.
5. Wait for the email that says that the build is ready. This can take some minutes.

## Testers

### Internal testers

1. In App Store Connect, select **TestFlight > Internal Testing > +** and make a group.
2. Add the testers. They must be users of the App Store Connect team.
3. Add the build to the group. Internal testers need no review.

### External testers

External testers need Beta App Review for the first build of each version.

1. Select **TestFlight > Test Information**. Enter the feedback email, the privacy policy URL and the beta app description.
2. In **Beta App Review Information**, clear **Sign-in required**. Enter these notes:

   > Topway needs no account for review. On the first screen, select "Try with sample data". The app then shows sample projects, services, variables, deployments and logs, and it does not connect to a server. All features work on the sample data. "Sign in with Railway" needs a Railway account, and the review does not need it.

3. In **What to Test**, tell the testers to report problems from **Settings > Help** in the app. Also tell them: select **Sign in with Railway**, and on the Railway consent page, select the workspaces for Topway. Topway removes the API token of an earlier build at launch. If you signed in with a different build of Topway, macOS can ask for permission to use the Keychain item. Select **Always Allow**. If you select **Deny**, Topway shows the start screen, and you must sign in again.
4. Make an external group, add the build and submit it for review.

## Checks

Do these checks before you archive:

```sh
swift test --package-path Packages/TopwayCore
swift format lint --recursive --strict topway Packages
xcodebuild -project topway.xcodeproj -scheme topway -configuration Release \
  CODE_SIGNING_ALLOWED=NO -derivedDataPath build archive -archivePath build/topway.xcarchive
```

Then make sure that the archive has the keys and the privacy manifest:

```sh
plutil -p build/topway.xcarchive/Products/Applications/topway.app/Contents/Info.plist \
  | grep -E "ITSAppUsesNonExemptEncryption|NSHumanReadableCopyright|LSApplicationCategoryType"
ls build/topway.xcarchive/Products/Applications/topway.app/Contents/Resources
```

`ITSAppUsesNonExemptEncryption` must be `false`, and `PrivacyInfo.xcprivacy` must be in `Resources`. The `build` folder is in `.gitignore`. Do not commit it.

## How testers report problems

Topway collects no data and has no crash reports of its own. Testers use **Settings > Help > Report a problem** or **Report a crash**, which open the issue forms on GitHub. The TestFlight feedback and crash data in App Store Connect are also available.
