# Picture in Picture - Not Applicable

## Status: Out of Scope

Picture in Picture (PiP) functionality is **not applicable** to Roots in its current implementation.

## Rationale

### No Media Playback
Roots does not include:
- Video player (`AVPlayer`)
- Lecture video playback
- Screen recording playback
- Video conferencing UI
- Media streaming capabilities

### No AVKit Usage
Code survey confirms zero usage of:
- `AVPictureInPictureController`
- `AVPlayerLayer`
- `AVKit` framework
- `AVFoundation` video playback

### Timer is Not Video
The timer functionality:
- Uses standard SwiftUI views and state updates
- No video/media pipeline
- Does not benefit from PiP's media-specific optimizations
- Better served by multi-window support (allows timer in separate window)

## Future Considerations

PiP would become applicable if Roots adds:

1. **Lecture Video Playback**
   - Embedded course lecture videos
   - Recording playback within app
   - YouTube/Vimeo integration with custom player

2. **Video Conferencing**
   - Study group video calls
   - Office hours with instructors
   - Screen sharing sessions

3. **Screen Recording**
   - Tutorial/walkthrough playback
   - Recorded study sessions
   - Review of timed practice tests

## Alternative: Multi-Window Support

For productivity workflows requiring "always visible" content:
- Use multi-window support (iPadOS/macOS)
- Open timer in separate window
- Position window for reference while working
- Native window management provides superior experience

## References

- [AVPictureInPictureController Documentation](https://developer.apple.com/documentation/avkit/avpictureinpicturecontroller)
- Apple HIG: Picture in Picture guidelines apply to video content only
