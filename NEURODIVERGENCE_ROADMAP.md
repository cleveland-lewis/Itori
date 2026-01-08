# Itori: Neurodivergence-First Design Roadmap

**Last Updated:** January 8, 2025

## Mission Statement

Itori is built for **neurodivergence**, specifically with Autism, ADHD, and OCD in mind.

Many of the features are designed to accommodate sensory differences and foster productivity. Clean, distraction-free design reduces visual noise, **100% native interface**.

Automatic scheduling breaks large assignments into manageable chunks with built-in timers.

An intelligent planning algorithm creates consistent daily structures while adapting to your energy levels.

The app respects how neurodivergent minds work: **flexible focus modes** for hyperfocus sessions, **optional visual cues** without overwhelming stimuli, and **no pressure notifications** that let you work at your own pace.

Features can be customized or disabled—because what helps one person might overwhelm another.

Itori is built by someone who understands the unique challenges of executive dysfunction, time blindness, and sensory processing differences. Transforming academic planning from a source of anxiety into a tool.

---

## Current Strengths ✅

### What's Already Great
- ✅ **Clean, Native Interface** - 100% native SwiftUI, no web views
- ✅ **Automatic Scheduling** - Breaks assignments into manageable chunks
- ✅ **Energy Level Tracking** - Adapts to your capacity
- ✅ **Built-in Timers** - Pomodoro, stopwatch, and custom timers
- ✅ **Extensive Customization** - Appearance, colors, layout options
- ✅ **No Completion Sounds** - Recently removed to reduce sensory overload
- ✅ **Compact Mode** - Reduces visual clutter
- ✅ **Animation Toggles** - Can disable transitions
- ✅ **Tab Customization** - Show only what you need
- ✅ **Offline-First** - Works without internet, no login required

---

## Feature Roadmap by Priority

## 🔴 High Priority (Immediate Impact)

### 1. Gentle Mode Setting Bundle
**Status:** Not Implemented  
**Impact:** Reduces sensory overload across the entire app  

**Features:**
- Single toggle that enables:
  - ✅ Disables all sounds (DONE)
  - Disables all push notifications
  - Reduces or removes animations
  - Softens colors (pastel palette)
  - Increases spacing between elements
  - Removes shadows and depth effects

**Implementation Notes:**
- Add to Settings > Accessibility > Sensory
- Should be reversible with one tap
- Save as user preset

---

### 2. Time Blindness Helpers
**Status:** Partially Implemented  
**Impact:** Critical for ADHD - makes time visible and concrete

#### 2a. Visual Time Indicators
- **Time Remaining Bars** on assignments
  - Color-coded: green (plenty of time) → yellow → orange → red (urgent)
  - Optional: hide colors, use only bar length
  
- **Elapsed Time Display** on timers
  - Large, persistent clock showing time spent
  - Optional progress ring around timer
  
- **"Time Until Due" Widget**
  - Dashboard card showing hours/days until next deadline
  - Updates in real-time

#### 2b. Time Awareness Prompts
- Gentle nudges: "You've been working for 45 minutes"
- Optional: "It's 3pm, you planned to finish by 4pm"
- Never alarming, always informational

**Implementation Notes:**
- Use natural language ("2 hours left" not "14:00:00")
- Make all time indicators optional
- Allow customization of color thresholds

---

### 3. Focus Mode Presets System
**Status:** Basic Implementation (Pomodoro exists)  
**Impact:** Supports hyperfocus and varied attention spans

#### Preset Modes:
1. **Deep Focus** (for hyperfocus sessions)
   - 90-minute work blocks
   - Minimal breaks
   - Hides all distractions
   
2. **Short Burst** (for executive dysfunction)
   - 5-10 minute sessions
   - Frequent breaks
   - Celebrates small wins
   
3. **Pomodoro Classic** ✅ (exists)
   - 25 min work, 5 min break
   
4. **Custom Presets** (user-defined)
   - Save your own configurations
   - Name them (e.g., "Late night coding", "Morning reading")

#### Additional Features:
- **Quick Switch** - Change modes mid-session
- **Auto-Select** - Suggest mode based on task type and time of day
- **Do Not Disturb Integration** - Silence notifications during focus

**Implementation Notes:**
- Store presets in UserDefaults
- Share presets between devices via iCloud
- Allow export/import of presets

---

