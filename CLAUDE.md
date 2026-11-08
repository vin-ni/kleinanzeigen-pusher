# Kleinanzeigen Pusher

A Chrome extension (Manifest V3) that lets you **re-post** ("Neu einstellen") old
ads on kleinanzeigen.de with one click. Re-posting (as opposed to merely editing)
bumps the ad back to the top of search results, which is the whole point of the
tool.

## How it works

Two content scripts injected on two different kleinanzeigen pages (see
[manifest.json](manifest.json)):

### 1. Overview page — `pages/offer-overview/index.js`
Runs on `https://www.kleinanzeigen.de/m-meine-anzeigen.html*` (the "my ads" list).

- Finds every existing edit link (`a[href^='/p-anzeige-bearbeiten.html']`).
- For each one, clones the surrounding `<li>` and injects a green
  **"Neu einstellen"** button (`a.ekz-recreate`, styled in
  [styles.css](pages/offer-overview/styles.css)).
- The injected link points at the same edit page but with `&ekz-recreate=true`
  appended to the URL — this flag is how the second script knows to activate.

### 2. Edit page — `pages/offer-details/index.js`
Runs on `https://www.kleinanzeigen.de/p-anzeige-bearbeiten.html*`. Declared with
**`"world": "MAIN"`** and **`"run_at": "document_start"`** in the manifest — this
is essential (see below).

- Does nothing unless the URL contains `ekz-recreate=true`.
- **Patches `window.fetch`** so that the save request is intercepted.
- Cosmetically relabels the "Anzeige speichern" button to "Neu einstellen".

## The core trick (current implementation)

kleinanzeigen's edit page is a **React/Preact SPA**. Clicking "Anzeige speichern"
does NOT do a native form POST — it fires:

```
POST https://www.kleinanzeigen.de/_actions/postListingWeb.submitListing/
Content-Type: multipart/form-data
```

The multipart body includes a field **`adId`**. The rule that everything hinges on:

> The save request **with** `adId` → backend UPDATES the ad.
> The save request **without** `adId` → backend CREATES a new ad (bumped to top).

So the fix intercepts the `fetch`, checks for the `submitListing` URL, and calls
`body.delete("adId")` on the `FormData` before it's sent. Re-posting to the top is
otherwise a **paid** feature on kleinanzeigen ("nach oben schieben"); this gets the
same effect for free by creating a fresh listing.

### Why `"world": "MAIN"` + `document_start` matters
A normal content script runs in an **isolated world** — patching `window.fetch`
there does NOT affect the page's own `fetch`, so the interception would never fire.
`"world": "MAIN"` runs our script in the page's real JS context. `document_start`
ensures the patch is installed **before** the app captures a reference to `fetch`.

### Known fragility / what breaks if the site changes
- The save endpoint path (`_actions/postListingWeb.submitListing/`) or the field
  name (`adId`) could change → update [offer-details/index.js](pages/offer-details/index.js).
- If the app stops sending a `FormData` body (e.g. switches to a `Request` object,
  JSON, or a stream), the interceptor logs a warning and can't strip the id —
  the body handling would need extending.
- All interesting `console` logs are prefixed `[ekz]` for quick debugging.

### Re-post leaves the OLD ad live
Creating a new ad does NOT delete the original — you'll briefly have two copies.
Recommended flow: let the extension create the new (bumped) ad, then delete the old
one manually. (A future version could auto-delete the old ad after confirming the
new one was created, gated behind a confirmation.)

## How this was diagnosed
Captured a `.har` of a real save while logged in, found the single non-GET request
(`submitListing`), and confirmed the multipart body carried `adId`. If this breaks
again, re-capture a HAR of "Anzeige speichern" and re-check the endpoint + fields.

## Project layout
```
manifest.json                       extension manifest (MV3)
pages/offer-overview/index.js       injects the "Neu einstellen" buttons
pages/offer-overview/styles.css     green button styling
pages/offer-details/index.js        strips ad-id + submits as new ad
images/                             extension icons
```

## Testing / loading
Load unpacked in `chrome://extensions` (Developer mode → Load unpacked → repo
root). There is no build step, bundler, or package.json — plain JS + a manifest.

## Notes
- `offer-overview/index.js` uses a `MutationObserver` to inject buttons as the
  client-side ad list renders (the edit links aren't in the DOM at first paint).
  Links already processed are marked with `data-ekz-processed` to avoid dupes.
- No tests, no CI, no dependencies.
