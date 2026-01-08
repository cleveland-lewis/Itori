# 🇪🇺 EU Digital Services Act (DSA) - Trader Status Analysis

**Date**: January 7, 2026  
**App**: Itori (Student Planner App)  
**Question**: Do EU DSA trader requirements apply to your app?

---

## 📊 Quick Answer

**YES - You need to provide trader information** ⚠️

Your app offers **paid subscriptions** ($4.99/month, $49.99/year), which means you're considered a **"trader"** under EU DSA regulations and must provide specific business information.

---

## 🔍 What Makes You a "Trader"

### Your App's Monetization:

Found in `ItoriSubscriptions.storekit`:

1. **Itori Premium Monthly**
   - Price: $4.99/month
   - Product ID: `com.itori.subscription.monthly`
   - Type: Recurring subscription

2. **Itori Premium Yearly**
   - Price: $49.99/year
   - Product ID: `com.itori.subscription.yearly`
   - Type: Recurring subscription
   - Includes: 1-week free trial

### Why This Makes You a Trader:

✅ You're selling digital goods/services  
✅ You're conducting commercial activity  
✅ You're targeting EU customers (175-country coverage)  
✅ You're charging money for premium features

**Result**: Under EU DSA, you're classified as a **trader** and must provide trader information.

---

## 📋 What You Must Provide

### Required Information (EU DSA Article 45):

When you submit your app to App Store Connect, you'll need to provide:

#### 1. **Business Identity**
- ✅ Legal name of your business or yourself (if sole proprietor)
- ✅ Business registration number (if applicable)
- ✅ Business address

#### 2. **Contact Information**
- ✅ Email address for customer inquiries
- ✅ Phone number (optional but recommended)
- ✅ Geographic address where you conduct business

#### 3. **Additional Details**
- ✅ Whether you're an individual or business entity
- ✅ VAT number (if you have one in EU)

---

## 🎯 Who This Applies To

### ✅ Applies to You If:

1. You offer **paid apps** → ❌ Your app is free
2. You offer **in-app purchases** → ✅ **YES - You have subscriptions**
3. You offer **subscriptions** → ✅ **YES - Monthly & Yearly**
4. You sell to **EU customers** → ✅ YES - Worldwide distribution

**Verdict**: You must comply ✅

### ❌ Would NOT Apply If:

- App is 100% free with no monetization
- App only contains ads (not selling to users)
- App doesn't target EU markets

---

## 📝 What Happens in App Store Connect

### During App Submission:

**Step 1**: Navigate to App Information section

**Step 2**: You'll see "Trader Status" or "EU Digital Services Act" section

**Step 3**: Answer these questions:

**"Are you a trader?"**
- Answer: **YES** (because you sell subscriptions)

**"Provide your trader information:"**
- Legal name
- Business address
- Email address
- Phone number (optional)
- Business registration number (if applicable)

### What Apple Does:

✅ Displays this info in your App Store listing **for EU users only**  
✅ Complies with EU DSA on your behalf  
✅ Makes it visible in a "Trader Information" section in the app details

---

## 🌍 Geographic Impact

### Who Sees This Information:

**EU Users Only** 🇪🇺
- Users downloading from EU App Stores will see trader info
- Displayed in App Store listing under app details

**Non-EU Users** 🌎
- Users outside EU won't see trader information
- Your US listing remains unchanged

### EU Countries Affected (27):

Austria, Belgium, Bulgaria, Croatia, Cyprus, Czech Republic, Denmark, Estonia, Finland, France, Germany, Greece, Hungary, Ireland, Italy, Latvia, Lithuania, Luxembourg, Malta, Netherlands, Poland, Portugal, Romania, Slovakia, Slovenia, Spain, Sweden

---

## 💡 Your Specific Situation

### Based on Your App:

**App Name**: Itori  
**Developer**: Cleveland Lewis III (assumed from bundle ID: `com.cwlewisiii.Itori`)  
**Monetization**: Premium subscriptions  
**Target Market**: Global (175 countries including EU)

### What You Need to Decide:

1. **Business Entity Type**:
   - Are you a sole proprietor/individual?
   - Or do you have a registered business (LLC, Corp, etc.)?

2. **Contact Information**:
   - What email should EU customers use for inquiries?
   - What phone number (if any)?
   - What address (can be home address if sole proprietor)?

