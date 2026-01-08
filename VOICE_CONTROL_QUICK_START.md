# Voice Control - Quick Start Guide

**For Testing Voice Control on iPhone/iPad**

---

## Enable Voice Control (2 minutes)

1. Open **Settings** app
2. Go to **Accessibility**
3. Select **Voice Control**
4. Toggle **Voice Control** to **ON**
5. Complete the brief tutorial

---

## Basic Commands

### Show Interactive Elements
```
"Show numbers"    → Shows numbers on all tappable elements
"Show names"      → Shows labels on all elements
"Show grid"       → Shows numbered grid overlay
"Hide numbers"    → Hides the overlay
```

### Interact with Elements
```
"Tap 5"           → Taps element number 5
"Tap Dashboard"   → Taps element labeled "Dashboard"
"Tap next"        → Taps element labeled "next"
```

### Navigation
```
"Scroll up"       → Scrolls view up
"Scroll down"     → Scrolls view down
"Go back"         → Goes back in navigation
"Go home"         → Returns to home screen
```

---

## Quick Test (5 Minutes)

### 1. Launch Itori
```
Say: "Open Itori"
```

### 2. Show Interactive Elements
```
Say: "Show numbers"
Expected: Numbers appear on all buttons and tabs
```

### 3. Navigate to Assignments
```
Say: "Tap Assignments"  (or say the number)
Expected: Assignments tab opens
```

### 4. Mark Task Complete
```
Say: "Show numbers"
Say: "Tap [number]"  (for a task checkbox)
Expected: Task toggles completion
```

### 5. Add New Assignment
```
Say: "Show names"
Say: "Tap Add Assignment"  (or Quick Add)
Expected: Form opens
```

### 6. Success!
If all 5 steps work, Voice Control is working correctly ✅

---

## Full Test Plan

For comprehensive testing, see:
**`VOICE_CONTROL_TEST_PLAN.md`**
- 10 detailed scenarios
- 30-45 minutes
- Covers all app features

---

## Common Issues

### "Can't see numbers on element"
**Solution:** Element might not be accessible. Check if it has accessibility label.

### "Number appears but nothing happens"
**Solution:** Verify element has `.accessibilityAddTraits(.isButton)`

### "Can't tap by name"
**Solution:** Check if element has `.accessibilityLabel()`

---

## Tips for Better Experience

- **Speak clearly** at normal pace
- **Wait** for number overlays to appear
- **Use headphones** for better voice detection
- **Quiet environment** improves accuracy
- **Say "Show numbers"** frequently to see what's accessible

---

## Test Checklist

Quick validation checklist:

- [ ] Can navigate all tabs
- [ ] Can add new items (tasks, events, etc.)
- [ ] Can mark tasks complete
- [ ] Can start/stop timer
- [ ] Can open settings
- [ ] Can edit existing items
- [ ] Can dismiss sheets/modals
- [ ] Can scroll lists

If all checked ✅ → Voice Control is working!

---

## Need Help?

### Documentation
- **Full Guide:** `VOICE_CONTROL_IMPLEMENTATION.md`
- **Test Plan:** `VOICE_CONTROL_TEST_PLAN.md`
- **Summary:** `VOICE_CONTROL_READY_SUMMARY.md`

### Verification Script
```bash
cd ~/Desktop/Itori
bash Scripts/check_voice_control_readiness.sh
```

---

## Report Issues

If you find issues during testing:

1. Note which screen/element
2. Note what command was said
3. Note what happened vs. expected
4. Document in `VOICE_CONTROL_TEST_PLAN.md` template

Most issues are quick fixes (1-2 hours max).

---

**Quick Start Complete!**

Voice Control should work smoothly. Enjoy hands-free control of Itori! 🎤✨

