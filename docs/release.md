# Release to TestFlight

This checklist is for the person who uploads a build. Do the steps in sequence. The app target is ready: the checks at the end show how to make sure.

## Before the first upload

### 1. App icon

App Store Connect rejects an upload that has no 1024 × 1024 pixel icon (512 pt @2x). The current `topway/Assets.xcassets/AppIcon.appiconset` has no such image, so the validation fails.

1. Make `AppIcon.icon` in Icon Composer.
2. Put `AppIcon.icon` in the `topway` folder. The folder is a synchronized group, so the file joins the target.
3. Delete `topway/Assets.xcassets/AppIcon.appiconset`.
4. In Xcode, select the `topway` target, then **General > App Icons and Launch Screen > App Icon**. Make sure that the value is `AppIcon`. This is the build setting `ASSETCATALOG_COMPILER_APPICON_NAME`.
5. Build the app and make sure that the icon shows.

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

The app declares the same in `topway/PrivacyInfo.xcprivacy`. The export compliance answer is in the build (`ITSAppUsesNonExemptEncryption` is `NO`), because Topway uses only HTTPS and secure WebSockets from the system.

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

   > Topway needs no account for review. On the first screen, select "Try with sample data". The app then shows sample projects, services, variables, deployments and logs, and it does not connect to a server. All features work on the sample data.

3. In **What to Test**, tell the testers to report problems from **Settings > Help** in the app.
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