3. **Registration Numbers**:
   - Do you have a business registration number?
   - Do you have a VAT number?

---

## 🔧 How to Comply

### In App Store Connect:

1. **Log in to App Store Connect**
2. **Go to your app** → Itori
3. **Navigate to App Information**
4. **Find "Trader Status" or "EU Digital Services Act" section**
5. **Select "I am a trader"**
6. **Fill in the required information**:

#### Example (Adjust for Your Details):

```
Legal Name: Cleveland Lewis III
(or: Itori Software LLC - if you have a business)

Business Address:
[Your business or home address]
[City, State, ZIP]
[Country]

Email Address:
support@itori.app
(or whatever email you want to use)

Phone Number: (Optional)
[Your phone number]

Business Registration Number: (If applicable)
[Your EIN, business license, or leave blank if sole proprietor]

VAT Number: (If applicable)
[Only if you're VAT registered in EU]
```

### 📧 Recommended Email Setup:

Create a support email like:
- `support@itori.app`
- `help@itori.app`
- Or use your personal email if preferred

This will be public for EU customers to contact you about purchases.

---

## ⚠️ What Happens If You Don't Comply

### If You Don't Provide Trader Info:

❌ App may be **rejected** during review  
❌ App may be **removed** from EU App Stores  
❌ **Can't distribute** to EU customers  
❌ Violates EU law (DSA Article 45)

### Timeline:

- **Effective**: February 17, 2025 (already in effect)
- **Enforcement**: Apple is now requiring this for all paid apps/subscriptions
- **Your deadline**: Before your next app submission

---

## ✅ Benefits of Compliance

### Why This Is Actually Good:

1. **Trust**: Shows EU users you're a legitimate business
2. **Transparency**: Builds customer confidence
3. **Legal protection**: Shows you as the seller, not Apple
4. **Dispute resolution**: Customers know who to contact
5. **Professional**: Makes your app look more credible

---

## 📊 Summary

### Your Requirements:

| Requirement | Status | Action Needed |
|-------------|--------|---------------|
| **Trader Status** | ✅ YES | Select "I am a trader" |
| **Legal Name** | ⚠️ Provide | Add your name or business name |
| **Address** | ⚠️ Provide | Add business/home address |
| **Email** | ⚠️ Provide | Add support email |
| **Phone** | 🔵 Optional | Add if you want |
| **Registration #** | 🔵 If applicable | Add if you have one |

---

## 🚀 Action Steps

### Before Your Next App Submission:

1. ✅ **Decide on business structure**
   - Individual developer or registered business?

2. ✅ **Gather information**:
   - Full legal name
   - Complete address
   - Contact email
   - Phone number (optional)
   - Business registration (if applicable)

3. ✅ **Log into App Store Connect**
   - Navigate to Itori app
   - Find "Trader Status" section
   - Complete all required fields

4. ✅ **Set up support email**
   - Create `support@itori.app` or similar
   - Or use existing email

5. ✅ **Save and submit**
   - Information will be displayed to EU users only
   - Appears in App Store listing

---

## 📚 References

1. **EU Digital Services Act (DSA)**:
   - Article 45: Trader disclosure requirements
   - Effective: February 17, 2025

2. **Apple Documentation**:
   - https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/

3. **EU Regulation**:
   - Regulation (EU) 2022/2065

---

## 🎯 Bottom Line

**Question**: Is EU DSA trader requirement pertinent to your app?

**Answer**: 
- ✅ **YES** - You have paid subscriptions ($4.99/mo, $49.99/yr)
- ✅ **You're a trader** - You're selling digital services
- ✅ **Must comply** - Required for EU distribution
- ✅ **Simple to do** - Just fill in your business info in App Store Connect

**Impact**: EU users will see your trader information in the App Store listing. Non-EU users won't see any changes.

**Next Steps**: 
1. Gather your business information
2. Add it to App Store Connect before next submission
3. EU compliance complete!

---

## 💡 Pro Tip

**Set up a professional support email** like `support@itori.app` before submitting. This looks more professional than a personal email and keeps support separate from your personal inbox.

---

**Status**: Action required before next App Store submission ⚠️  
**Difficulty**: Easy - just fill out a form  
**Time needed**: 5-10 minutes  
**Impact**: Required for EU distribution
