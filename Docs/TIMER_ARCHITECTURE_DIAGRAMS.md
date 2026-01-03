# Timer Feature Architecture Diagram

## System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         TIMER FEATURE EPIC                           │
│                  iOS/iPadOS + macOS Full Parity                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                           USER INTERFACES                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌────────────────┐    ┌────────────────┐    ┌────────────────┐   │
│  │   macOS UI     │    │    iOS UI      │    │   iPad UI      │   │
│  │  TimerPageView │    │ IOSTimerPageView│    │  (Split View)  │   │
│  │                │    │                │    │                │   │
│  │  • Timer Card  │    │  • Timer Card  │    │  • Activities  │   │
│  │  • Activities  │    │  • Activities  │    │  • Timer       │   │
│  │  • Tasks       │    │  • Tasks       │    │  • Tasks       │   │
│  │  • History     │    │  • History     │    │  • History     │   │
│  └────────┬───────┘    └────────┬───────┘    └────────┬───────┘   │
│           │                     │                      │            │
└───────────┼─────────────────────┼──────────────────────┼────────────┘
            │                     │                      │
            └─────────────────────┼──────────────────────┘
                                  │
┌─────────────────────────────────┼─────────────────────────────────┐
│                    SHARED ENGINE (SharedCore)                      │
├─────────────────────────────────┴─────────────────────────────────┤
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │           TimerPageViewModel (@MainActor)                   │  │
│  │                                                             │  │
│  │  State:                        Actions:                     │  │
│  │  • currentMode                 • startSession()             │  │
│  │  • currentSession              • pauseSession()             │  │
│  │  • sessionElapsed              • resumeSession()            │  │
│  │  • sessionRemaining            • endSession()               │  │
│  │  • activities                  • skipSegment()              │  │
│  │  • collections                 • addActivity()              │  │
│  │  • pastSessions               • updateActivity()            │  │
│  │  • isOnBreak                  • selectActivity()            │  │
│  │  • pomodoroCompletedCycles    • toggleTask()                │  │
│  └─────────────────┬──────────────────────────┬────────────────┘  │
│                    │                          │                    │
└────────────────────┼──────────────────────────┼────────────────────┘
                     │                          │
        ┌────────────┴──────────┐   ┌──────────┴───────────┐
        │                       │   │                      │
┌───────▼────────┐   ┌─────────▼───▼──────┐   ┌──────────▼────────┐
│   Persistence  │   │   Platform Adapters  │   │   Notification    │
│                │   │                      │   │   System          │
│  • UserDefaults│   │  iOS Only:           │   │                   │
│  • CoreData    │   │  ┌─────────────────┐│   │  • UNUserNotif... │
│  • iCloud Sync │   │  │  AlarmKit       ││   │  • Fallback       │
└────────────────┘   │  │  Scheduler      ││   │    Notifications  │
                     │  │                 ││   └───────────────────┘
                     │  │  • schedule()   ││
                     │  │  • cancel()     ││
                     │  │  • authorize()  ││
                     │  └─────────────────┘│
                     │                      │
                     │  ┌─────────────────┐│
                     │  │  Live Activity  ││
                     │  │  Manager        ││
                     │  │                 ││
                     │  │  • start()      ││
                     │  │  • update()     ││
                     │  │  • end()        ││
                     │  └─────────────────┘│
                     └──────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                       SYSTEM INTEGRATIONS                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐             │
│  │  AlarmKit    │  │  ActivityKit │  │ Notifications│             │
│  │  (iOS 26+)   │  │  (iOS 16.1+) │  │  (Fallback)  │             │
│  │              │  │              │  │              │             │
│  │  • Loud      │  │  • Lock      │  │  • Standard  │             │
│  │    alarms    │  │    Screen    │  │    alerts    │             │
│  │  • Reliable  │  │  • Dynamic   │  │  • Background│             │
│  │    firing    │  │    Island    │  │    delivery  │             │
│  │  • System    │  │  • StandBy   │  │              │             │
│  │    level     │  │              │  │              │             │
│  └──────────────┘  └──────────────┘  └──────────────┘             │
│                                                                       │
└───────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### 1. Timer Start Flow

```
User Taps "Start"
      │
      ▼
┌─────────────────┐
│ TimerPageView   │
│ startSession()  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────┐
│ TimerPageViewModel          │
│ • Create session            │
│ • Set initial duration      │
│ • Start clock timer         │
└────────┬────────────────────┘
         │
         ├───────────────────────────────┐
         │                               │
         ▼                               ▼
┌────────────────────┐     ┌──────────────────────────┐
│ AlarmScheduler     │     │ LiveActivityManager      │
│ (iOS only)         │     │ (iOS only)               │
│                    │     │                          │
│ scheduleTimerEnd() │     │ start()                  │
│ • fireIn: duration │     │ • Create activity        │
│ • loud alarm       │     │ • Show on Lock Screen    │
└────────────────────┘     └──────────────────────────┘
         │                               │
         ▼                               ▼
┌────────────────────┐     ┌──────────────────────────┐
│ System AlarmKit    │     │ System ActivityKit       │
│ • Schedule alarm   │     │ • Display Live Activity  │
│ • Request auth     │     │ • Dynamic Island         │
└────────────────────┘     └──────────────────────────┘
```

