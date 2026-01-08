# Epic 3: App Store Production & Subscriptions - Implementation Plan

**Date:** January 8, 2026  
**GitHub Issue:** #419  
**Status:** In Progress  
**Priority:** High (Release Blocker)

---

## Current Status Assessment

### ✅ Already Complete
1. **Core App Features** - Fully functional and tested
2. **Build Configuration** - Release builds pass for iOS/macOS
3. **Version Control** - 1.0.0 set, CHANGELOG.md finalized
4. **iCloud Sync** - CloudKit integration working
5. **StoreKit 2 Integration** - Basic implementation exists
6. **Accessibility** - 6+ features ready (95% complete)
7. **Legal Documents** - Privacy policy exists

### 🟡 Partial Progress
1. **StoreKit Configuration** - StoreKit file exists but product IDs mismatch
2. **Subscription UI** - Views exist but need testing
3. **Entitlements** - iCloud configured, need StoreKit entitlement

### ❌ Not Started
1. **App Store Connect Configuration** - Bundle setup needed
2. **Product IDs** - Need to sync with App Store Connect
3. **TestFlight** - No builds uploaded yet
4. **App Store Metadata** - Screenshots, descriptions not prepared
5. **App Icons** - Need all required sizes verified

---

## Critical Issues Identified

### 🔴 Issue 1: Product ID Mismatch
**Problem:** SubscriptionManager.swift has hardcoded IDs that don't match StoreKit configuration

**Current State:**
```swift
// SubscriptionManager.swift (Lines 16-21)
private let productIdentifiers = [
    "6757490466",  // ❌ Not a valid product ID format
    "6757490562",  // ❌ Not a valid product ID format
    "6757490611",  // ❌ Not a valid product ID format
    "6757490125"   // ❌ Not a valid product ID format
]
```

**StoreKit Configuration:**
```json
"productID": "com.itori.subscription.monthly"  // ✅ Correct format
"productID": "com.itori.subscription.yearly"   // ✅ Correct format
```

**Impact:** Subscriptions won't load in production or sandbox

**Fix Required:** Update SubscriptionManager to use correct product IDs

---

### 🔴 Issue 2: Missing In-App Purchase Entitlement
**Problem:** Config/Itori-iOS.entitlements doesn't include StoreKit entitlement

**Current State:**
- ✅ iCloud entitlements present
- ❌ No `com.apple.developer.in-app-payments` entitlement

**Impact:** App Store review will reject without this

**Fix Required:** Add StoreKit entitlement to all platform entitlement files

---

### 🔴 Issue 3: Bundle Identifier Discrepancy
**Problem:** Multiple identifiers in use

**Current:**
- Xcode: `clewisiii.Itori`
- StoreKit: References `com.itori.subscription.*`
- iCloud: `com.cwlewisiii.Itori`

**Impact:** Confusion, potential provisioning issues

**Fix Required:** Standardize on one bundle ID pattern

---

## Implementation Plan

### Phase 1: Fix Critical Issues (2-3 hours)

#### Task 1.1: Fix Product IDs ✅ Priority
**File:** `SharedCore/Services/SubscriptionManager.swift`

**Actions:**
1. Update product identifiers to match StoreKit config
2. Add comment explaining the product structure
3. Test loading products in simulator

**Code Change:**
```swift
// Product identifiers - must match App Store Connect configuration
private let productIdentifiers = [
    "com.itori.subscription.monthly",
    "com.itori.subscription.yearly"
]
```

---

#### Task 1.2: Add StoreKit Entitlement ✅ Priority
**Files:**
- `Config/Itori-iOS.entitlements`
- `Config/Itori.entitlements` (macOS)
- `Config/Itori-watchOS.entitlements`

**Actions:**
1. Add in-app purchase entitlement to all platforms
2. Verify in Xcode project settings

**Entitlement to Add:**
```xml
<key>com.apple.developer.in-app-payments</key>
<array/>
```

---

#### Task 1.3: Standardize Bundle Identifier ✅ Priority
**Decision Needed:** Choose ONE bundle ID format

**Options:**
1. `com.itori.app` (matches StoreKit pattern, professional)
2. `clewisiii.Itori` (current Xcode setting, personal)
3. `com.cwlewisiii.Itori` (current iCloud, hybrid)

**Recommendation:** Use `com.itori.app`
- Professional appearance
- Matches StoreKit configuration pattern
- Cleaner for App Store

