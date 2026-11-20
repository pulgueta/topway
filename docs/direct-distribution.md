# Release the direct build

This guide is for the owner of Topway. It tells you how to set up and make a release of the direct build: a notarized disk image (DMG) that users buy through Polar, with free updates from Sparkle. First do the one-time setup: the [Apple items](#one-time-setup-in-apple-developer), the [Sparkle keys](#make-the-sparkle-keys), the [GitHub secrets](#add-the-github-secrets) and the [Polar product](#sell-the-dmg-with-polar). Then each release is a version change, a tag and an upload to Polar.

## What the direct channel is

The direct channel is a second way to get Topway, next to the Mac App Store. It needs no App Review.

|                    | Mac App Store      | Direct                                                       |
| ------------------ | ------------------ | ------------------------------------------------------------ |
| Scheme             | `topway`           | `topway-direct`                                              |
| Signature          | Apple Distribution | Developer ID Application, notarized by Apple                 |
| Purchase           | The App Store      | Polar sells the DMG. The updates are free.                   |
| Download           | The App Store      | Polar, and the GitHub releases, for example `Topway-0.2.dmg` |
| Updates            | The App Store      | Sparkle 2 reads `https://topway.pulgueta.com/appcast.xml`    |
| Sparkle in the app | No                 | Yes                                                          |

Both channels use the bundle ID `com.pulgueta.topway`, the team `7QNFW3929Z`, the same OAuth client ID and the same sign-in callback.

The App Store build must not have update code (App Review Guideline 2.4.5). [`scripts/check-app-store-build.sh`](../scripts/check-app-store-build.sh) archives the App Store build and fails if it has Sparkle. CI runs it on each pull request.

Two files make a release:

- [`scripts/release-direct.sh`](../scripts/release-direct.sh) archives, signs, notarizes and packs the app, then adds it to the appcast.
- [`.github/workflows/release-direct.yml`](../.github/workflows/release-direct.yml) runs the script when you push a version tag. Then it makes the GitHub release and a pull request for the appcast.

## One-time setup in Apple Developer

You need three items from Apple. Each one has a different job:

- **Developer ID Application certificate**: signs the app and the DMG. By default, Gatekeeper opens only apps with this signature or an App Store signature.
- **Developer ID provisioning profile**: gives the app its Associated Domains entitlement and its application identifier. The sign-in callback needs the first one. The Keychain access group of the sign-in needs the second one.
- **App Store Connect API key**: lets `notarytool` send the app and the DMG to the Apple notary service with no Apple Account password.

### Export the Developer ID Application certificate

The certificate already exists. You made it on 2026-11-19, and it is in your login keychain. GitHub Actions needs a copy of it with its private key, in a `.p12` file.

1. Open Keychain Access.
2. Select the **login** keychain, then **My Certificates**.
3. Find **Developer ID Application: … (7QNFW3929Z)**. Expand it to make sure that it has a private key.
4. Right-click the certificate, then select **Export**.
5. For the file format, select **Personal Information Exchange (.p12)**. Save the file outside the repository, for example as `~/DeveloperID.p12`.
6. Type a strong password for the file.

Keep the `.p12` file and its password in your password manager. If you lose them, you must make a new certificate.

### Make the Developer ID provisioning profile

Xcode made a profile for you, **Mac Team Direct Provisioning Profile: com.pulgueta.topway**. Xcode manages that profile, so the release script cannot use it. Manual signing stops with this error:

```text
Provisioning profile "Mac Team Direct Provisioning Profile: com.pulgueta.topway" is Xcode managed, but signing settings require a manually managed profile.
```

Make a manual profile instead:

1. Open [Certificates, Identifiers & Profiles](https://developer.apple.com/account/resources/identifiers/list) in your Apple Developer account.
2. Open the identifier `com.pulgueta.topway`. Make sure that **Associated Domains** is on. The App Store build uses it too, so it is usually on.
3. Go to **Profiles** and add a profile.
4. Under **Distribution**, select **Developer ID**, then **Continue**.
5. Select the App ID `com.pulgueta.topway`.
6. Select the Developer ID Application certificate.
7. For the name, type `Topway Developer ID`. The script uses this name. If you use a different name, set `DEVELOPER_ID_PROFILE_NAME` when you run the script on your Mac.
8. Select **Generate**, then **Download**.

To use the profile on your Mac, copy it to the profiles folder of Xcode, with its UUID as the file name:

```sh
profile=~/Downloads/Topway_Developer_ID.provisionprofile
uuid=$(security cms -D -i "$profile" | plutil -extract UUID raw -o - -)
cp "$profile" ~/Library/Developer/Xcode/UserData/Provisioning\ Profiles/"$uuid".provisionprofile
```

When you renew the certificate, make a new profile with the new certificate. Then, before the next tag, update these secrets together. The commands are in [Add the GitHub secrets](#add-the-github-secrets).

- `DEVELOPER_ID_CERT_P12_BASE64`: a new `.p12` file of the new certificate with its private key. [Export the Developer ID Application certificate](#export-the-developer-id-application-certificate) tells how to make it.
- `DEVELOPER_ID_CERT_PASSWORD`, if the password of the `.p12` file changed.
- `DEVELOPER_ID_PROFILE_BASE64`.

If you update only the profile, the runner imports the earlier certificate, and it cannot sign with the certificate that the new profile names.

### Make an App Store Connect API key for notarization

1. In [App Store Connect](https://appstoreconnect.apple.com/access/integrations/api), open **Users and Access > Integrations > App Store Connect API**.
2. Under **Team Keys**, generate a key. Name it `Topway notarization`.
3. For the access, select **Developer**. Notarization needs no higher role.
4. Download the `.p8` file. App Store Connect lets you download it one time only.
5. Write down the **Key ID** of the key and the **Issuer ID** at the top of the page.

To notarize from your Mac, keep the key in a notarytool keychain profile. Replace `your_key_id` and `your_issuer_id` with your values:

```sh
xcrun notarytool store-credentials topway-notary \
  --key ~/AuthKey_your_key_id.p8 --key-id your_key_id --issuer your_issuer_id
```

## Make the Sparkle keys

Sparkle installs an update only when the EdDSA signature of the DMG agrees with the public key in the installed app (`SUPublicEDKey`). The script signs each DMG with the private key. Do these steps one time.

1. Get the Sparkle tools. The release script uses the same folder:

   ```sh
   xcodebuild -resolvePackageDependencies -project topway.xcodeproj -scheme topway-direct \
     -clonedSourcePackagesDirPath build/SourcePackages
   ```

   The tools are in `build/SourcePackages/artifacts/sparkle/Sparkle/bin`. Git ignores `build/`.

2. Make the keys:

   ```sh
   build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys
   ```

   `generate_keys` saves the private key in your login keychain and prints the public key. If macOS asks for access to the keychain, allow it.

3. Put the public key in [`Config/Direct.xcconfig`](../Config/Direct.xcconfig), then commit the file. A public key is safe to commit.

   ```text
   SPARKLE_PUBLIC_ED_KEY = your_public_key
   ```

4. Export the private key to a file outside the repository. You need this file for the GitHub secret and for a release from your Mac:

   ```sh
   build/SourcePackages/artifacts/sparkle/Sparkle/bin/generate_keys -x ~/sparkle_private_key
   ```

Keep a backup of the private key in two safe places, for example your password manager and an encrypted drive. **If you lose the private key, the users of the direct build cannot get updates.** They must download a new DMG by hand. Never commit the private key.

While `SPARKLE_PUBLIC_ED_KEY` is empty, the direct build does not check for updates, and the release script stops.

## Add the GitHub secrets

The workflow reads these repository secrets. It writes the certificate, the profile and the keys to files in the temporary folder of the runner, and the client ID to `Config/OAuth.local.xcconfig`. At the end, also after a failure, it deletes these files and the temporary keychain.

| Secret                         | What it holds                                                          |
| ------------------------------ | ---------------------------------------------------------------------- |
| `DEVELOPER_ID_CERT_P12_BASE64` | The `.p12` file of the Developer ID Application certificate, in base64 |
| `DEVELOPER_ID_CERT_PASSWORD`   | The password of the `.p12` file                                        |
| `DEVELOPER_ID_PROFILE_BASE64`  | The `Topway Developer ID` profile, in base64                           |
| `RAILWAY_OAUTH_CLIENT_ID`      | The client ID of the Railway OAuth app                                 |
| `NOTARY_KEY_P8_BASE64`         | The `.p8` file of the App Store Connect API key, in base64             |
| `NOTARY_KEY_ID`                | The Key ID of the API key                                              |
| `NOTARY_ISSUER_ID`             | The Issuer ID of the API key                                           |
| `SPARKLE_PRIVATE_ED_KEY`       | The text of the file from `generate_keys -x`                           |

To set them with the GitHub CLI, run these commands from the repository. The values go from the files to GitHub, and they do not show on the screen. For a command with no input file, `gh` asks you to paste the value.

```sh
base64 -i ~/DeveloperID.p12 | gh secret set DEVELOPER_ID_CERT_P12_BASE64
gh secret set DEVELOPER_ID_CERT_PASSWORD
base64 -i ~/Downloads/Topway_Developer_ID.provisionprofile | gh secret set DEVELOPER_ID_PROFILE_BASE64
sed -n 's/^RAILWAY_OAUTH_CLIENT_ID *= *//p' Config/OAuth.local.xcconfig | gh secret set RAILWAY_OAUTH_CLIENT_ID
base64 -i ~/AuthKey_your_key_id.p8 | gh secret set NOTARY_KEY_P8_BASE64
gh secret set NOTARY_KEY_ID
gh secret set NOTARY_ISSUER_ID
gh secret set SPARKLE_PRIVATE_ED_KEY < ~/sparkle_private_key
```

Then let the workflow open pull requests. In the repository on GitHub, go to **Settings > Actions > General**. Under **Workflow permissions**, select **Allow GitHub Actions to create and approve pull requests**.

After you set the secrets, delete `~/DeveloperID.p12`, the `.p8` file and `~/sparkle_private_key` from your Mac. Keep the copies in your password manager.

## Sell the DMG with Polar

[Polar](https://polar.sh) sells the DMG for you. Polar is the [Merchant of Record](https://polar.sh/docs/merchant-of-record/introduction): it processes the payment and is responsible for the international sales tax. A **File Downloads** benefit gives the DMG to the buyer. For the fees, see [Polar's pricing page](https://polar.sh/resources/pricing).

After the payment, the Polar confirmation page shows the download. Polar also sends an order confirmation email with a link to its Customer Portal, where the buyer can download the DMG again.

The DMG in each GitHub release stays public. Sparkle needs a public URL to download the updates, because the app has no license check and no Polar sign-in. So anyone who finds the release can download the DMG without Polar. This is the expected result, because Topway is MIT licensed and the updates are free.

### Make the product and the checkout link

Do these steps one time, after the first release has its DMG.

1. In the Polar dashboard, go to **Products** and make a product with the name `Topway`. For the billing cycle, select **One-time purchase**. For the pricing, select **Fixed price** and type the price. You cannot change the billing cycle or the pricing type later. You can change the amount.
2. Go to **Benefits** and select **+ Add Benefit**. For the **Type**, select **File Downloads**. Polar saves the benefit only when it has one file, so upload the DMG of the newest release in this form. Do steps 1 to 4 of [Upload the DMG of a release](#upload-the-dmg-of-a-release) for it. Then save the benefit, and add it to the `Topway` product.
3. Go to **Checkout Links**, select **New Link**, and select the `Topway` product. Then set these fields:
   - Leave **Success URL** empty. Then the buyer stays on the Polar confirmation page, which shows the download.
   - For **Return URL**, type `https://topway.pulgueta.com/download`. The checkout page then shows a back button to the site.
4. Go to **Finance > Account** and complete the checklist, then select **Submit for review**. Polar takes no payments until it approves the account. The [review checklist](https://polar.sh/docs/merchant-of-record/review-checklist) tells what Polar needs.
5. When Polar approves the account, copy the URL of the checkout link into `polarUrl` in [`web/src/config.ts`](../web/src/config.ts). Use the URL of the link, not the URL of the checkout page that it opens, because that page expires.
6. Build and deploy the website, as in step 9 of [Make a release with GitHub Actions](#make-a-release-with-github-actions). The download page then shows **Buy the DMG** in place of **Coming soon**.

[Checkout Links](https://polar.sh/docs/features/checkout/links) in the Polar documentation tells more.

### Upload the DMG of a release

**Upload the new DMG to the benefit at each release.** If you do not, new buyers install the old version first, and Sparkle then updates it.

1. Download the DMG of the release. Use the DMG of the GitHub release, not a different build, so that buyers get the same file as Sparkle:

   ```sh
   gh release download v0.2 --repo pulgueta/topway --pattern Topway-0.2.dmg
   ```

2. In Polar, open the **File Downloads** benefit of Topway. Drag `Topway-0.2.dmg` to the dropzone.
3. Make sure that the file has the same checksum. In the menu of the file, select **Copy SHA-256 Checksum**, and compare it with the output of this command:

   ```sh
   shasum -a 256 Topway-0.2.dmg
   ```

4. Make sure that the file has no **Malicious file detected** badge. Polar scans each upload, and buyers cannot download a file that it flags. [File Downloads](https://polar.sh/docs/features/benefits/file-downloads) in the Polar documentation tells what to do.
5. Save the benefit. Keep the DMG of the last release enabled for one day. Polar scans files in the background, so no badge right after the upload does not mean that the scan is complete. While both files are enabled, buyers get both, and each one works.
6. After one day, open the benefit again and make sure that the new DMG still has no badge. Then disable the DMG of the last release. Do not delete it. A disabled file stays available to the buyers who got it, but new buyers do not get it. A deleted file goes away for all buyers. Polar also gives the new file to all earlier buyers.
7. If Polar flags the new DMG later, stop all distribution of that DMG until you know the cause. The same file is in the GitHub release and in the Sparkle feed:
   1. In Polar, enable the DMG of the last release again, so that new buyers get a file that works.
   2. In `web/public/appcast.xml`, remove the `<item>` of the flagged version only. Keep the other items. Then deploy the website, so that Sparkle stops offering the update.
   3. Make the GitHub release a draft, so that its DMG is not public: `gh release edit v0.2 --repo pulgueta/topway --draft`.
   4. Find the cause. See [File Downloads](https://polar.sh/docs/features/benefits/file-downloads) in the Polar documentation. When you know that the file is safe, publish the release again (`--draft=false`), put back the item, and deploy. Otherwise, make a new release with a higher build number.

## Make a release

Each release needs a version number and a build number that are higher than the last release. Sparkle compares the build number (`CFBundleVersion`), not the version.

### Make a release with GitHub Actions

1. Change the version and the build number of both targets. Both channels then show the same number. This command changes 0.1 (1) to 0.2 (2) in the 4 build configurations:

   ```sh
   sed -i '' -e 's/MARKETING_VERSION = 0.1;/MARKETING_VERSION = 0.2;/' \
     -e 's/CURRENT_PROJECT_VERSION = 1;/CURRENT_PROJECT_VERSION = 2;/' \
     topway.xcodeproj/project.pbxproj
   ```

2. Make sure that the change is in 4 places. Each command must print `4`:

   ```sh
   grep -c 'MARKETING_VERSION = 0.2;' topway.xcodeproj/project.pbxproj
   grep -c 'CURRENT_PROJECT_VERSION = 2;' topway.xcodeproj/project.pbxproj
   ```

3. Commit the change and merge it into `main`.
4. Get the merged `main` on your Mac:

   ```sh
   git switch main
   git pull
   ```

5. Add a tag with the letter `v` and the version, then push it. The script stops if the tag is not `v` and `MARKETING_VERSION`.

   ```sh
   git tag v0.2
   git push origin v0.2
   ```

6. Open **Actions > Release the direct build** on GitHub, and wait until the run passes. Most of the time is for notarization. Apple says that notarization usually takes less than one hour.
7. Make sure that the release `v0.2` has `Topway-0.2.dmg`.
8. Open the pull request from the branch `release/v0.2`. It changes only `web/public/appcast.xml`. Its checks do not start by themselves: in the merge box, select **Approve workflows to run**. When the checks pass, merge it.
9. Deploy the website. The deploy replaces all the files of the site, so the site must also keep `/.well-known/apple-app-site-association` and `/oauth/callback`. Without them, the sign-in stops. [AGENTS.md](../AGENTS.md#sign-in-callback) tells why.
10. Make sure that the site serves the new appcast:

    ```sh
    curl -s https://topway.pulgueta.com/appcast.xml | grep '<sparkle:version>'
    ```

11. Upload the new DMG to Polar, as in [Upload the DMG of a release](#upload-the-dmg-of-a-release).

The release must exist before the appcast points to it. For this reason, the workflow makes the release first and gives you the appcast as a pull request. If a step after **Make the GitHub release** fails, do not run the workflow again. [The release is there, but the appcast pull request is not](#the-release-is-there-but-the-appcast-pull-request-is-not) tells how to finish it.

The workflow opens the pull request with the `GITHUB_TOKEN`. For such a pull request, GitHub keeps the CI runs in an approval-required state until a user with write access approves them. [Triggering a workflow from a workflow](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow#triggering-a-workflow-from-a-workflow) in the GitHub documentation tells more.

### Make a release from your Mac

Use this when GitHub Actions is not available. Your Mac must have:

- The Developer ID Application certificate in the login keychain.
- The `Topway Developer ID` profile in the profiles folder of Xcode.
- `Config/OAuth.local.xcconfig` with the client ID.
- The notarytool keychain profile `topway-notary`.
- The private Sparkle key in a file outside the repository.

1. Change the version and the build number, commit, and get the merged `main`, as in steps 1 to 4 above.
2. Run the script with the tag:

   ```sh
   NOTARY_KEYCHAIN_PROFILE=topway-notary SPARKLE_PRIVATE_KEY_FILE=~/sparkle_private_key \
     scripts/release-direct.sh v0.2
   ```

3. Turn off the release workflow. Then the tag push does not start a second release of the same tag:

   ```sh
   gh workflow disable release-direct.yml
   ```

4. Add the tag and make the GitHub release with the DMG:

   ```sh
   git tag v0.2
   git push origin v0.2
   gh release create v0.2 build/release/Topway-0.2.dmg --verify-tag --title "Topway 0.2" --generate-notes
   ```

5. Turn on the release workflow again. If it stays off, the next tag makes no release.

   ```sh
   gh workflow enable release-direct.yml
   ```

6. Commit `web/public/appcast.xml` on a branch, merge it, deploy the website, and upload the DMG to Polar, as in steps 8 to 11 above.

The script puts the DMG in `build/release/`, or in the folder that `OUTPUT_DIR` gives. Git ignores `build/`. The comments at the top of the script list all the options.

To test the build with no notarization and no appcast change, run `scripts/release-direct.sh --skip-notarize --skip-appcast`. Do not publish that DMG, because Gatekeeper refuses it.

## Users and channels

Tell users to install only one channel on a Mac. The two channels have the same bundle ID. With two copies on the Mac, macOS can give the sign-in callback to the other copy, and the sign-in does not finish.

To move from one channel to the other:

1. Quit Topway.
2. Delete the old copy.
3. Install the new copy, then open it.

The sign-in and the settings stay. Since commits 8066b99 and 352aaba, both channels keep the sign-in in the data protection keychain, in the access group `7QNFW3929Z.com.pulgueta.topway`. An older build, such as the App Store version 0.1, kept the sign-in in the file-based keychain. After a move from that build, Topway can ask for the Mac password one time. Type it and allow the access. [AGENTS.md](../AGENTS.md#keychain) tells how the Keychain move works.

Sparkle updates only the direct copy. The App Store updates only the App Store copy.

## Troubleshooting

### Notarization fails

The script stops and prints the submission ID. To see the problems, get the log of the submission:

```sh
xcrun notarytool log your_submission_id --keychain-profile topway-notary
```

In GitHub Actions, use `--key`, `--key-id` and `--issuer` in place of `--keychain-profile`. The log gives each problem with the path of the file. Apple's guide [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow) has more information.

### The release is there, but the appcast pull request is not

When a step after **Make the GitHub release** fails, the DMG is in the release, but the appcast does not have it. For example, the push of the branch fails, or GitHub Actions cannot create pull requests. Do not run the workflow again. The release is there, so a new run stops at that step. Also, a new build makes a DMG with different bytes, so its appcast does not agree with the DMG in the release.

Each attempt of the run keeps the appcast of its DMG and the checksum of the DMG in the artifact `appcast-v0.2-N`. `N` is the number of the attempt. Make the pull request with it:

1. See if the workflow pushed the branch. If this command prints a line, the branch has the correct appcast. Then go to step 7.

   ```sh
   git ls-remote --heads origin release/v0.2
   ```

2. Find the ID of the run:

   ```sh
   gh run list --workflow release-direct.yml --limit 5
   ```

3. In a new folder, download the artifacts of the run and the DMG of the release. Replace `your_run_id` with the ID from step 2. The commands stop at the first error:

   ```sh
   mkdir ~/appcast-v0.2 && cd ~/appcast-v0.2 &&
     gh run download your_run_id --repo pulgueta/topway --pattern 'appcast-v0.2-*' &&
     gh release download v0.2 --repo pulgueta/topway --pattern Topway-0.2.dmg &&
     echo "The downloads are complete."
   ```

   If the last line is not `The downloads are complete.`, a download failed. Do not continue. Correct the problem that `gh` shows, delete the folder `~/appcast-v0.2`, then do this step again.

4. Find the artifact that agrees with the DMG of the release. For each artifact, `shasum` compares `Topway-0.2.dmg` with the checksum in the artifact:

   ```sh
   for file in appcast-v0.2-*/Topway-0.2.dmg.sha256; do
     shasum -a 256 -c "$file" && echo "Use the folder ${file%%/*}."
   done
   ```

   The command shows `Use the folder` only after `Topway-0.2.dmg: OK`, for example `Use the folder appcast-v0.2-1.` Use only that folder. `FAILED` tells you that an artifact does not agree with the DMG. If no `Use the folder` line shows, no artifact agrees with the DMG of the release. Then do not make the pull request, and make the next release with a higher version and build number.

5. In the repository, put that appcast on a new branch from the newest `main`. Replace `appcast-v0.2-1` with the folder from step 4. The diff must add only the item of 0.2:

   ```sh
   git switch main
   git pull
   git switch --create release/v0.2
   cp ~/appcast-v0.2/appcast-v0.2-1/appcast.xml web/public/appcast.xml
   git diff
   ```

6. Commit the appcast and push the branch:

   ```sh
   git add web/public/appcast.xml
   git commit --message "chore(web): add v0.2 to the appcast"
   git push origin release/v0.2
   ```

7. Open the pull request:

   ```sh
   gh pr create --base main --head release/v0.2 --title "chore(web): add v0.2 to the appcast" \
     --body "This pull request adds v0.2 to the Sparkle appcast. The GitHub release v0.2 has the DMG."
   ```

8. When the checks pass, merge the pull request. Then do steps 9 to 11 of [Make a release with GitHub Actions](#make-a-release-with-github-actions).

### An update does not show

Do these checks in this sequence:

1. In Topway, go to **Settings > Updates**. If the footer says that the build has no update key, the build had an empty `SPARKLE_PUBLIC_ED_KEY`. Install a DMG from the release script, which refuses an empty key.
2. Select **Check for updates…**. Sparkle checks on a schedule, so an automatic check can come later.
3. Make sure that the site serves the new appcast. A cache can keep the old file for some time:

   ```sh
   curl -sI https://topway.pulgueta.com/appcast.xml
   curl -s https://topway.pulgueta.com/appcast.xml | grep '<sparkle:version>'
   ```

4. Make sure that the build number in the appcast is higher than the build number of the installed app. Sparkle ignores an item with the same or a lower `CFBundleVersion`. To see the installed build number:

   ```sh
   plutil -extract CFBundleVersion raw -o - /Applications/Topway.app/Contents/Info.plist
   ```

5. If Sparkle shows a signature error, the appcast has a signature from a different private key. Make the release again with the private key that agrees with `SPARKLE_PUBLIC_ED_KEY`.

### The sign-in does not come back to the app

1. Make sure that macOS approved the domain for Topway. The output must show `topway.pulgueta.com` with the App ID `7QNFW3929Z.com.pulgueta.topway` and the approval `approved`:

   ```sh
   sudo swcutil show | grep -B 2 -A 8 topway.pulgueta.com
   ```

2. Find all copies of Topway that Launch Services knows. The list must have only the installed app:

   ```sh
   lsregister=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
   "$lsregister" -dump | awk '/^path:/{p=$0} /^identifier: *com\.pulgueta\.topway$/{print p}' | sort -u
   ```

3. For each other copy, remove it from Launch Services, then delete it. Replace the path with the path from step 2:

   ```sh
   "$lsregister" -u "/path/to/the/other/Topway.app"
   ```

The release script and `scripts/check-app-store-build.sh` remove their own copies at exit. A copy in an Xcode archive, an old DMG or the Downloads folder can stay.