### 2. Timer Tick Flow

```
Every 1 Second
      │
      ▼
┌─────────────────────────────┐
│ Timer.publish()             │
│ (Combine Publisher)         │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ TimerPageViewModel          │
│ tickSession()               │
│ • Decrement remaining       │
│ • Increment elapsed         │
│ • Check completion          │
└────────┬────────────────────┘
         │
         ├───────────────────┐
         │                   │
         ▼                   ▼
┌────────────────┐   ┌───────────────────┐
│ UI Updates     │   │ LiveActivity      │
│ • Display time │   │ • Update time     │
│ • Progress bar │   │ • Throttle (1s)   │
└────────────────┘   └───────────────────┘
```

### 3. Timer Completion Flow

```
Remaining Time = 0
      │
      ▼
┌─────────────────────────────┐
│ TimerPageViewModel          │
│ completeSession()           │
│ • Mark completed            │
│ • Save to history           │
│ • Clear state               │
└────────┬────────────────────┘
         │
         ├─────────────────────────────┐
         │                             │
         ▼                             ▼
┌────────────────────┐     ┌──────────────────────────┐
│ AlarmScheduler     │     │ LiveActivityManager      │
│ • Alarm FIRES      │     │ end()                    │
│ • Loud sound       │     │ • Dismiss activity       │
│ • System UI        │     │ • Clear state            │
└────────────────────┘     └──────────────────────────┘
         │                             │
         ▼                             ▼
┌────────────────────┐     ┌──────────────────────────┐
│ User Action        │     │ UI Update                │
│ • Stop/Snooze      │     │ • Show completion        │
│ • Dismiss          │     │ • Update history         │
└────────────────────┘     └──────────────────────────┘
```

### 4. Task Alarm Flow

```
User Sets Task Reminder
      │
      ▼
┌─────────────────────────────┐
│ TaskAlarmPickerView         │
│ • Enable toggle             │
│ • Date/time picker          │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ saveReminder()              │
│ • Update task model         │
│ • Generate identifier       │
└────────┬────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│ UNUserNotificationCenter    │
│ • Schedule notification     │
│ • Calendar trigger          │
└────────┬────────────────────┘
         │
         ▼ (at reminder time)
┌─────────────────────────────┐
│ System Notification         │
│ • "Task Due Soon"           │
│ • Task title                │
│ • Sound/banner              │
└─────────────────────────────┘
```

---

## Platform Guard Structure

```
┌──────────────────────────────────────────────────────────────┐
│                    COMPILATION GUARDS                         │
└──────────────────────────────────────────────────────────────┘

#if os(iOS)
    ┌────────────────────────────────────────────┐
    │          iOS/iPadOS Code                    │
    │                                             │
    │  #if canImport(AlarmKit)                   │
    │      ┌──────────────────────────────────┐ │
    │      │   @available(iOS 26.0, *)         │ │
    │      │   ┌──────────────────────────┐   │ │
    │      │   │  AlarmKit Code           │   │ │
    │      │   │  • schedule()            │   │ │
    │      │   │  • cancel()              │   │ │
    │      │   │  • authorize()           │   │ │
    │      │   └──────────────────────────┘   │ │
    │      │   #else                           │ │
    │      │   • Fallback to notifications     │ │
    │      └──────────────────────────────────┘ │
    │  #endif                                    │
    │                                             │
    │  #if canImport(ActivityKit)                │
    │      ┌──────────────────────────────────┐ │
    │      │   @available(iOS 16.1, *)         │ │
    │      │   ┌──────────────────────────┐   │ │
    │      │   │  Live Activity Code      │   │ │
    │      │   │  • start()               │   │ │
    │      │   │  • update()              │   │ │
    │      │   │  • end()                 │   │ │
    │      │   └──────────────────────────┘   │ │
    │      └──────────────────────────────────┘ │
    │  #endif                                    │
    └────────────────────────────────────────────┘
#elseif os(macOS)
    ┌────────────────────────────────────────────┐
    │          macOS Code                         │
    │  • Standard notifications only              │
    │  • NO AlarmKit                              │
    │  • NO Live Activity                         │
    └────────────────────────────────────────────┘
#elseif os(watchOS)
    ┌────────────────────────────────────────────┐
    │          watchOS Code                       │
    │  • Standard notifications only              │
    │  • NO AlarmKit                              │
    │  • NO Live Activity                         │
    └────────────────────────────────────────────┘
#endif
```