**Files to Update:**
- Xcode project settings
- All `.entitlements` files
- StoreKit configuration
- Privacy policy URLs

---

### Phase 2: App Store Connect Setup (1-2 hours)

#### Task 2.1: Create App in App Store Connect
**Prerequisites:**
- [ ] Apple Developer Program membership active
- [ ] Bundle ID decided and available
- [ ] App name "Itori" available

**Steps:**
1. Log into App Store Connect
2. Create new app
3. Set bundle ID: `com.itori.app` (or chosen ID)
4. Configure basic app information
5. Set up subscription group
6. Add subscription products

---

#### Task 2.2: Configure Subscription Products
**Products to Create:**
1. **Monthly Subscription**
   - Product ID: `com.itori.subscription.monthly`
   - Price: $4.99/month
   - Group: Itori Premium
   - Free trial: 1 week

2. **Yearly Subscription**
   - Product ID: `com.itori.subscription.yearly`
   - Price: $49.99/year
   - Group: Itori Premium
   - Free trial: 1 week
   - Savings: ~17% vs monthly

**Localization Required:**
- Display names
- Descriptions
- Feature lists

---

#### Task 2.3: Update StoreKit Configuration
**File:** `Config/ItoriSubscriptions.storekit`

**Actions:**
1. Update product IDs if bundle ID changes
2. Sync prices with App Store Connect decisions
3. Configure trial periods
4. Test in Xcode with StoreKit testing

---

### Phase 3: Assets & Metadata (2-3 hours)

#### Task 3.1: App Icons
**Required Sizes:**
- iPhone: 180x180 (60pt @3x)
- iPad: 167x167 (83.5pt @2x)
- iPad Pro: 152x152 (76pt @2x)
- App Store: 1024x1024
- macOS: Multiple sizes (16, 32, 64, 128, 256, 512, 1024)

**Status:** Check if all sizes exist in `itori.icon/` directory

---

#### Task 3.2: Screenshots
**Required:**
- iPhone 6.7" (Pro Max) - 4-5 screenshots
- iPhone 6.5" (Plus) - 4-5 screenshots
- iPad Pro 12.9" - 4-5 screenshots
- macOS - 4-5 screenshots

**Content Ideas:**
1. Dashboard overview
2. Task management
3. Timer/Pomodoro feature
4. Grades tracking
5. Calendar integration

**Accessibility:** Include screenshots with accessibility features enabled

---

#### Task 3.3: App Store Metadata
**Required Fields:**

1. **Name:** Itori
2. **Subtitle:** (35 characters max)
   - Suggestion: "Academic Planner & Study Timer"

3. **Description:** (4000 characters max)
   - Feature highlights
   - Benefits for students
   - Platform support
   - Accessibility features

4. **Keywords:** (100 characters max)
   - Suggestion: "student,planner,homework,study,timer,pomodoro,grades,academic,college,school"

5. **Support URL:** Need to create
6. **Marketing URL:** Optional
7. **Privacy Policy URL:** Already exists at `/Users/clevelandlewis/Desktop/Itori/PRIVACY_POLICY.md`
   - **Action:** Host this online (GitHub Pages or website)

---

#### Task 3.4: App Store Categories
**Primary:** Education
**Secondary:** Productivity

**Age Rating:**
- 4+ (minimal content, educational purpose)

---

### Phase 4: TestFlight Setup (1-2 hours)

#### Task 4.1: Create Archive Build
**Steps:**
1. Set scheme to Release
2. Select "Any iOS Device" target
3. Product → Archive
4. Upload to App Store Connect
5. Wait for processing

**Build Settings to Verify:**
- [ ] Version: 1.0.0
- [ ] Build number: 1 (or next increment)
- [ ] Code signing: Distribution certificate
- [ ] Provisioning: App Store profile

---

#### Task 4.2: Configure TestFlight
**Settings:**
- Beta app description
- Beta app information
- Test Information (what to focus on)
- Feedback email

**Internal Testing:**
- Add internal testers
- Enable automatic notifications
- Set up test groups

---

#### Task 4.3: Internal Testing Protocol
**Test Cases:**
1. **Subscription Flow**
   - [ ] Product loading
   - [ ] Purchase monthly subscription
   - [ ] Purchase yearly subscription
   - [ ] Restore purchases
   - [ ] Subscription status updates

