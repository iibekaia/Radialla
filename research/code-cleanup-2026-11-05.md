# Code cleanup — 2026-11-05

Scope: app, widget and shared Swift sources; static review with an independent second pass. Existing features, bundle IDs, entitlements and saved-data keys are preserved. No packages, commits or permanent test framework added.

## Corrected issues

- Timed metadata callbacks could cancel a pending song update when an unrelated metadata field arrived. Relevant reads are now serialized, separately delivered title/artist updates work in either order, and detaching cancels and drops all old queued work.
- Failed station-logo downloads were treated as completed because fallback artwork existed. Later playback attempts can retry; completed images remain cached. Downloads now stop at the byte limit instead of checking size only after transferring the full response.
- A manual pause during an audio interruption could be overwritten by automatic resume when the interruption ended. User pause clears the saved resume intent; Apple's shouldResume hint is still required.
- Discarding a playback item for network policy had duplicated cleanup paths and could leave observation/metadata work active. One helper now clears the item, item observation, metadata and speed-driven gain updates.
- The refresh action could return immediately for a completed cached catalog. Explicit refresh now restarts scanning without blanking the current list. Indexed merging updates existing station records without duplicate IDs, and a revision refreshes the UI even when the count is unchanged.
- Catalog progress could overwrite playback/reconnection status. The two status sources are now separate.
- Playback and last-station restoration used different URL checks. Both now use Station.streamURL, which requires an HTTP(S) scheme and nonempty host.
- Frequency regular expressions were compiled on repeated view reads. They are now shared immutable expressions.
- Map refresh filtered the full catalog twice. Clustering now reuses the visible subset, preserving the distinct global-favorites and viewport-marker behavior.
- Transient location failures no longer replace a known automatic language with English; stale error text is cleared on a new successful request. Location callbacks explicitly belong to the main actor.
- Steady speed gain no longer writes the same player volume on every timer tick.
- Nine obsolete localization keys were removed consistently from all eight languages, after checking Swift references.

## Extracted components

- PlaybackSystemControls: remote commands, audio-session interruptions/output changes and Now Playing publication.
- PlaybackItemObserver: player/item KVO, current-item notifications and cleanup.
- PlayerTransportControls: shared previous/play-pause/next controls.
- ExpandedPlayerControls: expanded-player mute/favorite/transport/Shazam composition.
- StationArtwork: shared station-logo view, no longer declared inside the expanded player.

RadioStore remains the coordinator rather than becoming a collection of cross-file private-property exceptions. View state exposed for selection, playback and favorites is now read-only outside the store. Every new file is registered in the target. README structure and ownership notes were updated.

## Validation

- Debug and optimized Release builds of the app plus embedded WidgetKit extension, with signing disabled.
- Temporary macOS executable checks against production model/service sources: URL/frequency parsing, map viewport/date-line filtering, last-station persistence, saved-song deduplication/removal, widget snapshots and stream metadata ordering/stale-output handling.
- Recovery checks: successful-playback cancellation, manual pause, station changes, offline return, cellular blocking, Wi-Fi return and preference changes.
- Catalog checks against the production catalog extension with an in-memory API fixture: fresh-cache fast path, explicit refresh, metadata replacement, ID deduplication, revision changes and saved snapshot content.
- Property-list and all translation-file syntax validation; source-registration and duplicate project-object-ID checks.

## Not certified by these checks

Physical-device playback after calls, Bluetooth changes, real network handoffs, screen-locked recovery, GPS accuracy/battery use, actual station metadata coverage, artwork presentation and widget refresh timing still need the user's real-device regression pass. This cleanup is not a claim that all possible bugs are eliminated. API pagination can change while scanning, favorites still persist IDs rather than full station records, and dedicated CarPlay UI is not yet implemented.
