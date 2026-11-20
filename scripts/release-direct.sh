#!/usr/bin/env bash
#
# Make a release of the direct build of Topway: a Developer ID app in a notarized DMG, and a
# new item in the Sparkle appcast. docs/direct-distribution.md tells how to prepare a Mac or
# GitHub Actions for this script.
#
# Usage: scripts/release-direct.sh [--skip-notarize] [--skip-appcast] [vVERSION] [SETTING=value ...]
#
# The script does these steps in this sequence. It stops at the first problem.
#   1. Read the Release build settings of the topway-direct scheme. Stop if SPARKLE_PUBLIC_ED_KEY
#      or RAILWAY_OAUTH_CLIENT_ID is empty, or if the tag is not v$MARKETING_VERSION.
#   2. Archive with Developer ID signing and the Developer ID provisioning profile.
#   3. Export the archive for Developer ID.
#   4. Rename topway-direct.app to Topway.app, then examine its signature and its contents.
#   5. Notarize the app and staple the ticket to it.
#   6. Make Topway-VERSION.dmg with Topway.app and a link to /Applications.
#   7. Sign, notarize and staple the DMG, then examine it with Gatekeeper.
#   8. Make a new appcast with the DMG (generate_appcast of Sparkle), then examine the new item.
#   9. Put the DMG in OUTPUT_DIR and the new appcast in its place. The script changes these
#      files only after all the checks passed, so a failure keeps the earlier DMG and appcast.
#
# Options:
#   --skip-notarize  Do not notarize, staple or examine with Gatekeeper. For a test on your Mac.
#                    The script then never changes the release appcast: add --skip-appcast,
#                    or set APPCAST_OUTPUT to a test file.
#   --skip-appcast   Do not change the appcast.
#   vVERSION         The release tag, for example v0.2. The script stops if it is not
#                    v$MARKETING_VERSION.
#   SETTING=value    A build setting for xcodebuild, for example a test value of
#                    SPARKLE_PUBLIC_ED_KEY. Do not use it for a real release.
#
# Environment:
#   DEVELOPER_ID_PROFILE_NAME  The name of the Developer ID provisioning profile.
#                              Default: Topway Developer ID.
#   NOTARY_KEY_PATH            The .p8 file of an App Store Connect API key (for CI), with
#   NOTARY_KEY_ID              the key ID and
#   NOTARY_ISSUER_ID           the issuer ID.
#   NOTARY_KEYCHAIN_PROFILE    Or the name of a notarytool keychain profile (on your Mac).
#   SPARKLE_PRIVATE_KEY_FILE   The file with the private EdDSA key of Sparkle.
#   OUTPUT_DIR                 The folder for the DMG. Default: build/release.
#   APPCAST_FILE               The appcast to update. Default: web/public/appcast.xml.
#   APPCAST_OUTPUT             The file for the new appcast. Default: APPCAST_FILE. With
#                              --skip-notarize, it is necessary, and it cannot be the release
#                              appcast web/public/appcast.xml.
#
# The script works in a temporary folder. At exit, also after an error, it removes each app
# that it made from Launch Services and deletes the folder. A registered copy of
# com.pulgueta.topway stops the HTTPS sign-in of the installed app, so this cleanup is
# necessary. The script never prints a key or the OAuth client ID, and it never writes them
# into the repository.

set -euo pipefail

readonly USAGE="Usage: scripts/release-direct.sh [--skip-notarize] [--skip-appcast] [vVERSION] [SETTING=value ...]"
readonly SCHEME="topway-direct"
readonly BUNDLE_ID="com.pulgueta.topway"
readonly TEAM_ID="7QNFW3929Z"
readonly SIGNING_IDENTITY="Developer ID Application"
readonly EXPORTED_APP="topway-direct.app"
readonly APP_NAME="Topway.app"
readonly ASSOCIATED_DOMAIN="webcredentials:topway.pulgueta.com"
readonly MACH_LOOKUP_KEY="com.apple.security.temporary-exception.mach-lookup.global-name"
readonly DOWNLOAD_URL_BASE="https://github.com/pulgueta/topway/releases/download"
readonly LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
# generate_appcast keeps a copy of each app that it reads in this folder.
readonly SPARKLE_CACHE="$HOME/Library/Caches/Sparkle_generate_appcast"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT
# A fixed package folder, so the Sparkle tools are always in the same place.
readonly PACKAGES_DIR="$REPO_ROOT/build/SourcePackages"
readonly SPARKLE_BIN="$PACKAGES_DIR/artifacts/sparkle/Sparkle/bin"
# The appcast that the website serves. A DMG that is not notarized must never go in it.
readonly RELEASE_APPCAST="$REPO_ROOT/web/public/appcast.xml"
# The build numbers that the script compares as Sparkle does: numbers with periods.
readonly BUILD_PATTERN='^[0-9]+(\.[0-9]+)*$'