2. **Core Features**
   - [ ] Add/edit/delete tasks
   - [ ] Timer functionality
   - [ ] Grade tracking
   - [ ] Calendar sync

3. **iCloud Sync**
   - [ ] Data syncs between devices
   - [ ] Conflict resolution
   - [ ] Performance

4. **Accessibility**
   - [ ] VoiceOver navigation
   - [ ] Dynamic Type scaling
   - [ ] Voice Control
   - [ ] Dark Mode

---

### Phase 5: App Store Submission (1 hour)

#### Task 5.1: Pre-Submission Checklist
- [ ] All metadata complete
- [ ] Screenshots uploaded (all sizes)
- [ ] App icons present
- [ ] Privacy policy URL live
- [ ] Support URL created
- [ ] Subscription products configured
- [ ] TestFlight testing complete
- [ ] Known bugs documented
- [ ] Export compliance answered

---

#### Task 5.2: App Review Information
**Contact Information:**
- First Name: [Your name]
- Last Name: [Your name]
- Phone: [Your phone]
- Email: [Your email]

**Demo Account (if needed):**
- Not required (no login system)

**Notes for Reviewer:**
```
TESTING INSTRUCTIONS:

1. SUBSCRIPTIONS:
   - Use sandbox test account to test subscriptions
   - Monthly and yearly plans available
   - Free trial: 1 week
   - All features accessible with active subscription

2. CORE FEATURES:
   - Add tasks from Dashboard
   - Test Timer with any activity
   - Grant calendar permissions to see integration
   - Check Settings for customization options

3. ACCESSIBILITY:
   - 6 accessibility features implemented
   - VoiceOver: Full support with 130+ labels
   - See attached documentation for details

4. ICLOUD SYNC:
   - Data automatically syncs via CloudKit
   - Works across iOS, iPadOS, macOS
   - No user account required

KNOWN LIMITATIONS:
   - Batch review feature temporarily disabled (graceful fallback)
   - Some advanced features coming in v1.1

For questions: [your email]
```

---

#### Task 5.3: Submit for Review
**Final Actions:**
1. Select build for release
2. Choose manual or automatic release
3. Add version release notes
4. Submit for review
5. Monitor status

---

## Technical Implementation Details

### Code Changes Required

#### 1. SubscriptionManager.swift - Product IDs
```swift
// BEFORE (WRONG)
private let productIdentifiers = [
    "6757490466",
    "6757490562",
    "6757490611",
    "6757490125"
]

// AFTER (CORRECT)
private let productIdentifiers = [
    "com.itori.subscription.monthly",
    "com.itori.subscription.yearly"
]
```

---

#### 2. Entitlements - Add StoreKit
**Itori-iOS.entitlements:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <!-- Existing iCloud entitlements -->
    <key>com.apple.developer.icloud-container-identifiers</key>
    <array>
        <string>iCloud.com.itori.app</string>
    </array>
    <key>com.apple.developer.icloud-services</key>
    <array>
        <string>CloudKit</string>
        <string>CloudDocuments</string>
    </array>
    
    <!-- ADD THIS: In-App Purchase Entitlement -->
    <key>com.apple.developer.in-app-payments</key>
    <array/>
    
    <key>com.apple.security.application-groups</key>
    <array>
        <string>group.com.itori.app</string>
    </array>
