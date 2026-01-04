# Energy Level Sync - Developer Console Logging Guide

## Overview
Comprehensive developer mode logging has been added to track the entire energy level sync and scheduling pipeline.

## How to Enable Logging

1. **Enable Developer Mode**
   - Open Settings → Developer
   - Enable "Developer Mode"
   - Enable "UI Logging" (for LOG_UI messages)
   - Enable "Data Logging" (for LOG_DEV messages)

2. **View Logs**
   - Logs appear in Xcode console when running from Xcode
   - Or use Console.app and filter for "Itori" process

## Log Categories

All energy-related logs use these categories:
- `EnergySync` - iCloud synchronization
- `EnergyScheduling` - Scheduler filtering and planning
- `PlannerEngine` - Overall planner operations

## Complete Log Flow

### 1️⃣ User Selects Energy Level on Dashboard

**Location**: `DashboardView.swift → setEnergy()`

```
LOG: 🎯 User selected energy level
  level: high
  device: Mac
  timestamp: 2026-01-03 23:53:09

LOG: Adjusted energy profile for HIGH
  adjustment: +0.2

LOG: Updating scheduler preferences energy profile

LOG: 📅 Requesting planner recompute
  reason: energy level changed
  newLevel: high

LOG: ✅ Energy update complete, schedule will regenerate
```

### 2️⃣ Energy Value Writes to Local + iCloud

**Location**: `AppSettingsModel.swift → defaultEnergyLevel setter`

```
LOG: Setting energy level
  oldValue: Medium
  newValue: High
  iCloudEnabled: true

LOG: Writing energy to iCloud
  value: High

LOG: iCloud synchronize() called
  success: true
```

### 3️⃣ iCloud Pushes to Other Devices (Notification Received)

**Location**: `AppSettingsModel.swift → init() observer`

```
LOG: 🔔 Received iCloud change notification
  timestamp: 2026-01-03 23:53:11

LOG: Change reason: ServerChange (another device modified)

LOG: Changed keys from iCloud
  keys: roots.settings.defaultEnergyLevel

LOG: ⚡️ Energy level changed from another device
  oldValue: Medium
  newValue: High
  willTriggerRecompute: true

LOG: Triggering planner recompute due to energy change
```

### 4️⃣ Other Device Reads Energy from iCloud

**Location**: `AppSettingsModel.swift → defaultEnergyLevel getter`

```
LOG: Reading energy from iCloud
  cloudValue: High
  localValue: Medium

LOG: Syncing iCloud value to local storage
  from: Medium
  to: High
```

### 5️⃣ Planner Starts Scheduling with Energy Awareness

**Location**: `PlannerEngine.swift → scheduleWithAI()`

```
LOG: 🔋 Starting AI scheduling with energy awareness
  energyLevel: high
  energyString: High
  totalSessions: 12
  timestamp: 2026-01-03 23:53:12

LOG: Energy level configuration
  level: high
  filteringRules: All tasks
```

### 6️⃣ AI Scheduler Filters Tasks Based on Energy

**Location**: `AIScheduler.swift → generateSchedule()`

```
LOG: Starting schedule generation
  tasks: 12
  fixedEvents: 5
  energyLevel: high

LOG: Filtered tasks by energy
  original: 12
  filtered: 12
  energyLevel: high
```

### 7️⃣ Scheduler Completes and Returns Results

**Location**: `PlannerEngine.swift → scheduleWithAI()` (after AIScheduler)

```
LOG: 📊 AI Scheduler completed
  inputTasks: 12
  scheduledBlocks: 11
  unscheduledTasks: 1
  energyLevel: high
  filteringEfficiency: 91.7%

LOG: ⚠️ Some tasks could not be scheduled
  count: 1
  possibleReason: Not enough time slots available
```

## Energy Level Impact on Logs

### HIGH Energy
```
LOG: Energy level configuration
  filteringRules: All tasks
  
Result: All 12 tasks passed filtering → 11 scheduled
```

### MEDIUM Energy
```
LOG: Energy level configuration
  filteringRules: 7-day window + high importance
  
Result: 12 tasks → 8 passed filtering → 7 scheduled
```

### LOW Energy
```
LOG: Energy level configuration
  filteringRules: Critical tasks only (today/tomorrow)
  
Result: 12 tasks → 3 passed filtering → 3 scheduled

LOG: ⚠️ Some tasks could not be scheduled
  count: 9
  possibleReason: Low energy filtered out non-critical tasks
```

## Debugging Scenarios

### Scenario 1: Energy Not Syncing Between Devices

**What to check:**
1. Look for "iCloudEnabled: false" in write logs
2. Check for "No iCloud value found" in read logs
3. Verify "iCloud synchronize() called → success: true"
4. Check for "Received iCloud change notification" on other device

**Expected logs on Device A (setter):**
```
Setting energy level → Writing to iCloud → synchronize() success
```

**Expected logs on Device B (getter):**
```
Received notification → Changed keys → Energy changed from another device
```

### Scenario 2: Schedule Not Regenerating After Energy Change

**What to check:**
1. Look for "Requesting planner recompute" after energy selection
2. Verify "Starting AI scheduling" log appears shortly after
3. Check "AI Scheduler completed" shows new energy level

**Expected flow:**
```
User selects → setEnergy() → requestRecompute() → scheduleWithAI() → generateSchedule()
```

### Scenario 3: Wrong Number of Tasks Scheduled

**What to check:**
1. Verify "Energy level configuration" shows correct rules
2. Check "Filtered tasks by energy" shows filtering occurred
3. Look at "original vs filtered" task counts

**Expected for LOW energy:**
```
original: 12
filtered: 3  ← only critical tasks
scheduledBlocks: 3
```

## Log Levels

- **DEBUG**: Detailed internal operations (profile adjustments, reads)
- **INFO**: Major events (selection, sync, scheduling start/complete)
- **WARN**: Unexpected situations (unscheduled tasks, missing values)
- **ERROR**: Failures (not currently used for energy sync)

## Performance Tips

- Logs use metadata dictionaries for structured output
- Expensive operations (profile calculations) logged after completion
- iCloud sync is async - expect slight delay between devices
- Filtering happens before scheduling - check filtered count first

## Common Log Patterns

### ✅ Successful Sync
```
Device A: Setting energy → Writing to iCloud → success
Device B: Received notification → Syncing to local → Triggering recompute
```

### ⚠️ Sync Disabled
```
Setting energy → iCloudEnabled: false → Skipped iCloud write
```

### ⚠️ No Tasks Scheduled
```
inputTasks: 12
filtered: 0  ← energy level too restrictive
scheduledBlocks: 0
```

### 🔄 Energy Changed Externally
```
Received notification → reason: ServerChange → Energy changed from another device
```

## Testing Checklist with Logs

- [ ] Set high energy → see "All tasks" in logs
- [ ] Set low energy → see "Critical tasks only" in logs  
- [ ] Change on Mac → see notification on iPhone
- [ ] Change on iPhone → see notification on Mac
- [ ] Disable sync → see "iCloudEnabled: false"
- [ ] Enable sync → see value push to cloud
- [ ] Check filtered count matches energy rules
- [ ] Verify planner recompute after sync

## Pro Tips

1. **Filter Console by Category**: Search "EnergySync" for sync-only logs
2. **Follow UUID**: Tasks have IDs that persist through logs
3. **Check Timestamps**: Sync typically takes 1-3 seconds
4. **Watch for Emojis**: 🎯🔔⚡️📅📊 mark important events
5. **Compare Devices**: Run Console.app on both to see sync flow