---

## State Machine

```
┌─────────────────────────────────────────────────────────────┐
│                  TIMER SESSION STATES                        │
└─────────────────────────────────────────────────────────────┘

         ┌───────┐
         │ IDLE  │ ◄────────────────────┐
         └───┬───┘                      │
             │ start()                   │
             ▼                          │ endSession()
         ┌────────┐                     │
         │RUNNING │ ────────────────────┤
         └───┬────┘                     │
             │ pause()                   │
             ▼                          │
         ┌────────┐                     │
         │ PAUSED │ ────────────────────┤
         └───┬────┘                     │
             │ resume()                  │
             ▼                          │
         ┌────────┐                     │
         │RUNNING │ ────────────────────┤
         └───┬────┘                     │
             │ complete()                │
             ▼                          │
         ┌──────────┐                   │
         │COMPLETED │ ───────────────────┘
         └──────────┘

Actions at each transition:
• start()    → Schedule alarm, start Live Activity
• pause()    → Cancel alarm, update Live Activity
• resume()   → Reschedule alarm, update Live Activity
• complete() → Fire alarm (if not manual), end Live Activity
• endSession()→ Cancel alarm, end Live Activity
```

---

## Component Responsibilities

```
┌──────────────────────────────────────────────────────────────┐
│                    COMPONENT MATRIX                           │
├─────────────────┬────────────┬────────────┬─────────────────┤
│ Component       │ Platform   │ Owns       │ Responsibilities │
├─────────────────┼────────────┼────────────┼─────────────────┤
│ TimerPageView   │ macOS      │ UI         │ • Display        │
│                 │            │            │ • User input     │
│                 │            │            │ • Layout         │
├─────────────────┼────────────┼────────────┼─────────────────┤
│IOSTimerPageView │ iOS/iPadOS │ UI         │ • Display        │
│                 │            │            │ • User input     │
│                 │            │            │ • Layout         │
├─────────────────┼────────────┼────────────┼─────────────────┤
│TimerPageViewModel│ All       │ State      │ • Business logic │
│                 │            │ Logic      │ • State machine  │
│                 │            │            │ • Persistence    │
├─────────────────┼────────────┼────────────┼─────────────────┤
│AlarmScheduler   │ iOS/iPadOS │ System     │ • AlarmKit API   │
│                 │            │ Integration│ • Authorization  │
│                 │            │            │ • Scheduling     │
├─────────────────┼────────────┼────────────┼─────────────────┤
│LiveActivity     │ iOS/iPadOS │ System     │ • ActivityKit    │
│Manager          │            │ Integration│ • UI updates     │
│                 │            │            │ • Lifecycle      │
├─────────────────┼────────────┼────────────┼─────────────────┤
│TaskAlarmPicker  │ All        │ UI         │ • Date picker    │
│                 │            │            │ • Enable toggle  │
│                 │            │            │ • Notification   │
└─────────────────┴────────────┴────────────┴─────────────────┘
```

---

## File Structure

```
Roots/
├── SharedCore/
│   ├── State/
│   │   └── TimerPageViewModel.swift ─────────► Shared engine
│   ├── Models/
│   │   ├── TimerModels.swift ────────────────► Data models
│   │   └── FocusSession.swift
│   └── Features/
│       └── Scheduler/
│           └── AIScheduler.swift ─────────────► Task model (add alarm fields)
│
├── Platforms/
│   ├── iOS/
│   │   ├── Views/
│   │   │   ├── IOSTimerPageView.swift ───────► iOS UI
│   │   │   └── TaskAlarmPickerView.swift ────► NEW: Task reminder picker
│   │   ├── Scenes/
│   │   │   └── Timer/
│   │   │       ├── RecentSessionsView.swift
│   │   │       ├── AddSessionSheet.swift
│   │   │       └── EditSessionSheet.swift
│   │   └── PlatformAdapters/
│   │       ├── TimerAlarmScheduler.swift ────► AlarmKit integration
│   │       └── TimerLiveActivityManager.swift ► Live Activity
│   │
│   └── macOS/
│       └── Scenes/
│           └── TimerPageView.swift ───────────► macOS UI
│
├── Shared/
│   └── TimerLiveActivityAttributes.swift ─────► Live Activity model
│
└── RootsTimerWidget/
    ├── TimerLiveActivity.swift ───────────────► Live Activity UI
    └── RootsTimerWidgetBundle.swift
```

---

**Status**: Architecture documented ✅  
**Next**: Begin Phase 1 implementation  
**Last Updated**: 2026-01-03