</dict>
</plist>
```

---

#### 3. Bundle Identifier Updates
**If changing to com.itori.app:**

**Files to Update:**
1. Xcode project settings (all targets)
2. All `.entitlements` files
3. `Info.plist` references
4. App Groups identifiers
5. iCloud container identifiers
6. StoreKit configuration

**Search & Replace:**
- `clewisiii.Itori` → `com.itori.app`
- `com.cwlewisiii.Itori` → `com.itori.app`
- `group.clewisiii.Itori` → `group.com.itori.app`
- `iCloud.com.cwlewisiii.Itori` → `iCloud.com.itori.app`

---

### Testing Strategy

#### Local Testing (Xcode)
1. **StoreKit Testing Mode:**
   - Editor → Scheme → Run → StoreKit Configuration
   - Select `ItoriSubscriptions.storekit`
   - Test purchase flows without real money

2. **Sandbox Testing:**
   - Create sandbox test accounts in App Store Connect
   - Sign out of App Store on device
   - Test with sandbox account
   - Verify subscriptions load and purchase

---

#### Device Testing Checklist
- [ ] iPhone (iOS 17+)
- [ ] iPad (iPadOS 17+)
- [ ] Mac (macOS 14+)
- [ ] Apple Watch (watchOS 10+, if applicable)

---

## Timeline Estimate

### Fast Track (Minimum Viable)
**Total: 8-12 hours over 2-3 days**

| Phase | Time | Priority |
|-------|------|----------|
| Phase 1: Critical Fixes | 2-3 hours | 🔴 Blocking |
| Phase 2: App Store Connect | 1-2 hours | 🔴 Blocking |
| Phase 3: Assets & Metadata | 2-3 hours | 🔴 Blocking |
| Phase 4: TestFlight | 1-2 hours | 🔴 Blocking |
| Phase 5: Submission | 1 hour | 🔴 Blocking |
| Buffer for issues | 1-2 hours | - |

---

### Production Ready (Recommended)
**Total: 15-20 hours over 1 week**

Includes:
- Comprehensive testing
- Multiple TestFlight iterations
- Marketing materials preparation
- Documentation polish
- Website updates

---

## Success Criteria

### Minimum (Beta Release)
- [ ] App builds and uploads to TestFlight
- [ ] Subscription products load in sandbox
- [ ] Purchase flow completes successfully
- [ ] All entitlements configured correctly
- [ ] Core features work with subscription

### Ideal (Public Release)
- [ ] App approved by App Store review
- [ ] Subscriptions work in production
- [ ] TestFlight feedback incorporated
- [ ] Marketing materials ready
- [ ] Support infrastructure in place
- [ ] Analytics tracking configured

---

## Risk Assessment

### High Risk Items
1. **Product ID Configuration** - Easy to get wrong, hard to debug
   - Mitigation: Double-check all IDs match exactly

2. **Entitlements** - Common rejection reason
   - Mitigation: Verify all capabilities in Xcode match App Store Connect

3. **Bundle ID Change** - Can break provisioning
   - Mitigation: Create new App ID, don't modify existing

### Medium Risk Items
1. **TestFlight Review** - Can take 24-48 hours
   - Mitigation: Plan timeline accordingly

2. **Subscription Setup** - Complex configuration
   - Mitigation: Follow Apple's documentation exactly

### Low Risk Items
1. **Metadata** - Easy to update after submission
2. **Screenshots** - Can be added/changed anytime
3. **Description** - Can iterate post-launch

---

## Next Immediate Actions

### Priority 1 (Do First)
1. ✅ Fix product IDs in SubscriptionManager.swift
2. ✅ Add StoreKit entitlement to all platforms
3. ✅ Decide on final bundle identifier

### Priority 2 (Do Next)
4. Create app in App Store Connect
5. Configure subscription products
6. Test subscriptions in simulator

### Priority 3 (Do Soon)
7. Prepare app icons (verify all sizes)
8. Create screenshots
9. Write App Store description

---

## Resources & References

### Apple Documentation
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [In-App Purchase Guide](https://developer.apple.com/in-app-purchase/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

### Internal Documentation
- `PRODUCTION_PREP_COMPLETE.md` - Build readiness
- `APPSTORE_ACCESSIBILITY_ANALYSIS.md` - Accessibility features
- `APP_STORE_METADATA_REQUIREMENTS.md` - Metadata guide
- `PRIVACY_POLICY.md` - Privacy policy text

---

## Open Questions

1. **Bundle ID Decision:** Which bundle ID format to use?
   - Recommendation: `com.itori.app`

2. **Subscription Pricing:** Are $4.99/month and $49.99/year final?
   - Current StoreKit config has these values

3. **Free Tier:** What features are available without subscription?
   - Needs product decision

4. **Family Sharing:** Should subscriptions be shareable?
   - Current StoreKit: `"familyShareable": false`

5. **Trial Period:** 1 week free trial acceptable?
   - Current StoreKit: 1 week configured

---

## Conclusion

Epic 3 is **partially complete** with critical infrastructure in place but requiring:
1. Configuration fixes (product IDs, entitlements)
2. App Store Connect setup
3. Asset preparation
4. Testing & submission

The foundation is solid. With focused execution on the action plan above, the app can reach TestFlight in 2-3 days and App Store submission within a week.

**Next Step:** Execute Phase 1 (Critical Fixes) to unblock all downstream work.

---

*Document Version: 1.0*  
*Created: January 8, 2026*  
*GitHub Issue: #419*
