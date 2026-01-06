# Adding Free Completion Sounds

## Recommended Free Sound Sources

### 1. Freesound.org (Best Option)
**License:** Creative Commons 0 (CC0) or CC-BY
**URL:** https://freesound.org

**Recommended Completion Sounds:**
- "Success Bell" by user: rhodesmas (CC0)
  - https://freesound.org/people/rhodesmas/sounds/320655/
- "Positive Notification" by user: Bertrof (CC0)
  - https://freesound.org/people/Bertrof/sounds/131657/
- "Achievement" by user: LittleRobotSoundFactory (CC-BY)
  - https://freesound.org/people/LittleRobotSoundFactory/sounds/270303/

### 2. Mixkit.co
**License:** Free for commercial use
**URL:** https://mixkit.co/free-sound-effects/

**Recommended:**
- "Correct answer tone" - mixkit-correct-answer-tone-2870.wav
- "Achievement bell" - mixkit-achievement-bell-600.wav

### 3. Zapsplat.com
**License:** Free with attribution
**URL:** https://www.zapsplat.com

## How to Add Sound Files

### Step 1: Download Sound
1. Choose a sound from one of the sources above
2. Download in WAV or MP3 format
3. Recommended duration: 0.5-2 seconds

### Step 2: Add to Xcode Project
1. Add a new group: `Shared/Resources/Sounds/`
2. Drag sound file into Xcode
3. Check "Copy items if needed"
4. Select both iOS and macOS targets

### Step 3: Update AudioFeedbackService

Replace the synthesized sound with file playback:

```swift
/// Play timer end sound from file
func playTimerEnd() {
    guard settings.timerAlertsEnabled else { return }
    playAudioFile(named: "completion-sound", extension: "wav", volume: 0.8)
}

/// Play audio file from bundle
private func playAudioFile(named name: String, extension ext: String, volume: Float) {
    guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
        DebugLogger.log("Audio file not found: \(name).\(ext)")
        return
    }
    
    do {
        let player = try AVAudioPlayer(contentsOf: url)
        player.volume = volume
        player.prepareToPlay()
        player.play()
        
        // Store player to keep it alive during playback
        let playerID = UUID().uuidString
        audioPlayers[playerID] = player
        
        // Clean up after playback
        DispatchQueue.main.asyncAfter(deadline: .now() + player.duration + 0.1) { [weak self] in
            self?.audioPlayers.removeValue(forKey: playerID)
        }
    } catch {
        DebugLogger.log("Failed to play audio file: \(error)")
    }
}
```

## Recommended Sound Specifications

- **Format:** WAV (uncompressed) or MP3
- **Sample Rate:** 44.1 kHz
- **Bit Depth:** 16-bit
- **Channels:** Mono (smaller file size)
- **Duration:** 0.5-2 seconds
- **File Size:** < 100 KB

## Example: Using Freesound "Success Bell"

### 1. Download
```bash
# Download from Freesound
curl -O "https://freesound.org/data/previews/320/320655_5260872-lq.mp3"
mv 320655_5260872-lq.mp3 completion-sound.mp3
```

### 2. Convert to WAV (Optional, for quality)
```bash
# Using ffmpeg
ffmpeg -i completion-sound.mp3 -ar 44100 -ac 1 completion-sound.wav
```

### 3. Add Attribution (for CC-BY sounds)
Add to your About/Credits section:
```
"Success Bell" by rhodesmas (Freesound)
Licensed under Creative Commons Attribution 4.0
https://freesound.org/people/rhodesmas/sounds/320655/
```

## Alternative: System Sounds

Use built-in system sounds (no download needed):

### iOS System Sounds
```swift
import AudioToolbox

func playSystemCompletionSound() {
    // iOS "Tink" sound
    AudioServicesPlaySystemSound(1104)
}
```

**Available iOS Sounds:**
- 1103: SMS Received
- 1104: Tink
- 1105: Tock
- 1106: Tock (alternate)
- 1057: Anticipate (notification)

### macOS System Sounds
```swift
#if os(macOS)
import AppKit

func playMacCompletionSound() {
    NSSound(named: "Glass")?.play()
}
```

**Available macOS Sounds:**
- "Basso"
- "Blow"
- "Bottle"
- "Frog"
- "Funk"
- "Glass" (recommended for completion)
- "Hero"
- "Morse"
- "Ping"
- "Pop"
- "Purr"
- "Sosumi"
- "Submarine"
- "Tink"

## Recommended Approach

For a professional app, I recommend:

1. **Use system sounds** (no attribution needed, already on device)
2. **Or use CC0 sounds** from Freesound (no attribution required)
3. **Avoid CC-BY unless you can add credits** (requires attribution)

## Current Implementation

The app currently uses **synthesized tones**:
- ✅ No licensing issues
- ✅ No file size overhead
- ✅ Customizable
- ❌ Less "polished" than professional sounds

## Quick Fix: Use System Sound

Replace line 52 in `AudioFeedbackService.swift`:

```swift
/// Play timer end sound (system sound)
func playTimerEnd() {
    guard settings.timerAlertsEnabled else { return }
    #if os(iOS)
    AudioServicesPlaySystemSound(1104) // iOS Tink sound
    #else
    NSSound(named: "Glass")?.play() // macOS Glass sound
    #endif
}
```

This gives you professional sounds immediately with no downloads or licensing concerns!

## File Structure (if using custom sounds)

```
Itori/
├── Shared/
│   └── Resources/
│       └── Sounds/
│           ├── completion.wav
│           ├── start.wav
│           └── pause.wav
└── Config/
    └── SOUND_CREDITS.md  (if using CC-BY)
```

## Testing Your Sound

1. Run app in simulator/device
2. Start a timer
3. Let it complete
4. Should hear your sound
5. Check Settings → Timer → Alerts Enabled

## Legal Considerations

- ✅ **CC0:** Use freely, no attribution needed
- ✅ **System sounds:** Apple-provided, free to use
- ⚠️ **CC-BY:** Must provide attribution
- ❌ **Copyrighted:** Cannot use without permission

Choose sounds marked CC0 or use system sounds for the easiest implementation!