work_dir=""
skip_notarize=0
skip_appcast=0
tag=""
build_settings=()
notary_auth=()
settings=""
version=""
build=""
authority=""
public_key=""
profile_name="${DEVELOPER_ID_PROFILE_NAME:-Topway Developer ID}"
output_dir="${OUTPUT_DIR:-$REPO_ROOT/build/release}"
appcast_file="${APPCAST_FILE:-$RELEASE_APPCAST}"
appcast_output="${APPCAST_OUTPUT:-$appcast_file}"
# The temporary copies of step 9. The cleanup deletes them after a failure.
partial_files=()
# Step 9 replaces the DMG first and the appcast second. Until the appcast is in its place,
# placed_dmg is the DMG path and earlier_dmg is a hard link to the earlier DMG (empty when
# there was no earlier DMG). After a failure, the cleanup then puts back the earlier DMG.
placed_dmg=""
earlier_dmg=""

step() {
  echo
  echo "==> $*"
}

ok() { echo "OK: $*"; }

die() {
  echo "Error: $*" >&2
  exit 1
}

# When step 9 did not complete, put back the earlier DMG, so that the earlier DMG and appcast
# stay a pair. The appcast has the EdDSA signature of its DMG.
restore_earlier_dmg() {
  [[ -n "$placed_dmg" ]] || return 0
  if [[ -z "$earlier_dmg" ]]; then
    rm -f "$placed_dmg"
    echo "The script deleted the new DMG. There was no earlier DMG at $placed_dmg." >&2
  elif mv -f "$earlier_dmg" "$placed_dmg"; then
    # If the DMG rename did not occur, the two names are links to one file, and mv keeps both.
    rm -f "$earlier_dmg"
    echo "The script put back the earlier DMG at $placed_dmg." >&2
  else
    echo "Error: the script cannot put back the earlier DMG. Move $earlier_dmg to $placed_dmg." >&2
  fi
}

# Put back the earlier DMG if necessary. Then remove from Launch Services each app that the
# script made, and delete the folders and the temporary copies.
cleanup() {
  local app file
  restore_earlier_dmg
  for file in ${partial_files[@]+"${partial_files[@]}"}; do
    rm -f "$file"
  done
  if [[ -n "$work_dir" && -d "$work_dir" ]]; then
    while IFS= read -r -d '' app; do
      "$LSREGISTER" -u "$app" 2>/dev/null || true
    done < <(find "$work_dir" -name '*.app' \( -type d -o -type l \) -print0)
    rm -rf "$work_dir"
    # SwiftPM puts empty lock files, named from the folder path, in TMPDIR.
    rm -f "${TMPDIR:-/tmp}"/*"$(basename "$work_dir")"_*.lock
  fi
  for app in "$SPARKLE_CACHE"/*/"$APP_NAME"; do
    [[ -d "$app" ]] || continue
    "$LSREGISTER" -u "$app" 2>/dev/null || true
    rm -rf "$(dirname "$app")"
  done
}

parse_arguments() {
  local arg
  for arg in "$@"; do
    case "$arg" in
      -h | --help)
        echo "$USAGE"
        exit 0
        ;;
      --skip-notarize) skip_notarize=1 ;;
      --skip-appcast) skip_appcast=1 ;;
      -*) die "Unknown option: $arg. $USAGE" ;;
      *=*) build_settings+=("$arg") ;;
      *)
        [[ -z "$tag" ]] || die "Give one tag only. $USAGE"
        tag="$arg"
        ;;
    esac
  done
}

# Run xcodebuild for the topway-direct scheme (Release) with the SETTING=value arguments last,
# so that they replace the values of the script.
xcodebuild_direct() {
  xcodebuild \
    -project "$REPO_ROOT/topway.xcodeproj" \
    -scheme "$SCHEME" \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -clonedSourcePackagesDirPath "$PACKAGES_DIR" \
    "$@" \
    ${build_settings[@]+"${build_settings[@]}"}
}

