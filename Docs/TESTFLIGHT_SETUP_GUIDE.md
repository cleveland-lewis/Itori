# TestFlight Setup Guide for Itori

**Date**: December 30, 2024  
**Purpose**: Distribute iOS + watchOS app to testers via TestFlight

---

## Prerequisites

### 1. Apple Developer Program Membership
- **Cost**: $99/year
- **Sign up**: https://developer.apple.com/programs/
- **Note**: You MUST have a paid developer account (free accounts can't use TestFlight)

### 2. App Store Connect Account
- Same Apple ID as your Developer Program membership
- Access at: https://appstoreconnect.apple.com/

### 3. Required Information
- **App Name**: Itori (or whatever you want to call it publicly)
- **Bundle ID**: `clewisiii.Itori` (already configured)
- **SKU**: Any unique string (e.g., "ROOTS-2024")
- **Primary Language**: English
- **App Category**: Education or Productivity

---

## Step-by-Step Setup

### Phase 1: Create App in App Store Connect (One-Time)

#### 1.1 Log in to App Store Connect
1. Go to https://appstoreconnect.apple.com/
2. Sign in with your Apple Developer account
3. Click **"My Apps"**

#### 1.2 Create New App
1. Click **"+"** button → **"New App"**
2. Fill in:
   - **Platforms**: Check **iOS** (watchOS is included automatically)
   - **Name**: `Itori` (or your preferred public name)
   - **Primary Language**: English
   - **Bundle ID**: Select `clewisiii.Itori` from dropdown
     - If not in list, you need to register it first (see Phase 2)
   - **SKU**: `ROOTS-2024` (any unique identifier)
   - **User Access**: Full Access
3. Click **"Create"**

#### 1.3 Fill Required App Information
1. In the app page, go to **"App Information"** (left sidebar)
2. Fill in:
   - **Subtitle** (optional): "Student Planner & Timer"
   - **Category**: Education (Primary), Productivity (Secondary)
   - **Age Rating**: Click **"Edit"** → Answer questions → Likely 4+

3. Go to **"Pricing and Availability"**
   - **Price**: Free (or set a price)
   - **Availability**: All countries or select specific ones

---

### Phase 2: Configure Bundle ID (If Needed)

If your Bundle ID isn't in App Store Connect:

1. Go to https://developer.apple.com/account
2. Click **"Certificates, Identifiers & Profiles"**
3. Click **"Identifiers"** → **"+"** button
4. Select **"App IDs"** → Continue
5. Fill in:
   - **Description**: Itori iOS App
   - **Bundle ID**: Explicit → `clewisiii.Itori`
   - **Capabilities**: Check any needed (e.g., iCloud, Push Notifications)
6. Click **"Continue"** → **"Register"**

Repeat for watch app:
- **Bundle ID**: `clewisiii.Itori.watchkitapp`
- **Description**: Itori Watch App

---

### Phase 3: Create Archive in Xcode

#### 3.1 Prepare for Archive
1. Open `ItoriApp.xcodeproj` in Xcode
2. Select **"Itori"** scheme from scheme selector
3. In scheme selector, choose **"Any iOS Device"** (not a simulator)
4. **Product** → **"Clean Build Folder"** (⇧⌘K)

#### 3.2 Set Version and Build Number
1. Select **Itori** target (iOS app) in project navigator
2. Go to **"General"** tab
3. Set:
   - **Version**: `1.0` (or whatever you want)
   - **Build**: `1` (increment each upload)

Repeat for **ItoriWatch** target:
- Use same **Version** and **Build** numbers

#### 3.3 Configure Signing
1. Select **Itori** target → **"Signing & Capabilities"** tab
2. Check **"Automatically manage signing"**
3. Select your **Team** from dropdown
4. Xcode will create provisioning profiles

Repeat for **ItoriWatch** target

#### 3.4 Create Archive
1. **Product** → **"Archive"**
2. Wait for archive to complete (may take several minutes)
3. **Organizer** window will open automatically
   - If not: **Window** → **"Organizer"**

---

### Phase 4: Upload to TestFlight

#### 4.1 Validate Archive
1. In **Organizer**, select your archive
2. Click **"Validate App"**
3. Choose options:
   - **App Store Connect distribution**: Select it
   - **Upload symbols**: Check this (helps with crash reports)
   - **Manage Version and Build Number**: Let Xcode handle it
4. Click **"Validate"**
5. Wait for validation (checks for errors)
   - If errors appear, fix them and re-archive

#### 4.2 Distribute to App Store Connect
1. Click **"Distribute App"**
2. Choose **"App Store Connect"**
3. Click **"Upload"**
4. Choose same options as validation:
   - Upload symbols: ✅
   - Manage version/build: ✅
5. Click **"Upload"**
6. Wait for upload to complete (can take 5-15 minutes)

#### 4.3 Processing
1. Go to App Store Connect (https://appstoreconnect.apple.com/)
2. Click **"My Apps"** → **"Itori"**
3. Click **"TestFlight"** tab at top
4. You'll see your build with status **"Processing"**
5. **Wait**: Processing takes 10-60 minutes
   - You'll receive an email when ready
   - Status will change to **"Ready to Submit"** or **"Missing Compliance"**

---

### Phase 5: Export Compliance (Required)

#### 5.1 Answer Export Compliance Questions
1. In TestFlight tab, click on your build
2. You'll see **"Provide Export Compliance Information"**
3. Click **"Provide"**
4. Answer questions:
   - **Uses Encryption**: Probably **No** (unless you added it)
     - If you're just using HTTPS, answer **No**
   - If **Yes**: You'll need to answer more questions
5. Click **"Start Internal Testing"**

---

### Phase 6: Add Testers

#### 6.1 Internal Testing (Up to 100 People)
1. In TestFlight tab, go to **"Internal Testing"**
2. Click **"App Store Connect Users"** group
3. Click **"+"** to add testers
4. Add email addresses of testers (must have Apple IDs)
5. Testers receive email invite immediately

#### 6.2 External Testing (Up to 10,000 People)
1. Go to **"External Testing"**
2. Click **"+"** to create a new group
3. Name the group (e.g., "Beta Testers")
4. Add testers by email
5. **Submit for Review** (required for external testers)
   - Fill out test information
   - Wait for Apple review (1-2 days)

---

### Phase 7: Testers Install App

#### 7.1 Tester Setup
1. Testers receive email invite
2. They click **"View in TestFlight"** in email
3. They install **TestFlight** app from App Store
4. They accept the invite in TestFlight app
5. App appears in TestFlight → they tap **"Install"**

#### 7.2 Watch App Installation
**Automatic** (if tester has auto-install enabled):
- Watch app installs automatically after iOS app installs

**Manual**:
1. Open **Watch** app on iPhone
2. Go to **"My Watch"** tab
3. Scroll to bottom → **"Available Apps"**
4. Find **"Itori"** → Tap **"Install"**

---

## Uploading Updates

### When to Increment Version/Build
- **Build number**: Increment for every upload (1, 2, 3, 4...)
- **Version number**: Increment for significant updates (1.0, 1.1, 2.0)

### Process
1. Make your code changes
2. Increment **Build** number (e.g., 1 → 2)
3. **Product** → **"Clean Build Folder"**
4. **Product** → **"Archive"**
5. **Distribute App** → **"Upload"**
6. Wait for processing
7. In TestFlight, click **"Add Build to Test"** for your testing group
8. Testers automatically notified of update

---

## Troubleshooting

### Archive Button Grayed Out
- Make sure you selected **"Any iOS Device"** (not a simulator)
- Make sure you have a valid signing certificate

### "No accounts with App Store Connect access"
- You need to enroll in Apple Developer Program ($99/year)
- Free accounts cannot upload to TestFlight

### "Missing Compliance"
- Answer export compliance questions in App Store Connect
- Usually just need to confirm encryption usage

### "Invalid Bundle"
- Check that all targets have correct bundle IDs
- Check that version/build numbers match across targets
- Validate archive before uploading

### Watch App Not Showing
- Make sure it's embedded in iOS app (check `Itori.app/Watch/ItoriWatch.app`)
- Check bundle IDs match companion relationship
- Verify `WKCompanionAppBundleIdentifier` in watch Info.plist

### Testers Can't Install
- Make sure you added them in TestFlight
- Make sure they accepted the invite
- Make sure they have TestFlight app installed

---

## Quick Reference Commands

### Build for Archive
```bash
# Clean
xcodebuild -project ItoriApp.xcodeproj -scheme Itori clean

# Archive (creates .xcarchive)
xcodebuild -project ItoriApp.xcodeproj \
  -scheme Itori \
  -archivePath ~/Desktop/Itori.xcarchive \
  archive
```

### Export Archive (Command Line)
```bash
# Create export options plist first (see below)
xcodebuild -exportArchive \
  -archivePath ~/Desktop/Itori.xcarchive \
  -exportOptionsPlist exportOptions.plist \
  -exportPath ~/Desktop/ItoriExport
```

### Export Options Plist
Create `exportOptions.plist`:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>V9ZWYKRGTL</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

---

## Useful Links

- **App Store Connect**: https://appstoreconnect.apple.com/
- **Developer Portal**: https://developer.apple.com/account
- **TestFlight Beta Testing**: https://developer.apple.com/testflight/
- **App Store Review Guidelines**: https://developer.apple.com/app-store/review/guidelines/
- **TestFlight Help**: https://help.apple.com/app-store-connect/#/devdc42b26b8

---

## Timeline Summary

| Step | Time |
|------|------|
| Create App Store Connect app | 10 minutes |
| Configure bundle IDs | 5 minutes |
| Archive in Xcode | 5-10 minutes |
| Upload to App Store Connect | 5-15 minutes |
| Processing | 10-60 minutes |
| Export compliance | 2 minutes |
| **Total first upload** | **~1-2 hours** |
| | |
| **Subsequent uploads** | **~20-30 minutes** |

---

## Summary Checklist

- [ ] Enroll in Apple Developer Program ($99/year)
- [ ] Create app in App Store Connect
- [ ] Register bundle IDs (if needed)
- [ ] Configure signing in Xcode
- [ ] Set version and build numbers
- [ ] Archive in Xcode
- [ ] Upload to App Store Connect
- [ ] Wait for processing
- [ ] Answer export compliance questions
- [ ] Add testers
- [ ] Testers install via TestFlight

**You're ready to distribute your app!** 🚀
