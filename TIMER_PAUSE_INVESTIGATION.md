# Timer Pause Button Investigation

## Issue Report
User reports that when the timer is running and the pause button is pressed, the time goes to zero instead of freezing.

## Code Analysis

### Pause Function (Line 884-888)
```swift
private func pauseTimer() {
    guard isRunning else { return }
    isRunning = false
    // Timer state (remainingSeconds/elapsedSeconds) should NOT be modified
    // They will resume from where they left off when startTimer() is called again
}
```

This function is CORRECT - it only sets `isRunning = false` and does NOT modify:
- `remainingSeconds`
- `elapsedSeconds`
- `currentBlockDuration`

### Pause Button (Line 717)
```swift
Button(action: pauseTimer) {
    Image(systemName: "pause.fill")
        .font(.title2)
}
```

The button correctly calls `pauseTimer` - not `resetTimer`.

### Reset Function (Line 888-894)
```swift
private func resetTimer() {
    isRunning = false
    elapsedSeconds = 0
    remainingSeconds = TimeInterval(settings.pomodoroFocusMinutes * 60)
    isPomodorBreak = false
    currentBlockDuration = remainingSeconds
}
```

This is the function that WOULD reset time to initial values - but it's called by the STOP button, not pause.

### Tick Function (Line 973-986)
```swift
private func tick() {
    guard isRunning else { return }  // Won't run when paused
    
    switch mode {
    case .pomodoro, .countdown:
        if remainingSeconds > 0 {
            remainingSeconds -= 1
        } else {
            completeCurrentBlock()
        }
    case .stopwatch:
        elapsedSeconds += 1
    }
}
```

The tick function has a guard clause that prevents it from running when `isRunning` is false.

## Possible Causes

### 1. User Clicking Wrong Button
The pause and stop buttons are next to each other:
- Pause button: `pause.fill` icon
- Stop button: `stop.fill` icon

User might be accidentally clicking stop instead of pause.

### 2. Different Platform
If testing on iOS/iPad instead of macOS, there might be a different timer implementation with the bug.

### 3. Race Condition
Extremely unlikely, but there could be a threading issue where:
1. Pause sets `isRunning = false`
2. A tick happens simultaneously
3. Somehow state gets corrupted

### 4. Hidden onChange Handler
There could be an onChange handler on `isRunning` somewhere that we haven't found yet that resets state.

## Debugging Steps

1. **Add logging to pauseTimer:**
```swift
private func pauseTimer() {
    guard isRunning else { return }
    print("🟡 PAUSE: remainingSeconds=\(remainingSeconds), elapsedSeconds=\(elapsedSeconds)")
    isRunning = false
    print("🟡 PAUSE COMPLETE: remainingSeconds=\(remainingSeconds), elapsedSeconds=\(elapsedSeconds)")
}
```

2. **Add logging to resetTimer:**
```swift
private func resetTimer() {
    print("🔴 RESET CALLED")
    isRunning = false
    // ... rest of function
}
```

3. **Add logging to tick:**
```swift
private func tick() {
    guard isRunning else { 
        print("⏸️ Tick skipped - not running")
        return
    }
    print("⏱️ Tick: remaining=\(remainingSeconds)")
    // ... rest of function
}
```

4. **Test sequence:**
   - Start timer
   - Wait 5 seconds
   - Press pause
   - Check console logs
   - Check if time is still at -5 seconds or reset to 0

## Expected Behavior

When pause is pressed:
1. Timer display should freeze at current value
2. Tick function should stop running
3. Start/Resume button should appear
4. Pressing Start/Resume should continue from frozen value

## Actual Behavior (Reported)

When pause is pressed:
- Time goes to zero (like reset was called)

## Recommendation

Without being able to reproduce the issue, the code appears correct. Suggest:
1. Add debug logging
2. Verify correct button is being pressed
3. Test on macOS (not iOS/iPad)
4. Check if there's a platform-specific timer implementation being used

## Date
2026-01-06
