#!/usr/bin/env bash
#
# Make sure that the Mac App Store build of Topway has no Sparkle and no update code
# (App Review Guideline 2.4.5).
#
# Usage: scripts/check-app-store-build.sh [path to an .xcarchive or an .app]
#
# With no argument, the script archives the topway scheme (Release, with no signing and
# no OAuth client ID) into a temporary folder and examines that archive. At exit, also
# after an error, it removes the built apps from Launch Services and deletes the folder.
# A registered unsigned copy of com.pulgueta.topway stops the HTTPS sign-in of the
# real app, so this cleanup is necessary.
#
# With one argument, the script examines that archive or app. It does not change or
# register it.
#
# The script prints one PASS, FAIL or SKIP line for each check. The exit status is 0 when all
# checks pass, 1 when a check fails, and 2 for an incorrect command.

set -euo pipefail

readonly USAGE="Usage: scripts/check-app-store-build.sh [path to an .xcarchive or an .app]"
readonly BUNDLE_ID="com.pulgueta.topway"
readonly LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
readonly MACH_LOOKUP_KEY="com.apple.security.temporary-exception.mach-lookup.global-name"
# Sparkle classes start with SPU or SU, and imported symbols end with "(from Sparkle)".
readonly SPARKLE_SYMBOLS='(^|[^A-Za-z])SPU[A-Z]|SUAppcast|SUUpdater|Sparkle'
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
readonly REPO_ROOT

work_dir=""
failures=0
skipped=0

pass() { echo "PASS: $*"; }

fail() {
  echo "FAIL: $*"
  failures=$((failures + 1))
}

skip() {
  echo "SKIP: $*"
  skipped=$((skipped + 1))
}

die() {
  echo "Error: $*" >&2
  exit 2
}

# Print each line of the text with an indent.
print_list() { sed 's/^/      /' <<<"$1"; }

# Remove from Launch Services each app in the folder, then delete the folder.
cleanup() {
  [[ -n "$work_dir" && -d "$work_dir" ]] || return 0
  local app
  while IFS= read -r -d '' app; do
    "$LSREGISTER" -u "$app" 2>/dev/null || true
  done < <(find "$work_dir" -name '*.app' \( -type d -o -type l \) -print0)
  rm -rf "$work_dir"
  # SwiftPM puts empty lock files, named from the folder path, in TMPDIR.
  rm -f "${TMPDIR:-/tmp}"/*"$(basename "$work_dir")"_*.lock
}

# Archive the topway scheme into the temporary folder.
archive_app_store_build() {
  echo "Archiving the topway scheme into $work_dir. This can take some minutes."
  xcodebuild -quiet \
    -project "$REPO_ROOT/topway.xcodeproj" \
    -scheme topway \
    -configuration Release \
    -destination 'generic/platform=macOS' \
    -derivedDataPath "$work_dir/DerivedData" \
    -archivePath "$work_dir/topway.xcarchive" \
    CODE_SIGNING_ALLOWED=NO \
    RAILWAY_OAUTH_CLIENT_ID= \
    archive
}

# Print the path of the entitlements file of the topway target.
target_entitlements_file() {
  local setting
  setting=$(xcodebuild -project "$REPO_ROOT/topway.xcodeproj" -target topway \
    -configuration Release -showBuildSettings 2>/dev/null |
    sed -n 's/^ *CODE_SIGN_ENTITLEMENTS = //p')
  [[ -n "$setting" ]] || die "The topway target has no CODE_SIGN_ENTITLEMENTS setting."
  echo "$REPO_ROOT/$setting"
}

# Print the path of the app in an archive or the path of an app.
app_of() {
  local target="${1%/}" app_path
  case "$target" in
    *.xcarchive)
      app_path=$(/usr/libexec/PlistBuddy -c 'Print :ApplicationProperties:ApplicationPath' \
        "$target/Info.plist" 2>/dev/null) || die "The archive has no app: $target"
      echo "$target/Products/$app_path"
      ;;
    *.app) echo "$target" ;;
    *) die "Give the path of an .xcarchive or an .app. $USAGE" ;;
  esac
}

plist_value() { /usr/libexec/PlistBuddy -c "Print :$1" "$2" 2>/dev/null || echo "(none)"; }

# Check 1: the app has no Sparkle framework, XPC service, app, bundle or library.
# The list of find goes in a file, because find in a process substitution does not
# give its exit status: a part of the app that find cannot read would then pass.
check_no_sparkle_bundles() {
  local path list="$work_dir/bundles.list" found=()
  if ! find "$1" -iname '*sparkle*' \( -name '*.framework' -o -name '*.xpc' \
    -o -name '*.app' -o -name '*.bundle' -o -name '*.dylib' \) -print0 >"$list"; then
    fail "find cannot read all of the app, so the script cannot look for Sparkle bundles."
    return 0
  fi
  while IFS= read -r -d '' path; do
    found+=("${path#"$1/"}")
  done <"$list"

  if ((${#found[@]} == 0)); then
    pass "The app has no Sparkle framework, XPC service or bundle."
  else
    fail "The app has Sparkle code:"
    print_list "$(printf '%s\n' "${found[@]}")"
  fi
}

# Check 2: no Mach-O file links Sparkle or has Sparkle symbols. A stripped binary still
# lists the symbols that it imports, so nm also finds Sparkle in a Release build. For a
# universal binary, otool and nm read only the slice of this Mac, so -arch all is
# necessary to read each slice.
check_no_sparkle_in_binaries() {
  local file name libraries symbols list="$work_dir/files.list" count=0 problems=()
  if ! find "$1" -type f -print0 >"$list"; then
    fail "find cannot read all of the app, so the script cannot examine each Mach-O file."
    return 0
  fi
  while IFS= read -r -d '' file; do
    [[ "$(file -b "$file")" == Mach-O* ]] || continue
    count=$((count + 1))
    name="${file#"$1/"}"
    if ! libraries=$(otool -L -X -arch all "$file" 2>/dev/null); then
      problems+=("otool cannot read the libraries of $name.")
      continue
    fi
    if grep -qi sparkle <<<"$libraries"; then
      problems+=("$name links Sparkle.")
    fi
    if ! symbols=$(nm -m -arch all "$file" 2>/dev/null); then
      problems+=("nm cannot read the symbols of $name.")
      continue
    fi
    # Remove the "<path> (for architecture ...):" lines, because the path is not a symbol.
    symbols=$(grep -v ':$' <<<"$symbols" || true)
    if grep -qE "$SPARKLE_SYMBOLS" <<<"$symbols"; then
      problems+=("$name has Sparkle symbols.")
    fi
  done <"$list"

  if ((count == 0)); then
    fail "The app has no Mach-O file to examine."
  elif ((${#problems[@]} == 0)); then
    pass "No Mach-O file links Sparkle or has Sparkle symbols. Mach-O files examined: $count."
  else
    fail "Mach-O files with Sparkle:"
    print_list "$(printf '%s\n' "${problems[@]}")"
  fi
}

# Check 3: Info.plist has no Sparkle keys. All Sparkle keys start with SU.
check_no_sparkle_info_keys() {
  local xml keys
  xml=$(plutil -convert xml1 -o - "$1/Contents/Info.plist")
  keys=$(grep -oE '<key>SU[A-Z][A-Za-z]*</key>' <<<"$xml" | sed 's/<[^>]*>//g' || true)
  if [[ -z "$keys" ]]; then
    pass "Info.plist has no Sparkle (SU) keys."
  else
    fail "Info.plist has Sparkle keys:"
    print_list "$keys"
  fi
}

# Check 4: the entitlements have no mach-lookup exception for the Sparkle installer
# (names that end with -spks or -spki). A signed app has its entitlements in the
# signature. For an unsigned app, examine the entitlements file of the target (only
# when this script made the archive).
check_no_sparkle_exceptions() {
  local app="$1" target_file="$2" entitlements source exceptions
  if [[ -f "$app/Contents/_CodeSignature/CodeResources" ]]; then
    entitlements="$work_dir/entitlements.plist"
    codesign -d --entitlements - --xml "$app" >"$entitlements" 2>/dev/null ||
      die "codesign cannot read the signature of $app"
    source="the signature of the app"
  elif [[ -n "$target_file" ]]; then
    entitlements="$target_file"
    source="${target_file#"$REPO_ROOT/"}"
    echo "The app is not signed. The script examines the entitlements file of the topway target: $source"
  else
    skip "The app is not signed, so it has no entitlements to examine."
    return 0
  fi

  if [[ ! -s "$entitlements" ]]; then
    pass "No entitlements in $source, so no Sparkle mach-lookup exception."
    return 0
  fi
  plutil -lint -s "$entitlements" || die "The entitlements are not a valid property list: $source"
  exceptions=$(/usr/libexec/PlistBuddy -c "Print :$MACH_LOOKUP_KEY" "$entitlements" 2>/dev/null || true)
  exceptions=$(grep -E -- '-spk[si]$' <<<"$exceptions" | sed 's/^ *//' || true)
  if [[ -z "$exceptions" ]]; then
    pass "No -spks or -spki mach-lookup exception in $source."
  else
    fail "Sparkle mach-lookup exceptions in $source:"
    print_list "$exceptions"
  fi
}

