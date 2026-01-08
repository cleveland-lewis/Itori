# watchOS VoiceOver - Quick Test Guide

**Time Required:** 5-10 minutes  
**Status:** Ready to Test

---

## Enable VoiceOver on Apple Watch

### Method 1: On Watch
1. Press **Digital Crown** → Open **Settings**
2. Scroll to **Accessibility**
3. Tap **VoiceOver**
4. Toggle **VoiceOver** to **ON**

### Method 2: From iPhone
1. Open **Watch** app on iPhone
2. Go to **My Watch** tab
3. Tap **Accessibility**
4. Tap **VoiceOver**
5. Toggle **VoiceOver** to **ON**

---

## VoiceOver Gestures (Watch)

- **Single tap:** Select item
- **Double tap:** Activate
- **Swipe right:** Next item
- **Swipe left:** Previous item
- **Two-finger double tap:** Pause/resume VoiceOver
- **Digital Crown:** Scroll/adjust

---

## Quick Test (5 minutes)

### Test 1: Launch and Navigate
1. Open Itori timer on watch
2. **Swipe right** to navigate
3. ✅ Verify: Hear "Timer ready" or previous time
4. ✅ Verify: Decorative icon is skipped
5. ✅ Verify: Hear "Start Timer, button"

### Test 2: Start Timer
1. Navigate to "Start Timer" button
2. **Double tap** to activate
3. ✅ Verify: Timer starts
4. ✅ Verify: Hear activity name (if set)
5. ✅ Verify: Hear timer value in natural language

### Test 3: Pause Timer
1. **Swipe right** to "Pause timer" button
2. **Double tap** to activate
3. ✅ Verify: Timer pauses
4. ✅ Verify: Time stops updating

### Test 4: Stop Timer
1. **Swipe right** to "Stop timer" button
2. **Double tap** to activate
3. ✅ Verify: Timer stops and resets
4. ✅ Verify: Returns to idle state

---

## Expected VoiceOver Output

### Idle State:
```
"Timer ready"  (or "Previous time: 2 minutes, 30 seconds")
"Start Timer, button"
```

### Running State:
```
"Study Session"  (activity name, if set)
"Timer, 2 hours, 15 minutes, 30 seconds"
"Pause timer, button"
"Stop timer, button"
```

---

## Pass Criteria

✅ **PASS if:**
- All buttons have clear labels
- Timer announces time naturally (not "2:15:30")
- Can complete full workflow via VoiceOver only
- Decorative timer icon is skipped
- No unlabeled elements

❌ **FAIL if:**
- Any button is unlabeled
- Timer value not announced
- Cannot complete workflow
- Confusion about controls

---

## Troubleshooting

### "VoiceOver not working"
- Restart watch
- Toggle VoiceOver off/on
- Check watch is unlocked

### "Can't double-tap buttons"
- Tap once to select first
- Then double-tap anywhere on screen
- Or use Digital Crown click

### "Timer not updating"
- Timer updates every 0.1s internally
- VoiceOver announces less frequently (normal)
- Tap timer to hear current value

---

## If Test Passes ✅

1. watchOS VoiceOver is complete and working
2. Can declare watchOS accessibility in App Store Connect
3. Check all watchOS accessibility features:
   - ✅ VoiceOver
   - ✅ Larger Text
   - ✅ Dark Interface
   - ✅ Sufficient Contrast
   - ✅ Differentiate Without Color
   - ✅ Reduced Motion

---

## If Issues Found ⚠️

Document the issue:
- Which screen/element
- What VoiceOver announced (or didn't)
- What you expected
- Steps to reproduce

Most issues are quick label fixes (5-15 minutes).

---

**Ready to Test!** 🎤⌚✨

After testing, update `WATCHOS_VOICEOVER_IMPLEMENTATION.md` with results.

