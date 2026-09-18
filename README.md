# Nihongo Trainer (Flutter / Android)

A complete Flutter rewrite of the NihongoTrainer desktop app — same 320
sentences, 536 kanji, and 533 vocabulary words, now as a touch-first mobile
app with swipe gestures, a customizable background (your own photo, like a
chat wallpaper), and a custom launcher icon.

**👉 Start here: [`SETUP_INSTRUCTIONS.md`](./SETUP_INSTRUCTIONS.md)** — it
covers two ways to get from this code to an installed app:

- **Option A (recommended):** upload this folder to a free GitHub repo
  and a included automation (GitHub Actions) builds the APK for you in
  the cloud — no installs on your computer at all.
- **Option B:** build it locally with the Flutter SDK, useful if you want
  to tinker with live-reload.

## Quick summary

- All app code, data, font, and icon are already here and finished.
- Either build path takes about 10–30 minutes, mostly waiting, not typing.
- You end up with a real `app-release.apk` you install like any other app,
  and can rebuild any time (e.g. after swapping the icon image).

## What's new: Daily Review (spaced repetition)

Every vocab word and kanji now tracks its own learning progress on-device
(no account, no server). Rate each review **Again / Hard / Good / Easy**
and the app schedules when it should come back — missed items sooner,
well-known ones much later. The home screen's top banner always shows
what's due today and is the fastest way into a review session; Flashcards
mode feeds the same progress now too (swipe up = Good, swipe down =
Again), so nothing you do in the app is thrown away when you leave a
screen or switch filters. Existing modes (Learn Sentences, Learn Kanji,
Test) are unchanged.
