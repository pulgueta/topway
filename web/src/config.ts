// The links of the website that the owner of Topway must set. This is the only file to change.
//
// While a link is null, the download page shows "Coming soon" in place of its button, so the
// site never links to a page that does not exist. The build also prints a warning for each
// link that is null.

/**
 * TODO(owner): Put the Mac App Store URL of Topway here when App Review approves the app.
 * Copy it from App Store Connect, for example "https://apps.apple.com/app/topway/id1234567890".
 */
export const appStoreUrl: string | null = null;

/**
 * The Polar checkout link of the DMG product. The product has a File Downloads benefit with the
 * DMG. See "Sell the DMG with Polar" in docs/direct-distribution.md. The page shows no price:
 * set the price in Polar.
 */
export const polarUrl: string | null =
  "https://buy.polar.sh/polar_cl_VqIm4Hg6TFZqiXz96Z3h7Y2GZ2HbvfHb5KT0I3WYZQq";

/** The GitHub repository. Topway is MIT licensed, so anyone can build it from source. */
export const repositoryUrl = "https://github.com/pulgueta/topway";

/** The build steps in the README of the repository. */
export const buildFromSourceUrl = `${repositoryUrl}#build-from-source`;

/** The issue form for a problem report, the same link as in the README. */
export const reportProblemUrl = `${repositoryUrl}/issues/new/choose`;

/**
 * The privacy policy. The site links to PRIVACY.md on GitHub, so the policy has one source and
 * a reader can see the history of each change. public/_redirects sends /privacy to this URL.
 */
export const privacyPolicyUrl = `${repositoryUrl}/blob/main/PRIVACY.md`;
