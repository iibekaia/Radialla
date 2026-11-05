# Code sanitization — 2026-11-05

## Changes

- Extracted the existing station row into `StationRowView`; preserved playback, favorites, equalizer, frequency and accessibility behavior. Registered the new file in the app target.
- Removed the unused Google song-search URL and unreachable forced-catalog-refresh branch after the corresponding menu actions were removed.
- Removed unused player-status and shortcut-style configuration while retaining the current appearance and behavior.
- Removed seven obsolete translation keys consistently from all eight languages. Replaced the catalog interruption message so it no longer suggests a removed refresh action.
- Normalized formatting in the touched player, list and explorer sources. Updated README ownership notes, restored-station map behavior, favorites, song shortcuts and automatic network selection.
- Preserved station identifiers, persistence keys, bundle IDs, entitlements and the iOS 17 deployment target.

## Verification

- All 55 app, widget and shared Swift files passed syntax parsing.
- All Swift files exist, have file references and belong to source build phases. No duplicate object IDs or duplicate source entries were found.
- Project, Info plists, entitlements and all translation files passed property-list validation. All eight languages have the same 61 keys; every key is referenced by Swift sources.
- A temporary macOS executable using production model/service sources passed checks for Unicode/punctuation in YouTube search URLs, title/artist parsing, saved-song toggling/removal and UserDefaults round trips, last-station restoration, favorites/viewport/date-line filtering, restored-station map regions, reconnection and cancellation after pause.
- Ten reusable SwiftUI components passed a macOS 14 type check against temporary RadioStore/theme stubs. This checks those components against the available SwiftUI SDK, not the real iOS target.
- Full iOS app/widget build was attempted but could not start: the active developer directory is `/Library/Developer/CommandLineTools`, and Xcode is unavailable. No successful iOS compilation is claimed for this pass.

## Device checks remaining

Check the map and favorites focus, resizing and sheet dismissal, saved-song confirmation/removal, YouTube handoff, Dynamic Type/VoiceOver and uninterrupted Wi-Fi/cellular playback on an actual iPhone. Temporary checks did not use the user's saved data or make network requests.
