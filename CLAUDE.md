# Kleinanzeigen Pusher

A browser extension (Manifest V3, plain JS, no build step) that **re-posts**
("Neu einstellen") old ads on kleinanzeigen.de with one click. A re-post creates
a fresh listing, which puts the ad back at the top of the search results. Pushing
an ad to the top is otherwise a paid feature on kleinanzeigen.

[README.md](README.md) is the main documentation: how it works, the
kleinanzeigen endpoints the extension relies on, and the manual test checklist.
Read it first.

## Branches and remotes
- `upstream` = `jhinter/kleinanzeigen-pusher` (the original). It rewrote the
  extension as v2.0.0 (Nov 2026) and replaced our earlier fetch-patching fix
  (`pages/…`, `world: "MAIN"`) with the `formdata`-event approach below.
- `origin` = `vin-ni/kleinanzeigen-pusher` (Vinzenz's fork).
- `master` follows upstream. Pull updates with `git fetch upstream && git merge upstream/master`.
- `firefox` = master plus the Firefox manifest and packaging. Merge master into it after upstream updates.

## The core trick
The edit page (`/p-anzeige-bearbeiten.html?adId=<id>`) submits `new FormData(form)`
to the Astro action `postListingWeb.submitListing`. If the hidden `adId` field
is set, the backend updates the ad. If it is empty, the backend creates a new ad.
[src/edit-ad.js](src/edit-ad.js) listens for the `formdata` event (capture phase)
and blanks `adId`, but only when the URL has `&ekp=recreate`. Changing the DOM
input does not work, because React restores it.

The old ad stays live. Back on *Meine Anzeigen*, [src/my-ads.js](src/my-ads.js)
finds the new ad and offers to delete the old one, which needs an explicit click.

## Rules (from upstream)
No extension permissions, no remote code, and no requests to hosts other than
kleinanzeigen.de. Never delete anything without an explicit click. User-facing
text is German. Classes and globals are prefixed `ekp`.
