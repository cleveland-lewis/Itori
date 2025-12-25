# Picture in Picture (PiP)

Roots currently has no AVPlayer-based media viewer, video call UI, or embedded player of any kind. The codebase has no `AVPlayer`/`AVKit` imports, so there is no native media surface to attach an `AVPictureInPictureController` to. Implementing PiP today would therefore require adding first-party media playback or a call surface.

If we introduce an embedded lecture player, meeting view, or another media-driven screen in the future, the PiP implementation would live in the screen’s AV layer (`AVPictureInPictureController` with delegate) and would register the same `WindowGroup` scenes (iOS and macOS) that already host the rest of the app. Until such media surfaces exist, PiP remains out of scope because there is no content that benefits from floating playback.
