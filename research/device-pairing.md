# Device pairing and controller mode

The iOS app joins the web receiver by scanning its one-use QR code. It never
creates pairing codes. The server base is configured in DevicePairingService.
The web receiver and server must include the controller command API.

## Wire contract

Explicit actions use POST JSON. Authenticated HTTP requests send
`Authorization: Bearer <token>`; credentials never appear in URLs.

- `/api/pairing/join` `{code}` -> `{token, state}`
- `/api/pairing/command` `{type:"play", stationId}` -> state
- `/api/pairing/command` `{type:"pause"}` -> state
- `/api/pairing/command` `{type:"viewport", latitude, longitude, zoom}` -> state
- `wss://<server>/api/pairing/socket`: authenticate with first text frame `{token}`;
  receive `{type:"state", state}` snapshots and `{type:"heartbeat"}` every 20 seconds.
  The app no longer calls the legacy HTTP `/wait` endpoint.
- `/api/pairing/leave` `{}` -> `{ok:true}`

State includes `revision`, `members`, `receiverOnline`, optional `playback` and optional `viewport`.
`receiverOnline` tracks live authenticated browser sockets for the device that
created the pairing. A phone socket or saved browser membership alone does not
count. Older servers omit the field, so browser presence requires the updated server.
Playback commands contain `type`, optional `stationId` and `revision`. The app
reflects server-accepted playback intent; this API does not report whether the
browser's audio is actually audible. Browser autoplay policy may require a user
gesture on the receiver before audio can start.

## Mobile behavior

A saved device-only Keychain token restores controller mode before the last
station can autoplay. Joining stops AVPlayer, removes its item and metadata,
cancels recovery/interruption resumption, and deactivates the audio session.
Station selection, next/previous, and play/pause send ordered commands instead of
starting local audio. Map camera changes send a viewport; the longitude span is
converted to web zoom and values are clamped to the server's supported bounds.
Map browsing does not automatically select a different station in controller mode.
The app sends no legacy audio ownership claims.

The subscription reconnects with exponential backoff from 0.5 to 8 seconds,
receiving a fresh snapshot after reconnect. A 10-second initial deadline and
45-second message watchdog close stalled connections. Credentials stay out of
WebSocket URLs.

If the browser goes offline or the phone loses its connection to the pairing
server, the app waits eight seconds before switching to its local player. It
resumes the selected station when playback was requested and stays paused
otherwise. A browser that loses power without closing its socket is detected
by the server heartbeat before this grace period starts.

The Keychain token and subscription survive temporary receiver loss. When the
browser reconnects to the same pairing, the app stops local audio, returns to
controller mode and sends the phone's current play or pause intent to the browser.
An expired token clears the saved pairing. Explicit disconnect revokes membership
before forgetting the token and leaves remote playback under browser control.
If the leave request fails, the user can retry.

## Verification

Standalone checks cover QR validation, command JSON, viewport conversion,
joining, command ordering, disconnect, expired credentials and local fallback.
`tests/pairing-controller/ControllerTests.swift` also accepts a disposable localhost
server origin to verify that the same pairing restores controller mode when the
receiver returns.
`tests/pairing-socket/SocketTests.swift` runs against a disposable local
radialla-web server and verifies first-frame authentication, live state delivery,
fresh snapshots after reconnect and revoked-token close code 4401. Compile it
with `PairingSocketConnection.swift` and pass the localhost server origin as its
first argument. Never point this integration check at production. Service type
checking and Swift parsing can run with Command Line Tools. A full iOS app build
requires Xcode with the iOS SDK.

On hardware with the matching web deployment, verify pairing while the phone is
playing, cold launch with saved pairing, station selection, rapid play/pause,
map pan/zoom, network loss/recovery, token expiry, explicit disconnect, and local
playback afterward. Check that no phone audio starts from interruptions, route
changes or recovery while the app is controlling the browser. Verify that closing
and reopening the browser hands playback over in both directions, including when
paused, and check background suspension and browser autoplay separately.