# Print the value of a build setting from the output of -showBuildSettings.
build_setting() { sed -n "s/^ *$1 = //p" <<<"$settings" | tail -n 1; }

# Stop when the text $1 is not numbers with periods. The script cannot compare other build
# numbers as Sparkle does. $2 tells where the text comes from.
check_build_number() {
  [[ "$1" =~ $BUILD_PATTERN ]] ||
    die "$2 is \"$1\". Use a build number of numbers and periods, for example 2 or 1.2."
}

# Exit with 0 when the build $1 is higher than the build $2, as Sparkle compares them
# (SUStandardVersionComparator). Each part between the periods is a number, and the shorter
# build gets parts of 0. Thus 10 is higher than 2, 1.10 is higher than 1.2, and 1 is equal to
# 1.0.0, so it is not higher.
is_higher_build() {
  local -a parts_a parts_b
  local count i a b
  IFS=. read -r -a parts_a <<<"$1"
  IFS=. read -r -a parts_b <<<"$2"
  count=${#parts_a[@]}
  ((${#parts_b[@]} <= count)) || count=${#parts_b[@]}
  for ((i = 0; i < count; i++)); do
    a=$((10#${parts_a[i]:-0}))
    b=$((10#${parts_b[i]:-0}))
    ((a == b)) || return $((a > b ? 0 : 1))
  done
  return 1
}

# Print the sparkle:version of each item in the appcast, one on each line.
appcast_builds() {
  xmllint --xpath "//*[local-name()='item']/*[local-name()='version']/text()" "$1" 2>/dev/null || true
}

# Print the highest build in the appcast, as Sparkle compares them, or nothing.
newest_appcast_build() {
  local item newest=""
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    check_build_number "$item" "A build in the appcast"
    if [[ -z "$newest" ]] || is_higher_build "$item" "$newest"; then
      newest="$item"
    fi
  done <<<"$(appcast_builds "$1")"
  echo "$newest"
}

# Exit with 0 when the appcast has one item with the build $2, and each other item has a lower
# build, as Sparkle compares them. Then Sparkle offers that item as the update.
is_newest_appcast_build() {
  local item found=0
  while IFS= read -r item; do
    [[ -n "$item" ]] || continue
    if [[ "$item" == "$2" ]]; then
      found=$((found + 1))
    else
      check_build_number "$item" "A build in the appcast"
      is_higher_build "$2" "$item" || return 1
    fi
  done <<<"$(appcast_builds "$1")"
  ((found == 1))
}

# Print the path $1 from the root, with no symbolic link, no . and no .. in it. A folder that
# does not exist yet stays as it is in the path, because step 9 can make it.
full_path() {
  local path="$1" folder="/" name next
  local -a names
  [[ "$path" == /* ]] || path="$PWD/$path"
  IFS=/ read -r -a names <<<"$path"
  for name in ${names[@]+"${names[@]}"}; do
    case "$name" in
      "" | .) ;;
      ..) folder=$(dirname "$folder") ;;
      *)
        next="${folder%/}/$name"
        if [[ -d "$next" ]]; then
          folder=$(cd "$next" 2>/dev/null && pwd -P) || folder="$next"
        else
          folder="$next"
        fi
        ;;
    esac
  done
  echo "$folder"
}

# Exit with 0 when the path $1 is the release appcast, also with a different spelling, and
# also when web/public does not exist yet. The comparison ignores uppercase and lowercase,
# because the disk of a Mac usually does.
is_release_appcast() {
  [[ "$1" -ef "$RELEASE_APPCAST" ]] && return 0
  [[ "$(full_path "$1" | tr '[:upper:]' '[:lower:]')" == "$(full_path "$RELEASE_APPCAST" | tr '[:upper:]' '[:lower:]')" ]]
}

# A DMG that is not notarized must never go in the release appcast. With --skip-notarize, the
# script writes a new appcast only to APPCAST_OUTPUT, and that cannot be the release appcast.
check_appcast_output() {
  ((skip_notarize == 1 && skip_appcast == 0)) || return 0
  [[ -n "${APPCAST_OUTPUT:-}" ]] ||
    die "With --skip-notarize, the script does not change the release appcast. Add --skip-appcast, or set APPCAST_OUTPUT to a test file."
  if is_release_appcast "$appcast_output"; then
    die "APPCAST_OUTPUT is the release appcast. With --skip-notarize, set it to a test file."
  fi
  ok "With --skip-notarize, the new appcast goes only to $appcast_output."
}

# Step 1. Find each problem that would stop the release before the long build starts.
preflight() {
  step "1. Read the build settings and the release inputs."
  check_appcast_output
  settings=$(xcodebuild_direct -showBuildSettings) || die "xcodebuild cannot read the build settings."
  version=$(build_setting MARKETING_VERSION)
  build=$(build_setting CURRENT_PROJECT_VERSION)
  [[ -n "$version" && -n "$build" ]] || die "The build settings have no MARKETING_VERSION or CURRENT_PROJECT_VERSION."
  echo "Version: $version ($build)"
  check_build_number "$build" "CURRENT_PROJECT_VERSION"

  [[ -n "$(build_setting SPARKLE_PUBLIC_ED_KEY)" ]] ||
    die "SPARKLE_PUBLIC_ED_KEY is empty. Put the public key from generate_keys in Config/Direct.xcconfig."
  ok "SPARKLE_PUBLIC_ED_KEY has a value."
  [[ -n "$(build_setting RAILWAY_OAUTH_CLIENT_ID)" ]] ||
    die "RAILWAY_OAUTH_CLIENT_ID is empty, so the release cannot sign in. Put it in Config/OAuth.local.xcconfig."
  ok "RAILWAY_OAUTH_CLIENT_ID has a value."

  if [[ -n "$tag" ]]; then
    [[ "$tag" == "v$version" ]] || die "The tag is $tag, but MARKETING_VERSION is $version. Use the tag v$version."
    ok "The tag $tag agrees with MARKETING_VERSION."
  fi

  if ((skip_notarize == 0)); then
    if [[ -n "${NOTARY_KEYCHAIN_PROFILE:-}" ]]; then
      notary_auth=(--keychain-profile "$NOTARY_KEYCHAIN_PROFILE")
    elif [[ -n "${NOTARY_KEY_PATH:-}" && -n "${NOTARY_KEY_ID:-}" && -n "${NOTARY_ISSUER_ID:-}" ]]; then
      [[ -f "$NOTARY_KEY_PATH" ]] || die "NOTARY_KEY_PATH does not point to a file."
      notary_auth=(--key "$NOTARY_KEY_PATH" --key-id "$NOTARY_KEY_ID" --issuer "$NOTARY_ISSUER_ID")
    else
      die "Set NOTARY_KEYCHAIN_PROFILE, or NOTARY_KEY_PATH, NOTARY_KEY_ID and NOTARY_ISSUER_ID. To make a test build, use --skip-notarize."
    fi
    ok "The notary credentials are set."
  fi

  if ((skip_appcast == 0)); then
    [[ -n "${SPARKLE_PRIVATE_KEY_FILE:-}" && -f "$SPARKLE_PRIVATE_KEY_FILE" ]] ||
      die "SPARKLE_PRIVATE_KEY_FILE does not point to a file. To make a build with no appcast change, use --skip-appcast."
    ok "The private EdDSA key file is there."
    if [[ -f "$appcast_file" ]]; then
      local newest
      newest=$(newest_appcast_build "$appcast_file")
      if [[ -n "$newest" ]]; then
        is_higher_build "$build" "$newest" ||
          die "CURRENT_PROJECT_VERSION ($build) must be higher than the newest build in the appcast ($newest). Sparkle compares CFBundleVersion, and for Sparkle, 1 and 1.0 are equal."
        ok "The build $build is higher than the newest build in the appcast ($newest)."
      fi
    else
      echo "There is no appcast at $appcast_file. The script makes a new one."
    fi
  fi
}

# Step 2. Command-line build settings go to all targets, also to the Swift package targets,
# and a package target must not get a provisioning profile. So the profile name goes through
# a nested setting that has a value only for a target that makes a .app (WRAPPER_EXTENSION).
archive_app() {
  step "2. Archive the $SCHEME scheme (Release). This can take some minutes."
  xcodebuild_direct -quiet \
    -derivedDataPath "$work_dir/DerivedData" \
    -archivePath "$work_dir/topway-direct.xcarchive" \
    CODE_SIGN_STYLE=Manual \
    DEVELOPMENT_TEAM="$TEAM_ID" \
    CODE_SIGN_IDENTITY="$SIGNING_IDENTITY" \
    'PROVISIONING_PROFILE_SPECIFIER=$(TOPWAY_PROFILE_FOR_$(WRAPPER_EXTENSION))' \
    TOPWAY_PROFILE_FOR_app="$profile_name" \
    archive
  ok "The archive is at $work_dir/topway-direct.xcarchive."
}

# Step 3. The export signs the app and all the code in it (Sparkle, its XPC services and its
# helper apps) with Developer ID and a secure timestamp.
export_app() {
  step "3. Export the archive for Developer ID."
  local options="$work_dir/ExportOptions.plist"
  /usr/libexec/PlistBuddy \
    -c "Add :method string developer-id" \
    -c "Add :signingStyle string manual" \
    -c "Add :teamID string $TEAM_ID" \
    -c "Add :signingCertificate string $SIGNING_IDENTITY" \
    -c "Add :provisioningProfiles dict" \
    -c "Add :provisioningProfiles:$BUNDLE_ID string $profile_name" \
    "$options" >/dev/null
  xcodebuild -exportArchive \
    -archivePath "$work_dir/topway-direct.xcarchive" \
    -exportPath "$work_dir/export" \
    -exportOptionsPlist "$options"
  [[ -d "$work_dir/export/$EXPORTED_APP" ]] || die "The export has no $EXPORTED_APP."
}

# Step 4. The bundle name is not in the signature, so the rename keeps the signature valid.
check_app() {
  local app="$1" details entitlements domains exceptions name
  step "4. Rename the app to $APP_NAME and examine it."
  mv "$work_dir/export/$EXPORTED_APP" "$app"

  codesign --verify --deep --strict "$app" || die "The signature of $APP_NAME is not valid."
  details=$(codesign -dvv "$app" 2>&1)
  authority=$(sed -n 's/^Authority=//p' <<<"$details" | head -n 1)
  [[ "$authority" == "$SIGNING_IDENTITY: "*"($TEAM_ID)" ]] ||
    die "$APP_NAME has the signature of \"$authority\", not of $SIGNING_IDENTITY ($TEAM_ID)."
  ok "The signature is valid, by $authority."

  entitlements="$work_dir/entitlements.plist"
  codesign -d --entitlements - --xml "$app" >"$entitlements" 2>/dev/null ||
    die "codesign cannot read the entitlements of $APP_NAME."
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :com.apple.application-identifier' "$entitlements" 2>/dev/null)" == "$TEAM_ID.$BUNDLE_ID" ]] ||
    die "The entitlements have no application identifier $TEAM_ID.$BUNDLE_ID. The sign-in uses it for the Keychain."
  domains=$(/usr/libexec/PlistBuddy -c 'Print :com.apple.developer.associated-domains' "$entitlements" 2>/dev/null || true)
  grep -qxF "    $ASSOCIATED_DOMAIN" <<<"$domains" ||
    die "The entitlements do not have $ASSOCIATED_DOMAIN. The sign-in callback needs it."
  exceptions=$(/usr/libexec/PlistBuddy -c "Print :$MACH_LOOKUP_KEY" "$entitlements" 2>/dev/null || true)
  for name in "$BUNDLE_ID-spks" "$BUNDLE_ID-spki"; do
    grep -qxF "    $name" <<<"$exceptions" ||
      die "The entitlements do not have the mach-lookup exception $name. Sparkle cannot install updates without it."
  done
  ok "The entitlements have the application identifier, $ASSOCIATED_DOMAIN and the Sparkle exceptions."

  [[ -d "$app/Contents/Frameworks/Sparkle.framework" ]] || die "$APP_NAME has no Sparkle.framework."
  public_key=$(plutil -extract SUPublicEDKey raw -o - "$app/Contents/Info.plist" 2>/dev/null || true)
  [[ -n "$public_key" ]] || die "SUPublicEDKey in the Info.plist of $APP_NAME is empty."
  ok "$APP_NAME has Sparkle.framework and a value for SUPublicEDKey."
}

# Send a file to the Apple notary service and wait for the result.
notarize() {
  local file="$1" result status id
  result="$work_dir/notary-$(basename "$file").json"
  echo "Send $(basename "$file") to the Apple notary service. This can take some minutes."
  xcrun notarytool submit "$file" "${notary_auth[@]}" --wait --output-format json >"$result" || true
  status=$(plutil -extract status raw -o - "$result" 2>/dev/null || echo "unknown")
  id=$(plutil -extract id raw -o - "$result" 2>/dev/null || echo "unknown")
  if [[ "$status" != "Accepted" ]]; then
    cat "$result" >&2
    die "The notary service did not accept $(basename "$file") (status: $status). To see why, run: xcrun notarytool log $id with your notary credentials."
  fi
  ok "The notary service accepted $(basename "$file") (submission $id)."
}

# Examine a file with Gatekeeper. It must be accepted as notarized.
assess() {
  local result
  result=$(spctl "$@" 2>&1) || die "Gatekeeper does not accept the file: $result"
  grep -q "source=Notarized Developer ID" <<<"$result" ||
    die "Gatekeeper does not see a notarized Developer ID file: $result"
  ok "Gatekeeper accepts it as notarized Developer ID."
}

# Step 5. notarytool needs an archive for an app, so the script sends a ZIP of the app.
notarize_app() {
  local app="$1" zip="$work_dir/Topway.zip"
  step "5. Notarize $APP_NAME and staple the ticket to it."
  ditto -c -k --keepParent "$app" "$zip"
  notarize "$zip"
  xcrun stapler staple "$app"
  assess --assess --type execute -vv "$app"
}

# Step 6. Sparkle recommends an APFS disk image with lzfse compression (ULFO).
make_dmg() {
  local dmg_dir="$1" dmg="$2"
  step "6. Make $(basename "$dmg")."
  ln -s /Applications "$dmg_dir/Applications"
  hdiutil create -quiet -volname Topway -srcfolder "$dmg_dir" -fs APFS -format ULFO -ov "$dmg"
  ok "The DMG has $APP_NAME and a link to /Applications."
}

# Step 7.
sign_dmg() {
  local dmg="$1"
  step "7. Sign the DMG, then notarize and staple it."
  codesign --sign "$authority" --timestamp "$dmg"
  codesign --verify --strict "$dmg" || die "The signature of the DMG is not valid."
  ok "The DMG has the signature of $authority."
  if ((skip_notarize == 1)); then
    echo "Skip notarization, stapling and Gatekeeper (--skip-notarize)."
    return 0
  fi
  notarize "$dmg"
  xcrun stapler staple "$dmg"
  assess -a -t open --context context:primary-signature -vv "$dmg"
}

# Exit with 0 only when the EdDSA signature (base64) of the file agrees with the public key
# (base64). Sparkle signs all the bytes of the archive with Ed25519, and CryptoKit has Ed25519.
verify_ed_signature() {
  local verifier="$work_dir/verify_ed_signature.swift"
  cat >"$verifier" <<'SWIFT'
import CryptoKit
import Foundation

let arguments = CommandLine.arguments
guard arguments.count == 4,
    let key = Data(base64Encoded: arguments[1]),
    let signature = Data(base64Encoded: arguments[2]),
    let file = FileManager.default.contents(atPath: arguments[3]),
    let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: key)
else { exit(2) }
exit(publicKey.isValidSignature(signature, for: file) ? 0 : 1)
SWIFT
  xcrun swift "$verifier" "$1" "$2" "$3"
}

# Step 8. generate_appcast reuses the appcast that is in the updates folder and adds an item
# for each new archive. The folder has only the new DMG, so the script first puts the current
# appcast there: the earlier items keep their URLs. --maximum-versions 0 keeps all items
# (the default keeps 3). The private key comes from a file, never from the command line.
# generate_appcast only warns when the private key does not agree with SUPublicEDKey, and it
# can then write the item with no signature. So the script examines the signature of the new
# item. The new appcast stays in the temporary folder until step 9.
update_appcast() {
  local dmg="$1" updates="$work_dir/updates" tool="$SPARKLE_BIN/generate_appcast" signature
  step "8. Add $(basename "$dmg") to the appcast."
  [[ -x "$tool" ]] || die "generate_appcast is not at $tool."
  mkdir "$updates"
  cp "$dmg" "$updates/"
  [[ ! -f "$appcast_file" ]] || cp "$appcast_file" "$updates/appcast.xml"
  "$tool" \
    --ed-key-file "$SPARKLE_PRIVATE_KEY_FILE" \
    --download-url-prefix "$DOWNLOAD_URL_BASE/v$version/" \
    --maximum-versions 0 \
    -o "$updates/appcast.xml" \
    "$updates"
  is_newest_appcast_build "$updates/appcast.xml" "$build" ||
    die "The new appcast does not have the build $build as its newest item."
  signature=$(xmllint --xpath "string(//*[local-name()='item'][*[local-name()='version']='$build']/*[local-name()='enclosure']/@*[local-name()='edSignature'])" \
    "$updates/appcast.xml" 2>/dev/null || true)
  [[ -n "$signature" ]] ||
    die "The new appcast item has no EdDSA signature. Make sure that SPARKLE_PRIVATE_KEY_FILE agrees with SPARKLE_PUBLIC_ED_KEY."
  verify_ed_signature "$public_key" "$signature" "$dmg" ||
    die "The EdDSA signature in the new appcast item does not agree with SUPublicEDKey of the app. Sparkle would refuse this update. Make sure that SPARKLE_PRIVATE_KEY_FILE agrees with SPARKLE_PUBLIC_ED_KEY."
  ok "The EdDSA signature of the new item agrees with the DMG and with SUPublicEDKey."
}

# Step 9. Each file goes first to a temporary copy in its folder, and then a rename replaces the
# earlier file. The script does this only after all the checks passed. Thus a failure keeps the
# earlier DMG and appcast, and a file is never there in part. The DMG and the appcast change
# together: if the appcast rename fails, the cleanup puts back the earlier DMG.
put_release_files() {
  local dmg="$1" new_appcast="$work_dir/updates/appcast.xml" target
  step "9. Put the DMG and the appcast in their folders."
  mkdir -p "$output_dir"
  target="$output_dir/$(basename "$dmg")"
  partial_files+=("$target.partial")
  cp "$dmg" "$target.partial"
  if ((skip_appcast == 0)); then
    mkdir -p "$(dirname "$appcast_output")"
    partial_files+=("$appcast_output.partial")
    cp "$new_appcast" "$appcast_output.partial"
    if [[ -e "$target" ]]; then
      ln -f "$target" "$target.earlier"
      earlier_dmg="$target.earlier"
    fi
    placed_dmg="$target"
  fi
  mv -f "$target.partial" "$target"
  ok "The DMG is at $target."
  if ((skip_appcast == 0)); then
    mv -f "$appcast_output.partial" "$appcast_output" ||
      die "The script cannot put the new appcast at $appcast_output."
    placed_dmg=""
    if [[ -n "$earlier_dmg" ]]; then
      rm -f "$earlier_dmg"
      earlier_dmg=""
    fi
    ok "The appcast at $appcast_output has $version ($build)."
  fi
}

main() {
  parse_arguments "$@"
  trap cleanup EXIT
  trap 'exit 130' INT TERM
  work_dir=$(mktemp -d -t topway-release)

  preflight
  archive_app
  export_app

  local dmg_dir="$work_dir/dmg"
  local app="$dmg_dir/$APP_NAME"
  local dmg="$work_dir/Topway-$version.dmg"
  mkdir "$dmg_dir"
  check_app "$app"
  if ((skip_notarize == 0)); then
    notarize_app "$app"
  else
    step "5. Skip notarization of the app (--skip-notarize)."
  fi
  make_dmg "$dmg_dir" "$dmg"
  sign_dmg "$dmg"

  if ((skip_appcast == 0)); then
    update_appcast "$dmg"
  else
    step "8. Skip the appcast (--skip-appcast)."
  fi
  put_release_files "$dmg"
  dmg="$output_dir/$(basename "$dmg")"

  echo
  if ((skip_notarize == 1)); then
    echo "Result: the test files are ready. This DMG is not notarized. Do not publish it."
  else
    echo "Result: the release files are ready."
  fi
  echo "DMG: $dmg"
  if ((skip_appcast == 0)); then
    echo "Appcast: $appcast_output"
  fi
  if ((skip_notarize == 0 && skip_appcast == 0)); then
    echo "Next: put the DMG in the GitHub release v$version, then publish the appcast."
  fi
}

main "$@"
