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

State includes `revision`, `members`, optional `playback` and optional `viewport`.
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

Explicit disconnect, WebSocket close code 4401, or HTTP 401 clears controller mode and returns to local
controls, paused. Local playback resumes on the next user play action. Transient
network failure keeps controller mode active so local audio cannot start
unexpectedly. Failed commands are reported in the pairing screen and are not
replayed automatically. Disconnect revokes server membership before forgetting
the token; if the leave request fails, the user can retry.

## Verification

Standalone checks cover QR validation, command JSON, viewport conversion,
joining, command ordering, disconnect and expired credentials.
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
changes or recovery while paired. Verify browser autoplay permission separately.