# Check 5: the bundle ID is the App Store one. Also print what the script examines.
check_identity() {
  local plist="$1/Contents/Info.plist" bundle_id version build
  bundle_id=$(plist_value CFBundleIdentifier "$plist")
  version=$(plist_value CFBundleShortVersionString "$plist")
  build=$(plist_value CFBundleVersion "$plist")
  echo "App: $1"
  echo "Version: $version ($build)"
  if [[ "$bundle_id" == "$BUNDLE_ID" ]]; then
    pass "The bundle ID is $BUNDLE_ID."
  else
    fail "The bundle ID is $bundle_id, not $BUNDLE_ID."
  fi
}

main() {
  case "${1:-}" in
    -h | --help)
      echo "$USAGE"
      exit 0
      ;;
  esac
  (($# <= 1)) || die "Give one path or no path. $USAGE"

  trap cleanup EXIT
  trap 'exit 130' INT TERM
  work_dir=$(mktemp -d -t topway-app-store-check)

  local app target_file=""
  if (($# == 0)); then
    archive_app_store_build
    app=$(app_of "$work_dir/topway.xcarchive")
    target_file=$(target_entitlements_file)
  else
    app=$(app_of "$1")
  fi
  [[ -f "$app/Contents/Info.plist" ]] || die "This is not an app bundle: $app"

  check_identity "$app"
  check_no_sparkle_bundles "$app"
  check_no_sparkle_in_binaries "$app"
  check_no_sparkle_info_keys "$app"
  check_no_sparkle_exceptions "$app" "$target_file"

  if ((failures == 0 && skipped == 0)); then
    echo "Result: all checks passed. The app has no Sparkle."
  elif ((failures == 0)); then
    echo "Result: no check failed, but $skipped of 5 checks did not run."
  else
    echo "Result: $failures of 5 checks failed."
    exit 1
  fi
}

main "$@"
