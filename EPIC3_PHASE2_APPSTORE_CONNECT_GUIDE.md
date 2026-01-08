# Epic 3 Phase 2: App Store Connect Setup Guide

**Date:** January 8, 2026  
**GitHub Issue:** #419  
**Prerequisites:** Phase 1 Complete ✅  
**Estimated Time:** 1-2 hours

---

## Current Configuration

### From Xcode Project
- **Bundle ID:** `clewisiii.Itori`
- **Version:** 1.0 (Marketing), 1 (Build)
- **Development Team:** V9ZWYKRGTL
- **Platforms:** iOS, iPadOS, macOS, watchOS

### From StoreKit Configuration
- **Product IDs:**
  - `com.itori.subscription.monthly` ($4.99/month)
  - `com.itori.subscription.yearly` ($49.99/year)
- **Subscription Group:** Itori Premium
- **Free Trial:** 1 week

---

## Phase 2 Checklist

### Pre-Flight Checks
- [ ] Apple Developer Program membership is active
- [ ] You have App Manager or Admin role in team V9ZWYKRGTL
- [ ] You can log into [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Bundle ID `clewisiii.Itori` is registered (or ready to register)

---

## Task 2.1: Create App in App Store Connect

### Step-by-Step Instructions

#### 1. Log into App Store Connect
1. Go to https://appstoreconnect.apple.com
2. Sign in with your Apple ID
3. Select your team (V9ZWYKRGTL)

#### 2. Create New App
1. Click "My Apps"
2. Click the "+" button → "New App"
3. Fill in the form:

**Platforms:**
- ☑️ iOS
- ☑️ iPadOS  
- ☑️ macOS
- ☑️ watchOS (if watch app is ready)

**Name:**
```
Itori
```

**Primary Language:**
```
English (U.S.)
```

**Bundle ID:**
```
Select: clewisiii.Itori
(If not in dropdown, need to register in Developer Portal first)
```

**SKU:**
```
ITORI-001
(Internal identifier, can be anything unique)
```

**User Access:**
```
Full Access (default)
```

4. Click "Create"

---

### Step 2A: If Bundle ID Doesn't Exist

If `clewisiii.Itori` isn't in the dropdown:

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Certificates, Identifiers & Profiles → Identifiers
3. Click "+" to add new
4. Select "App IDs" → Continue
5. Fill in:
   - Description: `Itori`
   - Bundle ID: `clewisiii.Itori` (Explicit)
   - Capabilities:
     - ☑️ iCloud (CloudKit)
     - ☑️ In-App Purchase
     - ☑️ Push Notifications (if needed)
     - ☑️ App Groups
6. Register
7. Return to App Store Connect and refresh

---

## Task 2.2: Configure Basic App Information

### In App Store Connect → Your App

#### Category
**Primary Category:**
```
Education
```

**Secondary Category:**
```
Productivity
```

#### Age Rating
1. Click "Edit" next to Age Rating
2. Answer the questionnaire:
   - Violence: None
   - Profanity: None
   - Adult Content: None
   - Gambling: None
   - Horror/Fear: None
   - Mature/Suggestive: None
   - Realistic Violence: None
   - Prolonged Violence: None
   - Sexual Content: None
   - Drugs/Alcohol: None
   - Medical/Treatment: None
   - Gambling Simulations: None

**Result: 4+ rating**

#### App Privacy
1. Click "App Privacy" in sidebar
2. You'll need to add privacy details:

**Does this app collect data?**
```
☑️ Yes (if using analytics)
⬜ No (if truly no data collection)
```

**For Itori (assuming minimal analytics):**
```
Data Types Collected: None or Contact Info (email for support)
Purpose: App Functionality
Linked to User: No
Used for Tracking: No
```

**Privacy Policy URL:**
```
https://[your-website]/itori/privacy
(Need to host PRIVACY_POLICY.md online)
```

---

## Task 2.3: Set Up Subscriptions

### Navigate to Subscriptions
1. In your app, click "Features" → "In-App Purchases"
2. Or click "Subscriptions" in the sidebar

### Create Subscription Group
1. Click "+" or "Create"
2. Select "Auto-Renewable Subscription"
3. Reference Name: `Itori Premium`
4. Click "Create"

### Add Monthly Subscription
1. In the Itori Premium group, click "+" to add subscription
2. Fill in details:

**Reference Name:**
```
Itori Premium Monthly
```

**Product ID:**
```
com.itori.subscription.monthly
```

**Subscription Duration:**
```
1 Month
```

**Subscription Price:**
```
$4.99 USD (App Store will calculate other currencies)
```

**Introductory Offer:**
- ☑️ Enable
- Type: Free Trial
- Duration: 1 Week
- Eligibility: New Subscribers

**Localizations:**
- Click "Add Localization"
- Language: English (U.S.)

**Subscription Display Name:**
```
Itori Premium Monthly
```

**Description:**
```
Access all premium features including unlimited tasks, advanced timer modes, AI study insights, practice test generation, and cross-device sync.

• Unlimited assignments and courses
• Advanced Pomodoro timer with custom sessions
• AI-powered study recommendations
• Practice test generator
• Flashcard decks with spaced repetition
• Grade tracking and GPA calculator
• Calendar integration
• iCloud sync across all devices
• Priority support

Your subscription renews automatically unless cancelled at least 24 hours before the end of the current period.
```

3. Click "Save"

### Add Yearly Subscription
1. Click "+" to add another subscription
2. Fill in details:

**Reference Name:**
```
Itori Premium Yearly
```

**Product ID:**
```
com.itori.subscription.yearly
```

**Subscription Duration:**
```
1 Year
```

**Subscription Price:**
```
$49.99 USD
```

**Promotional Text:**
```
Save 17% compared to monthly
```

**Introductory Offer:**
- ☑️ Enable
- Type: Free Trial
- Duration: 1 Week
- Eligibility: New Subscribers

**Localizations:**
- Language: English (U.S.)

**Subscription Display Name:**
```
Itori Premium Yearly
```

**Description:**
```
Get the best value with our yearly plan! Save 17% compared to monthly subscription while enjoying all premium features.

• Everything in Monthly plan
• 17% savings ($50/year vs $60/year)
• Uninterrupted access for a full year
• Cancel anytime

All premium features included:
• Unlimited assignments and courses
• Advanced Pomodoro timer
• AI-powered study insights
• Practice test generator
• Flashcard system
• Grade tracking
• Calendar integration
• iCloud sync across all devices
• Priority support

Best for committed students who want year-round academic support.
```

3. Click "Save"

---

## Task 2.4: Configure Subscription Group Settings

### Edit Subscription Group
1. Click on "Itori Premium" group name
2. Configure settings:

**Display Name:**
```
Itori Premium
```

**App Name (for receipts):**
```
Itori
```

**Subscription Management:**
- ☑️ Allow customers to manage subscriptions in Settings

**Family Sharing:**
```
⬜ Enable Family Sharing
(Currently disabled in StoreKit config)
```

**Subscription Status URL (optional):**
```
Leave blank for now
(Can add server-to-server notification endpoint later)
```

3. Click "Save"

---

## Task 2.5: Submit Subscriptions for Review

### Before Submitting
Subscriptions must be submitted for review separately from the app.

1. Go to each subscription (monthly & yearly)
2. Click "Submit for Review"
3. Add screenshots showing:
   - Subscription paywall
   - Feature list
   - Terms clearly visible

**Screenshot Requirements:**
- 1242 x 2208 pixels (iPhone 6.5")
- Show subscription options clearly
- Display pricing prominently
- Include "Terms & Conditions" text

### Review Notes
```
SUBSCRIPTION TESTING NOTES:

Monthly Plan: $4.99/month with 1-week free trial
Yearly Plan: $49.99/year with 1-week free trial (17% savings)

All premium features are clearly described in the app:
- Unlimited assignments and courses
- Advanced timer features
- AI study insights
- Practice test generator
- Flashcard system
- Grade tracking
- Calendar integration
- iCloud sync

Users can manage subscriptions in iOS Settings.
Cancel anytime functionality is provided by iOS system.

Sandbox test accounts can be provided if needed.
```

4. Submit each subscription

**Note:** Subscriptions typically review in 24-48 hours

---

## Task 2.6: Update StoreKit Configuration (If Needed)

### Verify Local Configuration
The file `Config/ItoriSubscriptions.storekit` should already be correct.

**Current Configuration:**
```json
{
  "subscriptionGroups": [
    {
      "name": "Itori Premium",
      "subscriptions": [
        {
          "productID": "com.itori.subscription.monthly",
          "displayPrice": "4.99",
          "recurringSubscriptionPeriod": "P1M",
          "introductoryOffer": {
            "paymentMode": "free",
            "subscriptionPeriod": "P1W"
          }
        },
        {
          "productID": "com.itori.subscription.yearly",
          "displayPrice": "49.99",
          "recurringSubscriptionPeriod": "P1Y",
          "introductoryOffer": {
            "paymentMode": "free",
            "subscriptionPeriod": "P1W"
          }
        }
      ]
    }
  ]
}
```

**Verification:**
- ✅ Product IDs match App Store Connect
- ✅ Prices match
- ✅ Trial periods match
- ✅ Durations match

**No changes needed!** ✅

---

## Task 2.7: Test StoreKit Configuration Locally

### In Xcode
1. Open `ItoriApp.xcodeproj`
2. Edit Scheme (Product → Scheme → Edit Scheme)
3. Run → Options tab
4. StoreKit Configuration: Select `ItoriSubscriptions.storekit`
5. Click "Close"

### Run on Simulator
1. Build and run on iOS Simulator
2. Navigate to Settings → Subscriptions
3. Verify:
   - [ ] Two subscription options appear
   - [ ] Monthly: $4.99/month displayed
   - [ ] Yearly: $49.99/year displayed
   - [ ] "1 week free" trial badge shows
   - [ ] Can select a plan
   - [ ] Purchase sheet appears (StoreKit testing mode)
   - [ ] Purchase completes successfully
   - [ ] App recognizes active subscription

### Debugging
If products don't load:
```swift
// Check SubscriptionManager output in console
// Should see:
"Loaded 2 products"
// Should NOT see:
"Failed to load products"
```

If "Failed to load products":
1. Check product IDs match exactly (case-sensitive)
2. Verify StoreKit configuration is selected in scheme
3. Clean build folder (Cmd+Shift+K)
4. Rebuild

---

## Task 2.8: Create Sandbox Test Accounts

### In App Store Connect
1. Go to "Users and Access"
2. Click "Sandbox" tab
3. Click "+" to add tester
4. Fill in:
   - Email: `itori.test1@icloud.com` (use + trick: yourname+test1@icloud.com)
   - Password: Create strong password
   - First/Last Name: Test User
   - Country: United States
   - Date of Birth: 18+ years old

5. Create 2-3 test accounts for testing scenarios:
   - Fresh user (new subscription)
   - Cancelled user (test restore)
   - Expired trial (test paid conversion)

### Test on Physical Device
**Important:** Sandbox testing requires a real device, not simulator

1. Sign out of App Store on device:
   - Settings → [Your Name] → Media & Purchases → Sign Out

2. Install app on device (via Xcode or TestFlight)

3. Open app, navigate to subscriptions

4. Attempt to purchase - it will prompt for App Store login

5. Sign in with sandbox test account

6. Complete purchase (it will say "[Environment: Sandbox]")

7. Verify subscription activates in app

---

## Verification Checklist

### App Store Connect Setup ✅
- [ ] App created with correct bundle ID
- [ ] Category set to Education/Productivity
- [ ] Age rating completed (4+)
- [ ] Privacy policy added (need to host online first)
- [ ] Subscription group "Itori Premium" created
- [ ] Monthly subscription configured ($4.99)
- [ ] Yearly subscription configured ($49.99)
- [ ] Both subscriptions submitted for review
- [ ] Sandbox test accounts created

### Local Testing ✅
- [ ] StoreKit configuration selected in Xcode scheme
- [ ] App builds and runs on simulator
- [ ] Subscriptions load in app (2 products visible)
- [ ] Can select a subscription plan
- [ ] Purchase sheet appears correctly
- [ ] Purchase completes in StoreKit test mode
- [ ] App recognizes active subscription state

### Device Testing ✅
- [ ] Tested on physical iOS device
- [ ] Sandbox test account created
- [ ] Purchase flow works with sandbox account
- [ ] Subscription activates in app
- [ ] Restore purchases works
- [ ] Can cancel and resubscribe

---

## Common Issues & Solutions

### Issue 1: Bundle ID Not Found
**Symptom:** Bundle ID doesn't appear in App Store Connect dropdown

**Solution:**
1. Go to developer.apple.com/account
2. Register the bundle ID explicitly
3. Enable In-App Purchase capability
4. Return to App Store Connect and refresh

---

### Issue 2: Products Won't Load
**Symptom:** SubscriptionManager returns empty array

**Solutions:**
- Verify product IDs are EXACT match (case-sensitive)
- Check StoreKit configuration is selected in Xcode scheme
- Ensure entitlements include `com.apple.developer.in-app-payments`
- Clean build folder and rebuild
- Check console for "Failed to load products" error

---

### Issue 3: Sandbox Purchase Fails
**Symptom:** Purchase sheet appears but fails to complete

**Solutions:**
- Ensure you're using a sandbox test account (not your real Apple ID)
- Sign out of real App Store account first
- Check that device is in sandbox testing mode
- Verify sandbox account is active (not revoked)
- Try creating a new sandbox test account

---

### Issue 4: Subscription Review Rejection
**Symptom:** Subscriptions rejected during review

**Common Reasons:**
1. Missing privacy policy URL
2. Unclear subscription terms in UI
3. Screenshots don't show pricing clearly
4. Feature list not matching actual app functionality

**Solutions:**
- Ensure privacy policy is hosted and accessible
- Add clear pricing and terms to subscription view
- Retake screenshots showing all required info
- Update feature descriptions to match app exactly

---

## Time Tracking

### Estimated Times
- Task 2.1: Create app - 15 minutes
- Task 2.2: Basic info - 15 minutes  
- Task 2.3: Subscriptions - 30 minutes
- Task 2.4: Group settings - 10 minutes
- Task 2.5: Submit for review - 15 minutes
- Task 2.6: Verify StoreKit - 5 minutes
- Task 2.7: Local testing - 15 minutes
- Task 2.8: Sandbox testing - 30 minutes

**Total Estimated: 2 hours 15 minutes**

---

## Phase 2 Completion Criteria

### Must Have ✅
- [ ] App exists in App Store Connect
- [ ] Subscriptions configured and submitted
- [ ] StoreKit configuration verified
- [ ] Products load successfully in simulator
- [ ] Purchase flow works in StoreKit test mode

### Should Have
- [ ] Sandbox testing completed on device
- [ ] Multiple test accounts created
- [ ] Privacy policy URL added
- [ ] Screenshots prepared for review

### Nice to Have
- [ ] Server-to-server notifications configured
- [ ] Subscription analytics set up
- [ ] Family sharing decision finalized
- [ ] Promotional offers planned

---

## Next Steps: Phase 3

Once Phase 2 is complete:
1. Prepare app assets (icons, screenshots)
2. Write App Store description
3. Create promotional materials
4. Prepare for TestFlight

**Estimated Phase 3 Time:** 2-3 hours

---

## Support Resources

### Apple Documentation
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Subscriptions Guide](https://developer.apple.com/documentation/storekit/in-app_purchase/subscriptions_and_offers)
- [StoreKit Testing](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)

### Internal Docs
- `EPIC3_APP_STORE_PRODUCTION_PLAN.md` - Full plan
- `EPIC3_PHASE1_COMPLETE.md` - Phase 1 summary
- `Config/ItoriSubscriptions.storekit` - StoreKit config

---

*Phase 2 Guide Created: January 8, 2026*  
*Next: App Store Connect Setup*  
*GitHub Issue: #419*
