# 📱 App Store Connect - App Information Requirements

**Question**: Do you need to fill out the App Information section from Apple's documentation?

**Answer**: **YES - Absolutely required for App Store submission!** ✅

---

## 🎯 Quick Summary

The link you shared (https://developer.apple.com/help/app-store-connect/reference/app-information) is about the **core App Store metadata** - the information that appears in your App Store listing.

**This is NOT optional** - it's the basic information every app needs to be published.

---

## 📋 What You MUST Provide

### 1. **App Name** (Required)
**Your app name**: Itori
- ✅ Already have this
- Must be unique in App Store
- Max 30 characters
- Shows in App Store and device home screen

### 2. **Subtitle** (Optional but Recommended)
Short description under app name
- Max 30 characters
- Examples:
  - "Smart Study Planner"
  - "AI Academic Assistant"
  - "Student Planner & Timer"

### 3. **Primary Category** (Required)
**Recommendation for Itori**: **Education** or **Productivity**

Options:
- **Education** (if focus is academic/learning)
- **Productivity** (if focus is planning/organization)

**Secondary Category** (Optional):
- If primary is Education → add Productivity
- If primary is Productivity → add Education

### 4. **Primary Language** (Required)
**Your app**: English (U.S.)
- ✅ Already have this (based on your localizations)

### 5. **Bundle ID** (Required)
**Your app**: `com.cwlewisiii.Itori`
- ✅ Already set in your project

### 6. **SKU** (Required)
Unique identifier for your app (internal use only)
- Suggestion: `itori-2026` or `com.itori.app`
- Not visible to users
- Cannot be changed after submission

---

## 📝 What You Need to WRITE

### 1. **App Description** (Required)
Maximum 4,000 characters

**Based on your README, here's a draft**:

```
Itori is your intelligent academic companion, designed to help students excel in their studies through smart scheduling, assignment tracking, and focused learning.

KEY FEATURES:

📚 INTELLIGENT PLANNER
• AI-powered scheduling that adapts to your workload and energy levels
• Automatic assignment planning with deadline tracking
• Smart calendar integration with conflict detection
• Focus on what matters most with priority-based scheduling

✏️ ASSIGNMENT MANAGEMENT
• Track homework, projects, exams, and recurring tasks
• Automatic reminders and notifications
• Grade tracking and progress monitoring
• Organize by semester and course

🎴 FLASHCARD LEARNING
• Spaced repetition for effective memorization
• Multi-deck support with progress tracking
• Study mode optimized for retention
• Perfect for exam preparation

⏱️ FOCUS TIMER
• Pomodoro and custom timer modes
• Session history and productivity analytics
• Stay focused with distraction-free study sessions
• Track your study time across subjects

📅 CALENDAR INTEGRATION
• Seamlessly sync with your device calendar
• View all assignments and study sessions in one place
• Automatic scheduling based on your availability
• Never miss a deadline

🎯 COURSE ORGANIZATION
• Semester-based course management
• File organization for course materials
• Grade tracking and GPA calculation
• Everything organized by subject

📝 PRACTICE TESTS
• Generate timed practice exams from your coursework
• Test your knowledge before the real thing
• Track improvement over time

☁️ ICLOUD SYNC
• Seamlessly sync across all your Apple devices
• Access your data on Mac, iPhone, and iPad
• Always up-to-date, everywhere you study

DESIGNED FOR STUDENTS
Whether you're in high school, college, or graduate school, Itori adapts to your academic needs. From managing a few courses to juggling a full semester load, Itori keeps you organized, focused, and on track to succeed.

PREMIUM FEATURES
Unlock advanced features with Itori Premium:
• Unlimited assignments and courses
• Advanced AI scheduling
• Priority support
• And more!

Start your free trial today and experience smarter studying!
```

### 2. **Keywords** (Required)
Maximum 100 characters, comma-separated

**Recommendations**:
```
student planner,study,homework,assignments,academic,school,college,university,calendar,timer,flashcards,pomodoro,productivity,grades,schedule,focus,learning,education
```

Alternative (more concise):
```
study,homework,planner,school,college,assignments,grades,calendar,timer,flashcards,focus,academic,schedule
```

### 3. **Promotional Text** (Optional but Recommended)
Maximum 170 characters
- Can be updated anytime without new app review
- Appears above description

**Example**:
```
Smart study planning meets AI-powered scheduling. Track assignments, ace exams, and stay focused with Itori - your academic success companion.
```

Or:
```
Plan smarter, study better. Itori combines intelligent scheduling, assignment tracking, and focus tools to help students succeed. Try free today!
```

### 4. **Support URL** (Required)
Website where users can get support

**Options**:
- Create a simple support page: `https://itori.app/support`
- Use GitHub: `https://github.com/[your-username]/itori/wiki`
- Use email: Create redirect to `mailto:support@itori.app`
- Temporary: Use your personal site or LinkedIn

### 5. **Marketing URL** (Optional)
Your app's marketing website

**Options**:
- `https://itori.app` (if you have a domain)
- Leave blank if you don't have a website yet

### 6. **Privacy Policy URL** (Required)
**CRITICAL**: Required because you have subscriptions and collect data

**Must include**:
- What data you collect (assignments, study time, calendar events)
- How you use it (app functionality, iCloud sync)
- Data storage (iCloud, on-device)
- User rights (delete data, export, access)
- Contact information

**Options**:
1. **Host on website**: `https://itori.app/privacy`
2. **GitHub**: Create privacy.md in your repo
3. **Use privacy generator**: Search "app privacy policy generator"

**Minimum content needed**:
```
PRIVACY POLICY

Last updated: January 7, 2026

1. INFORMATION WE COLLECT
Itori collects information you provide:
- Course and assignment information
- Study session data
- Calendar events
- Preferences and settings

2. HOW WE USE YOUR DATA
- To provide app functionality
- To sync across your devices via iCloud
- To personalize your experience
- To send notifications about assignments

3. DATA STORAGE
- All data stored locally on your device
- Optional iCloud sync (your choice)
- No data sent to third-party servers
- You control your data

4. YOUR RIGHTS
- Delete your data anytime
- Export your data
- Disable iCloud sync
- Request data access

5. CONTACT
Email: support@itori.app

[Add more sections as needed]
```

---

## 🖼️ What Visual Assets You Need

### 1. **App Icon** (Required)
- ✅ You have: `itori.icon/`
- Sizes: 1024x1024px (App Store)
- All platform sizes (iOS, macOS, watchOS)

### 2. **Screenshots** (Required)

**iOS (iPhone):**
- Need 2-10 screenshots
- Sizes: 6.7" display (iPhone 15 Pro Max)
- Can use same screenshots for all iPhone sizes

**macOS:**
- Need 1-10 screenshots  
- Size: 1280 x 800 pixels or larger

**Recommendations**:
- Show main features: planner, assignments, timer, flashcards
- Use text overlays to highlight features
- Show the app in action, not just empty screens

### 3. **App Preview Video** (Optional)
- 15-30 second video showing app in use
- Not required but highly recommended
- Significantly increases downloads

---

## 🎮 Age Rating (Required)

**Your app needs age rating for**:
- ✅ No objectionable content (looks clean)
- ✅ Educational purpose
- ✅ No violence, gambling, adult content

**Likely rating**: **4+** (suitable for all ages)

Questions you'll answer:
- Cartoon or realistic violence? NO
- Medical/treatment info? NO  
- Alcohol/tobacco/drugs? NO
- Gambling? NO
- Horror/fear themes? NO
- Mature/suggestive themes? NO
- Profanity/crude humor? NO
- Sexual content? NO
- Unrestricted web access? NO (if you don't have web browser)

---

## 💰 Pricing & Availability (Required)

### 1. **Price**
**Your app**: Free (with in-app purchases)
- Base app: FREE
- Itori Premium: $4.99/month or $49.99/year

### 2. **Availability**
**Territories**: All 175 countries (as you planned)

### 3. **App Store Availability Date**
When your app should appear in the App Store
- Usually: "Make available immediately after approval"
- Or: Schedule a specific date

---

## 📊 App Store Information Required

| Item | Status | Priority | Notes |
|------|--------|----------|-------|
| **App Name** | ✅ Have | Required | Itori |
| **Subtitle** | ⚠️ Need | Recommended | "Smart Study Planner" |
| **Description** | ⚠️ Need | Required | See draft above |
| **Keywords** | ⚠️ Need | Required | See suggestions above |
| **Category** | ⚠️ Need | Required | Education or Productivity |
| **Age Rating** | ⚠️ Need | Required | Likely 4+ |
| **Privacy Policy URL** | ❌ Need | Required | CRITICAL - Must create |
| **Support URL** | ⚠️ Need | Required | Setup support page/email |
| **Screenshots** | ⚠️ Need | Required | Take on devices |
| **Bundle ID** | ✅ Have | Required | com.cwlewisiii.Itori |
| **SKU** | ⚠️ Need | Required | Create unique ID |
| **Copyright** | ⚠️ Need | Required | "2026 Cleveland Lewis III" |
| **Trader Info (EU DSA)** | ⚠️ Need | Required | See previous doc |
| **Encryption** | ✅ Done | Required | Already added |

---

## 🚨 CRITICAL: Privacy Policy

**YOU MUST CREATE A PRIVACY POLICY** because:
1. ✅ You collect user data (assignments, courses, study data)
2. ✅ You use iCloud (data transmission)
3. ✅ You have subscriptions (Apple requires it)
4. ✅ You integrate with Calendar (personal data)

**Without a privacy policy, your app will be REJECTED.**

### Quick Solution:

**Option 1: Use a Generator** (Fastest)
1. Go to https://www.termsfeed.com/privacy-policy-generator/
2. Fill in your app details
3. Download and host somewhere

**Option 2: Create Simple Markdown** (Good enough)
1. Create `privacy.md` in your repo
2. Use the template provided above
3. Link to it via GitHub Pages

**Option 3: Create Website** (Most professional)
1. Buy domain: `itori.app`
2. Create simple landing page
3. Add `/privacy` page with policy

---

## ✅ Pre-Submission Checklist

### Information You MUST Prepare:

- [ ] **App description** (4000 char max) - See draft above
- [ ] **Keywords** (100 char max) - See suggestions
- [ ] **Subtitle** (30 char max) - "Smart Study Planner"
- [ ] **Privacy Policy URL** - MUST CREATE
- [ ] **Support URL** - MUST CREATE
- [ ] **Screenshots** - iPhone & Mac (2-10 each)
- [ ] **Category** - Education or Productivity
- [ ] **Age Rating** - Answer questionnaire (likely 4+)
- [ ] **SKU** - Unique ID (e.g., "itori-2026")
- [ ] **Copyright** - "2026 Cleveland Lewis III"
- [ ] **Promotional text** (170 char) - Optional but good
- [ ] **EU Trader info** - See previous document
- [ ] **Marketing URL** (optional) - If you have website

---

## 🎯 Priority Order

**Do these FIRST (Blocking)**:
1. ✅ **Privacy Policy** - REQUIRED, takes 1-2 hours
2. ✅ **Support URL** - REQUIRED, takes 30 mins
3. ✅ **Screenshots** - REQUIRED, takes 1-2 hours
4. ✅ **App Description** - REQUIRED, use draft above
5. ✅ **Keywords** - REQUIRED, use suggestions

**Do these NEXT (Quick)**:
6. ✅ **Category** - Education or Productivity (2 mins)
7. ✅ **Age Rating** - Answer questions (5 mins)
8. ✅ **SKU** - Pick unique ID (1 min)
9. ✅ **Copyright** - Your name + year (1 min)
10. ✅ **Subtitle** - "Smart Study Planner" (2 mins)

**Do these LAST (Optional)**:
11. 🔵 **Promotional Text** - Nice to have (10 mins)
12. 🔵 **Marketing URL** - If you have website
13. 🔵 **App Preview Video** - Great for conversion

---

## 🚀 Bottom Line

**Question**: Do you need App Information?

**Answer**: 
- ✅ **YES - 100% REQUIRED**
- ✅ **Can't publish without it**
- ✅ **This is your App Store listing**
- ✅ **Users see this to decide whether to download**

**What it is**:
The App Information page is the metadata that appears in the App Store - your description, screenshots, keywords, etc. This is how users find and learn about your app.

**Time needed**: 
- Minimum: 3-4 hours (privacy policy, screenshots, writing)
- Ideal: 8-10 hours (professional screenshots, video, polished copy)

**Next steps**:
1. Create privacy policy (CRITICAL)
2. Take screenshots on devices
3. Write description (can use draft above)
4. Fill out rest of metadata

---

**Status**: Required for submission - start on privacy policy ASAP! ⚠️