### 4. Overwhelm Prevention Controls
**Status:** Not Implemented  
**Impact:** Prevents shutdown from too much information

#### Features:
- **"Show Only Today" Filter**
  - Hides future assignments completely
  - Reduces decision fatigue
  - Toggle on/off easily
  
- **Task Limit Setting**
  - Show maximum 3, 5, or 10 tasks at once
  - Hide the rest until needed
  - "Load more" button for when ready
  
- **Simplified Dashboard**
  - "One Thing at a Time" mode
  - Shows current task only
  - Reveals next task when current is complete
  
- **Auto-Hide Completed**
  - Immediately remove checked items
  - Reduces visual clutter
  - Archive instead of delete

**Implementation Notes:**
- Add to toolbar as quick toggle
- Remember user preference
- Animate gently when showing/hiding

---

## 🟡 Medium Priority (Quality of Life)

### 5. Visual Clarity & Reading Support
**Status:** Not Implemented  
**Impact:** Helps with dyslexia, visual processing, eye strain

#### Features:
- **Dyslexia-Friendly Font**
  - OpenDyslexic or Atkinson Hyperlegible
  - Optional, not default
  - Applies to all text
  
- **Line Spacing Control**
  - Tight / Normal / Comfortable / Spacious
  - Affects reading comprehension
  
- **High Contrast Mode**
  - Black on white or white on black
  - Removes grays
  - Increases border thickness
  
- **Color Blindness Support**
  - Patterns in addition to colors
  - Test with simulators
  - User-selectable palette

**Implementation Notes:**
- Settings > Accessibility > Visual
- Preview changes in real-time
- Don't override system accessibility settings

---

### 6. Executive Function Support
**Status:** Partially Implemented  
**Impact:** Helps overcome task initiation paralysis

#### Features:
- **"Start Now" Quick Action**
  - One-tap to begin task + start timer
  - No decisions, just action
  - Opens focused view
  
- **Task Breakdown Suggestions**
  - AI-powered subtask generation
  - "This essay could be: outline → draft → edit"
  - Optional, not automatic
  
- **Transition Helpers**
  - "You just finished X, want to start Y?"
  - Reduces context-switching friction
  - Optional 2-minute buffer between tasks
  
- **Quick Capture**
  - Voice notes
  - Photo capture (whiteboard/assignment)
  - "Inbox" for unsorted thoughts

**Implementation Notes:**
- Make prompts gentle, not commanding
- Allow "Not now" without guilt
- Store transition preferences

---

### 7. Expanded Customization
**Status:** Good foundation, needs expansion  
**Impact:** Personalization reduces friction

#### Features:
- **UI Presets**
  - "Calm Morning" (soft colors, wide spacing)
  - "Focused Evening" (dark, minimal)
  - "High Energy" (bright, compact)
  - User can create and save own
  
- **Per-Task Settings**
  - Some tasks need notifications, others don't
  - Some tasks deserve celebrations, others don't
  - Granular control
  
- **Energy-Adaptive UI**
  - Low energy = simpler interface
  - High energy = show more options
  - Based on user's energy level setting

**Implementation Notes:**
- Store presets as JSON
- Quick switch in toolbar
- Time-based auto-switching (optional)

---

## 🟢 Lower Priority (Nice to Have)

### 8. Gentle Positive Reinforcement
**Status:** Not Implemented  
**Impact:** Builds momentum without pressure

#### Features:
- **Optional Encouragement**
  - "Nice work today" (never "You should do more")
  - Can be fully disabled
  - Frequency control (rare / occasional / frequent)
  
- **Progress Visualization**
  - Charts that show growth, not judgment
  - Celebrate streaks but don't punish breaks
  - "You completed 3 tasks this week" (vs "You missed 4 days")
  
- **Forgiving Streak Tracking**
  - Streaks pause, don't break
  - "Welcome back" not "You failed"
  - Optional: hide streaks entirely

**Implementation Notes:**
- Default: OFF
- Test messaging with neurodivergent beta testers
- Never shame, only support

---

### 9. In-App Guides & Education
**Status:** Not Implemented  
**Impact:** Helps users discover features and understand why they exist

#### Content:
- **"Why This Helps"** explainers
  - Next to each accessibility feature
  - Written by neurodivergent designer
  - Short, scannable
  
