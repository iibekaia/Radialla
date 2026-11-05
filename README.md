# Radialla — iPhone radio app

Open `radialla.xcodeproj`, select the `radialla` scheme and run on iOS 17 or later. Both the app and widget must use the same signing Team. Preserve the existing app bundle identifier `ge.globeradio.app` when updating an installed copy, so local data is retained.

The app uses SwiftUI, MapKit, AVPlayer and [Radio Browser](https://docs.radio-browser.info/), with no third-party packages. Station search, genre filtering and transcription are intentionally absent. All Swift source files are explicitly registered in the Xcode targets.

## Responsibilities

- `Stores/RadioStore.swift`: playback coordination, observable UI state, station queue and favorites.
- `Stores/RadioStore+Catalog.swift`: incremental catalog loading, refresh and merging by station ID.
- `Stores/RadioStore+Widget.swift`: validated widget deep links.
- `Services/PlaybackSystemControls.swift`: remote commands, audio interruptions, output removal and system Now Playing publication.
- `Services/PlaybackItemObserver.swift`: player/item KVO and current-item notifications, with stale-item guards and observer cleanup.
- `Services/PlaybackRecoveryController.swift`: network monitoring across Wi-Fi and cellular, retry scheduling and cancellation.
- `Services/StreamMetadataReader.swift`: ordered timed metadata updates and stale-output protection.
- `Services/NowPlayingArtworkController.swift`: bounded artwork fetching, image downsampling and caching.
- `Services/StationCatalogService.swift`: network requests, JSON decoding and atomic disk caching on a separate actor.
- `Services/StationMapIndex.swift`: viewport filtering and clustering, including date-line wrapping.
- `Services/LocationController.swift`: main-actor location handling, country lookup and explicit map focus.
- `Services/SpeedVolumeController.swift` and `SpeedVolumePolicy.swift`: GPS-driven, bounded player gain.
- `Services/LastStationStore.swift` and `Stores/SavedTracksStore.swift`: independent local persistence.
- `Services/ThemeResolver.swift` and `Localization.swift`: appearance, eight interface languages and status formatting.
- `Views/ExplorerView.swift`: screen composition and lifecycle coordination.
- `Views/ExplorerHeader.swift`, `ExplorerDrawer.swift`, `ExplorerMenu.swift`: branding and full-screen menu.
- `Views/StationMapView.swift`, `StationListView.swift`, `StationRowView.swift`: map/list presentation and resize affordances.
- `Views/RadioSheetStyle.swift`: shared sheet handle and spacing.
- `Views/YouTubeButton.swift`, `PlayerShortcutStyle.swift`: shared song-search shortcut and appearance.
- `Views/StationArtwork.swift`, `PlayerTransportControls.swift`, `PlayerMuteButton.swift`, `StationFavoriteButton.swift`: reusable player components.
- `Views/MiniPlayerView.swift`, `ExpandedPlayerView.swift`: compact and expanded composition.
- `Shared/WidgetStationSnapshot.swift` and `RadiallaWidget/`: the shared snapshot, widget provider, view and configuration.

Keep networking and playback outside views. Extract reusable behavior rather than copying it into another player or growing a catch-all file. Follow `AGENTS.md`.

Views obtain custom translations through the `@Localized` dynamic property, which observes SwiftUI's locale environment. This invalidates open menus and nested controls immediately when the language changes, without recreating the view or losing its state. Non-view messages continue to resolve the selected language from persistent preferences.

## Catalog and map

Restore the disk snapshot immediately. Allow up to 1.5 seconds for the initial country result, then prioritize country pages of 200 stations while the global scan loads 500-item pages, separated by 350 ms. Country lookup is not a city-radius query. JSON decoding and cache I/O do not run on the UI actor.

Save progress every 2,000 global records and at completion/country-load boundaries. Snapshots younger than six hours resume their offset; older snapshots stay visible while scanning restarts. Indexed merging updates changed records without adding duplicate IDs. Catalog progress does not overwrite playback/reconnection messages.

Map clustering reuses the already-filtered station subset. The favorites list intentionally includes favorites outside the current viewport, while map markers remain viewport-filtered. Frequency expressions are compiled once; displayed frequencies are inferred from station names, not authoritative metadata.

On launch, focus the restored station when it has coordinates; otherwise center once on the first location result. Returning from the background refreshes location-dependent data without moving the map. The location button still explicitly requests map focus. The map heart filters favorites and zooms to the first listed favorite when enabled. Selecting/skipping a station never zooms the camera; the active marker animates. List resizing has two resting heights and hides map controls until restored.

## Playback and recovery

The last successfully playing station is stored with its stream URL and display metadata. A cold launch attempts to resume its live broadcast without expanding the player. Failed selections do not replace this saved record. Invalid saved data is discarded. The shared `Station.streamURL` validation is used by playback and restoration.

Wi-Fi/cellular handoffs that AVPlayer handles seamlessly do not force a restart. A stalled stream gets an eight-second grace period. Failure retries back off through 2, 4, 8, 16 and 30 seconds; buffering retries use at least eight seconds. Offline paths pause retries until connectivity returns. Availability of a path does not imply the server is reachable.

Manual pause, output removal and station changes cancel pending work. Interruption recovery also checks Apple's shouldResume hint; a manual pause during an interruption cancels automatic resumption. Muting is independent of retry and system output volume. The expanded player opens only for an explicit station selection or a tap on the mini player's content.

### Network selection

Audio requests allow cellular access. The system chooses the available Wi-Fi or cellular path; there is no mobile-data toggle. Network recovery preserves manual pause and does not restart streams that continue playing through a handoff.

### Automatic speed-based volume

With location permission, player gain decreases from 1.0 at 110 km/h to 0.65 at 120 km/h and remains bounded above that speed. Slowing reverses the curve; below 110 restores normal gain. Changes ramp smoothly over roughly 3.5 seconds for the full range. There is no toggle.

Invalid/inaccurate GPS samples are ignored. After ten seconds without valid data, normal gain is restored smoothly. Background location is enabled while playing, with the system indicator. No speed history is saved or uploaded. This is not a calibrated speedometer, a safety warning or an automotive standard.

## Song metadata and artwork

Timed title/artist fields are processed in order. Unrelated metadata does not cancel an in-flight song update; title and artist arriving separately are combined. Switching playback items clears old metadata and rejects stale callbacks. The `Artist - Title` split is a convention-based inference. Only metadata supplied through AVFoundation is displayed; no microphone or audio recognition is used.

The song card can save title, artist, source station and date locally. Saved songs are available from the menu, with swipe-to-delete and the same YouTube search shortcut as the player. Saving displays a confirmation; the menu shows the current saved count. Audio is not recorded or downloaded.

System Now Playing receives the station logo, with the bundled RadioLogo as an immediate fallback. Logo fetching has a 12-second request timeout and a 5 MB byte limit enforced during transfer, with a Content-Length precheck. Images are downsampled to 512 pixels off the UI actor and cached within a bounded memory budget. Failed logo requests can retry on a later playback attempt. Old requests cannot replace a newer station's artwork.

iOS controls artwork presentation on the Lock Screen, Control Center and standard audio Dynamic Island. No separate Live Activity or custom island layout is added.

## Home Screen widget

The small and medium WidgetKit widgets show the last successfully played station. Tapping opens `radialla://play-last` in the app and starts/resumes that station; existing playback of it is not restarted. This is launch-and-play, not an in-place playback toggle.

Both targets use App Group `group.ge.globeradio.app`. The shared snapshot contains station ID, display name, country and language, not the stream URL. Changed snapshots request a WidgetKit reload; the OS controls timing. The original app-side last-station record remains authoritative.

Device setup:
1. Assign the same Team to `radialla` and `RadiallaWidget`.
2. Enable/register the shared App Group for `ge.globeradio.app` and `ge.globeradio.app.widget`; matching entitlement files are included.
3. Run the `radialla` scheme, which embeds the widget automatically.
4. Play a station successfully, then add Radialla from the iPhone Home Screen widget gallery.

## Validation and remaining work

Current cleanup validation and limitations are recorded in `research/code-sanitization-2026-11-05.md`. The current environment provides Command Line Tools, so syntax, project/localization integrity and standalone model/service checks are available; a full iOS app/widget build requires Xcode. No permanent unit-test target currently exists. Standalone checks do not certify actual stream reliability.

On the user's physical iPhone, recheck:
- Rapid station changes, metadata updates and unavailable logos.
- Lock Screen/remote controls and playback after calls.
- Manual pause during a call, headphone/Bluetooth removal and network loss.
- Wi-Fi/cellular transitions and recovery after connectivity returns.
- Saved songs, last-station restoration and widget cold/warm launches.
- Menu scrolling/closing, map resizing and no camera reset after foregrounding.
- GPS volume behavior, battery use, Dynamic Type and VoiceOver.

Dedicated CarPlay scenes and the audio entitlement are not implemented. Other production work includes stream/catalog licensing review, privacy disclosures, API mirror discovery, stable pagination against changing server data, full favorite-record persistence and broader performance/accessibility profiling. iOS may suspend recovery when background audio stops. Live metadata support depends on each stream.

## Apple references

- [Audio interruptions](https://developer.apple.com/documentation/avfaudio/handling-audio-interruptions)
- [Player metadata output](https://developer.apple.com/documentation/avfoundation/avplayeritemmetadataoutput)
- [System Now Playing](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter)
- [Network path monitoring](https://developer.apple.com/documentation/network/nwpathmonitor)
- [Cellular audio policy](https://developer.apple.com/documentation/avfoundation/avurlassetallowscellularaccesskey)
- [Background location](https://developer.apple.com/documentation/corelocation/cllocationmanager/allowsbackgroundlocationupdates)
- [Widget deep links](https://developer.apple.com/documentation/widgetkit/linking-to-specific-app-scenes-from-your-widget-or-live-activity)
- [App Groups](https://developer.apple.com/documentation/xcode/configuring-app-groups)
