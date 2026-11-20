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
 * TODO(owner): Put the Polar URL for the DMG here. First decide how Polar works (task T9):
 * a public DMG with a Polar purchase to support the developer, or a Polar file download.
 * The page text does not depend on that choice and shows no price.
 */
export const polarUrl: string | null = null;

/** The GitHub repository. Topway is MIT licensed, so anyone can build it from source. */
export const repositoryUrl = "https://github.com/pulgueta/topway";

/** The build steps in the README of the repository. */
export const buildFromSourceUrl = `${repositoryUrl}#build-from-source`;

/** The issue form for a problem report, the same link as in the README. */
export const reportProblemUrl = `${repositoryUrl}/issues/new/choose`;

/** The source of the privacy page, so a reader can see the history of each change. */
export const privacySourceUrl = `${repositoryUrl}/blob/main/PRIVACY.md`;
