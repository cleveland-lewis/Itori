# Phase 2 Quick Reference Card

**Epic 3 - App Store Connect Setup**

---

## ⚡ Quick Info

**Bundle ID:** `clewisiii.Itori`  
**Version:** 1.0 (Build 1)  
**Team:** V9ZWYKRGTL  
**Subscription Group:** Itori Premium

---

## 📋 8-Step Checklist

### 1. Log Into App Store Connect
→ https://appstoreconnect.apple.com

### 2. Create New App
- My Apps → "+" → New App
- Name: **Itori**
- Bundle ID: **clewisiii.Itori**
- SKU: **ITORI-001**
- Platforms: iOS, iPadOS, macOS

### 3. Set Categories
- Primary: **Education**
- Secondary: **Productivity**
- Age Rating: **4+**

### 4. Add Privacy Policy
- Need URL: Host PRIVACY_POLICY.md online first
- Options:
  - GitHub Pages
  - Personal website
  - Simple HTML hosting

### 5. Create Subscription Group
- Features → In-App Purchases
- Create group: **Itori Premium**

### 6. Add Monthly Subscription
- Product ID: `com.itori.subscription.monthly`
- Price: **$4.99/month**
- Trial: **1 week free**
- Display Name: **Itori Premium Monthly**

### 7. Add Yearly Subscription
- Product ID: `com.itori.subscription.yearly`
- Price: **$49.99/year**
- Trial: **1 week free**
- Display Name: **Itori Premium Yearly**
- Note: **17% savings!**

### 8. Create Sandbox Accounts
- Users and Access → Sandbox
- Create 2-3 test emails

---

## 🧪 Local Testing

### In Xcode:
1. Edit Scheme (Product → Scheme → Edit Scheme)
2. Run tab → Options
3. StoreKit Configuration: `ItoriSubscriptions.storekit`
4. Build & Run on simulator
5. Go to Settings → Subscriptions
6. Verify 2 products load
7. Test purchase flow

---

## 📝 Subscription Descriptions

### Monthly:
```
Access all premium features including unlimited tasks, advanced 
timer modes, AI study insights, practice test generation, and 
cross-device sync.

• Unlimited assignments and courses
• Advanced Pomodoro timer
• AI-powered study recommendations
• Practice test generator
• Flashcard system
• Grade tracking
• Calendar integration
• iCloud sync across all devices
```

### Yearly:
```
Get the best value with our yearly plan! Save 17% compared to 
monthly subscription while enjoying all premium features.

• Everything in Monthly plan
• 17% savings ($50/year vs $60/year)
• Uninterrupted access for a full year

Best for committed students who want year-round academic support.
```

---

## 🐛 Troubleshooting

### Products Won't Load?
1. Check product IDs are exact match
2. Verify StoreKit config selected in scheme
3. Clean build (Cmd+Shift+K)
4. Check console for errors

### Bundle ID Not Found?
1. Go to developer.apple.com/account
2. Register bundle ID explicitly
3. Enable In-App Purchase capability
4. Return to App Store Connect

### Sandbox Testing Fails?
1. Sign out of real App Store
2. Use sandbox account email
3. Check "[Environment: Sandbox]" appears
4. Try new sandbox account if stuck

---

## ⏱️ Time Estimate

| Task | Time |
|------|------|
| Create app | 15 min |
| Basic info | 15 min |
| Subscriptions | 30 min |
| Submit for review | 15 min |
| Sandbox testing | 30 min |
| **Total** | **~2 hours** |

---

## ✅ Completion Criteria

- [ ] App exists in App Store Connect
- [ ] Both subscriptions configured
- [ ] Subscriptions submitted for review
- [ ] Products load in simulator (2 shown)
- [ ] Purchase works in StoreKit test mode
- [ ] Sandbox accounts created

---

## 📚 Resources

**Documentation:** `EPIC3_PHASE2_APPSTORE_CONNECT_GUIDE.md`  
**Verify Script:** `bash Scripts/appstore_phase2_verify.sh`  
**GitHub Issue:** #419

---

*Quick Reference v1.0 - January 8, 2026*
