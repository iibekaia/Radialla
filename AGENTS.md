# radialla development conventions

- Keep views focused; extract reusable UI into separate SwiftUI view files.
- Keep networking, location, map calculations, localization and playback outside presentation components.
- Do not accumulate unrelated features in a single file. Register new Swift files in the Xcode target.
- Preserve existing behavior and translations when refactoring. Prefer supported public Apple APIs and maintain the declared iOS deployment target.
- Build the target after code changes. Report device-only checks separately from compilation.
