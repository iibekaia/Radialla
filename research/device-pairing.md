# Device pairing integration

The app menu now contains Device pairing. It can generate an eight-digit code
or join using a code from the web. The server URL is configured in
`DevicePairingService.swift` and currently points to the Radialla Railway service.

This client expects the pairing API being developed independently in radialla-web.
Those server changes must be deployed before the screen works; a successful
`/api/health` response alone does not mean the pairing endpoints exist.

## Wire contract

All requests use POST with JSON and `Cache-Control: no-store` responses.
Authenticated requests send `Authorization: Bearer <token>`, never tokens in URLs.

- `/api/pairing/create` `{}` -> `{token, code, expiresAt, state}`
- `/api/pairing/join` `{code}` -> `{token, state}`
- `/api/pairing/code` `{}` (authenticated) -> `{code, expiresAt}`
- `/api/pairing/claim` `{clientId}` (authenticated) -> state
- `/api/pairing/wait` `{afterRevision}` (authenticated) -> state; long poll up to 25 seconds
- `/api/pairing/leave` `{}` (authenticated) -> `{ok:true}`

State is `{revision: integer, owner: string|null, members: integer}`. Expiry is
Unix time in milliseconds. Client IDs are new UUIDs per running app instance.
A 401 response clears the saved credentials and requires pairing again.

The app saves its token in device-only Keychain storage. No account is required.
Disconnect revokes server membership before clearing credentials locally.
The initial server implementation stores pairing state in memory: a server
restart/redeployment can require pairing again. It requires one server instance.

Playback claims are sent after AVPlayer confirms playing. Loading and failed
streams do not claim playback. Remote owner changes pause through RadioStore,
which also cancels automatic recovery and clears interruption-resume intent.
Revision checks ignore old responses; pending claims suppress stale remote pauses.
Internet loss does not stop local audio, and exclusive playback cannot be
guaranteed while a device is disconnected or the OS has suspended the process.

## Verification

Swift parsing, service type checking, plist and project-format validation can run
with Command Line Tools. A full app build requires Xcode with the iOS SDK.

On real devices, check web-to-iOS and iOS-to-web switching, screen-locked audio,
background/network reconnection, expired codes, server restart, disconnect,
loading/failed streams, and simultaneous playback starts. iOS background execution
must be verified on hardware; the HTTP client does not wake a suspended app.
