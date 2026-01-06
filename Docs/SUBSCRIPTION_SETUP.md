# Subscription Setup Guide

This guide explains how to set up App Store subscriptions for Itori.

## Overview

Itori uses StoreKit 2 for in-app subscriptions. The implementation includes:
- `SubscriptionManager` - Handles subscription state and purchases
- `IOSSubscriptionView` - iOS subscription UI
- `MacOSSubscriptionView` - macOS subscription UI
- `ItoriSubscriptions.storekit` - Local testing configuration

## Subscription Tiers

### Monthly Subscription
- Product ID: `com.itori.subscription.monthly`
- Price: $4.99/month
- Includes all premium features

### Yearly Subscription
- Product ID: `com.itori.subscription.yearly`
- Price: $49.99/year (20% savings)
- Includes 1 week free trial
- Includes all premium features

## App Store Connect Setup

### 1. Create Subscription Group

1. Log into [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to your app → **Subscriptions**
3. Click **+** to create a new subscription group
4. Name: **Itori Premium**
5. Reference Name: **Itori Premium**

### 2. Add Monthly Subscription

1. Click **+** in the subscription group
2. Fill in details:
   - **Reference Name**: Itori Premium Monthly
   - **Product ID**: `com.itori.subscription.monthly`
   - **Subscription Duration**: 1 month
3. Add pricing:
   - Select territories
   - Set price: $4.99 USD (equivalent pricing in other territories)
4. Add localized information:
   - **Subscription Display Name**: Itori Premium Monthly
   - **Description**: Monthly subscription to Itori Premium with AI-powered study planning, advanced analytics, and unlimited storage.

### 3. Add Yearly Subscription

1. Click **+** in the subscription group
2. Fill in details:
   - **Reference Name**: Itori Premium Yearly
   - **Product ID**: `com.itori.subscription.yearly`
   - **Subscription Duration**: 1 year
3. Add pricing:
   - Select territories
   - Set price: $49.99 USD (equivalent pricing in other territories)
4. Add intro offer:
   - **Offer Type**: Free trial
   - **Duration**: 1 week
   - **Eligibility**: New subscribers
5. Add localized information:
   - **Subscription Display Name**: Itori Premium Yearly
   - **Description**: Yearly subscription to Itori Premium with AI-powered study planning, advanced analytics, and unlimited storage. Save 20% compared to monthly.

### 4. Set Up App Metadata

1. Go to **Subscription Information**
2. Add subscription group display name: **Itori Premium**
3. Add subscription features (what users get):
   - AI-Powered Study Plans
   - Advanced Planning & Auto-scheduling
   - Analytics & Insights
   - Unlimited Storage
   - Priority Support

### 5. Configure Agreements

1. Ensure **Paid Applications Agreement** is signed
2. Set up banking and tax information if not already done

## Local Testing

### Xcode Configuration

1. Open your Xcode project
2. Select the scheme → **Edit Scheme**
3. Go to **Run** → **Options**
4. **StoreKit Configuration**: Select `ItoriSubscriptions.storekit`

### Testing Subscriptions

The StoreKit configuration file provides local testing without real purchases:

```swift
// Product IDs match App Store Connect
Monthly: com.itori.subscription.monthly ($4.99)
Yearly: com.itori.subscription.yearly ($49.99, 1-week free trial)
```

To test:
1. Run the app in simulator/device
2. Navigate to Settings → Itori Premium
3. Click Subscribe on any plan
4. StoreKit will simulate the purchase flow

### Managing Test Subscriptions

In Xcode:
- **Debug** → **StoreKit** → **Manage Transactions**
- View, expire, refund, or renew test subscriptions

## Sandbox Testing

### Create Sandbox Testers

1. App Store Connect → **Users and Access**
2. Click **Sandbox Testers** → **+**
3. Create test accounts with different regions
4. Use these accounts on physical devices

### Testing Flow

1. Sign out of App Store on device
2. Run app from Xcode
3. When prompted to sign in, use sandbox tester account
4. Test subscription purchase flow
5. Subscriptions auto-renew much faster in sandbox (5 min per month)

## Production Setup

### Before Submission

1. ✅ Subscription group is created and active
2. ✅ Both subscription products are configured
3. ✅ Pricing is set for all territories
4. ✅ Localized descriptions are added
5. ✅ Free trial is configured for yearly plan
6. ✅ Banking and tax info is complete

### App Review Information

Add this to your App Review notes:

```
SUBSCRIPTION TESTING:
- Two subscription tiers: Monthly ($4.99) and Yearly ($49.99)
- Yearly includes 1-week free trial for new subscribers
- Test account: [provide sandbox account]
- Location to access: Settings → Itori Premium
- All features accessible without subscription for review
```

### Privacy Manifest

Ensure `PrivacyInfo.xcprivacy` includes StoreKit usage:

```xml
<key>NSPrivacyTracking</key>
<false/>
<key>NSPrivacyAccessedAPITypes</key>
<array>
    <dict>
        <key>NSPrivacyAccessedAPIType</key>
        <string>NSPrivacyAccessedAPICategoryPaymentServices</string>
        <key>NSPrivacyAccessedAPITypeReasons</key>
        <array>
            <string>In-app purchases and subscription management</string>
        </array>
    </dict>
</array>
```

## Code Integration

### Checking Subscription Status

```swift
// In any view
@StateObject private var subscriptionManager = SubscriptionManager.shared

var body: some View {
    if subscriptionManager.isSubscribed {
        // Show premium features
    } else {
        // Show paywall or limited features
    }
}
```

### Observing Status Changes

```swift
.onChange(of: subscriptionManager.subscriptionStatus) { oldStatus, newStatus in
    switch newStatus {
    case .subscribed:
        // Enable premium features
    case .notSubscribed:
        // Disable premium features
    case .expired:
        // Show renewal prompt
    default:
        break
    }
}
```

## Premium Features to Gate

Consider gating these features behind subscription:

- ✅ AI-powered study plan generation
- ✅ Advanced analytics and insights
- ✅ Unlimited flashcard decks
- ✅ Practice test generation
- ✅ Export/import functionality
- ✅ Custom themes
- ✅ Priority support

## Support & Troubleshooting

### Common Issues

**Products not loading**
- Verify product IDs match exactly in code and App Store Connect
- Check that products are "Ready to Submit" status
- Ensure app bundle ID matches

**Purchase fails**
- Check sandbox tester is signed in
- Verify banking/tax information is complete
- Ensure subscription group is active

**Subscription doesn't restore**
- Use `AppStore.sync()` before checking entitlements
- Verify user is signed in with same Apple ID

### Customer Support

Provide these resources to users:
- **Manage Subscription**: iOS Settings → [Your Name] → Subscriptions
- **Request Refund**: https://reportaproblem.apple.com
- **Support Email**: support@itori.app

## Analytics

Track these events for subscription optimization:

```swift
// When user views subscription page
Analytics.track("subscription_page_viewed")

// When user initiates purchase
Analytics.track("subscription_purchase_started", properties: [
    "product_id": product.id,
    "price": product.displayPrice
])

// When purchase completes
Analytics.track("subscription_purchased", properties: [
    "product_id": product.id,
    "transaction_id": transaction.id
])

// When subscription expires
Analytics.track("subscription_expired")
```

## Next Steps

1. Set up subscriptions in App Store Connect following this guide
2. Test with StoreKit configuration file locally
3. Test with sandbox accounts on device
4. Submit for App Review with clear testing instructions
5. Monitor subscription metrics in App Store Connect

## Resources

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/)