- **Configuration Wizard**
  - "Tell us about your needs"
  - Suggests appropriate settings
  - Can skip entirely
  
- **Tips & Tricks**
  - Context-aware suggestions
  - "Did you know you can..."
  - Dismissible, non-intrusive

**Implementation Notes:**
- Markdown files for easy updates
- Localized
- Accessible via Help button

---

### 10. Community Features (Optional)
**Status:** Not Implemented  
**Impact:** Reduces isolation, shares strategies

#### Features:
- **Preset Sharing**
  - Export your focus mode or UI preset
  - Import from others
  - Curated collection
  
- **Anonymous Patterns** (Privacy-first)
  - "Users with ADHD often work best at 2pm"
  - Opt-in only
  - Never personally identifiable
  
- **Tips from Community**
  - User-submitted strategies
  - Moderated for safety
  - "What helps you start tasks?"

**Implementation Notes:**
- Privacy is paramount
- No social comparison
- No public profiles or performance metrics

---

## Implementation Phases

### Phase 1: Foundation (Current - Q1 2025)
- [x] Remove sensory overload (sounds)
- [ ] Add Gentle Mode toggle
- [ ] Implement "Show Only Today" filter
- [ ] Add time remaining indicators

### Phase 2: Core Enhancements (Q2 2025)
- [ ] Focus mode presets system
- [ ] Overwhelm controls (task limits)
- [ ] Visual clarity options (fonts, spacing, contrast)
- [ ] "Start Now" quick actions

### Phase 3: Polish & Refinement (Q3 2025)
- [ ] Energy-adaptive UI
- [ ] Per-task customization
- [ ] UI preset system
- [ ] Transition helpers

### Phase 4: Community & Growth (Q4 2025)
- [ ] In-app guides
- [ ] Preset sharing
- [ ] Optional gentle encouragement
- [ ] Beta testing with neurodivergent users

---

## Design Principles

### Always:
✅ **Respect cognitive load** - Less is more  
✅ **Provide escape hatches** - Every feature can be disabled  
✅ **Default to calm** - Gentle is better than loud  
✅ **Explain why** - Help users understand their needs  
✅ **Test with community** - Neurodivergent voices lead design  

### Never:
❌ **Shame or pressure** - No guilt, no "you should"  
❌ **Assume one-size-fits-all** - What helps one may harm another  
❌ **Hide complexity permanently** - Progressive disclosure, not removal  
❌ **Use dark patterns** - No manipulation, no tricks  
❌ **Ignore feedback** - Lived experience is expertise  

---

## Measuring Success

### Quantitative Metrics:
- Time to complete first task (should decrease)
- Number of features users disable (flexibility indicator)
- Session completion rate (vs abandonment)
- User retention (are they coming back?)

### Qualitative Metrics:
- User testimonials about reduced anxiety
- Feedback on what features actually help
- Requests for features to disable (good - means they're exploring)
- Reports of "I can finally manage school"

### Key Question:
**"Does this reduce anxiety or increase it?"**

If a feature increases anxiety for even a minority of neurodivergent users, it should be optional or removed.

---

## Resources & Research

### Neurodivergence Research:
- [ADHD & Time Blindness](https://www.additudemag.com/time-blindness-adhd/)
- [Autism & Sensory Processing](https://www.autism.org.uk/advice-and-guidance/topics/sensory-differences)
- [Executive Dysfunction Strategies](https://chadd.org/about-adhd/executive-function-skills/)

### Design Inspiration:
- macOS Accessibility Features (great baseline)
- Bear Notes (calm, focused writing)
- Things 3 (gestural, no friction)
- Forest (gamification done gently)

### Accessibility Standards:
- [WCAG 2.1 AAA](https://www.w3.org/WAI/WCAG21/quickref/)
- [Apple Human Interface Guidelines - Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Inclusive Design Principles](https://inclusivedesignprinciples.org/)

---

## Contributing

If you are neurodivergent and have ideas for Itori, your input is invaluable.

**What helps you?**  
**What overwhelms you?**  
**What's missing?**

Your lived experience is the best guide for making Itori truly supportive.

---

## Contact

For questions about neurodivergence features or to share your experience:
- GitHub Issues: Feature requests and bug reports
- Email: [Your Contact]
- Beta Testing: [Sign up link when available]

---

**Remember:** Itori is a tool, not a taskmaster. It should reduce your cognitive load, not add to it.
