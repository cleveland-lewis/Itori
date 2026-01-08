# Itori Website

Professional website for the Itori app with privacy policy and app information.

## Files

- `index.html` - Homepage with features, privacy summary, and download links
- `privacy.html` - Complete privacy policy (required for App Store)
- `styles.css` - Professional styling with responsive design

## Hosting Options

### Option 1: GitHub Pages (Free, Easy)

1. **Create a new repo** or use existing repo
2. **Add website files** to a `docs` folder or root
3. **Enable GitHub Pages:**
   - Go to repo Settings → Pages
   - Source: Deploy from branch
   - Branch: main, folder: /docs (or root)
   - Save
4. **Access your site** at: `https://[username].github.io/[repo-name]/`

**Privacy Policy URL for App Store:**
```
https://[username].github.io/[repo-name]/privacy.html
```

### Option 2: Netlify (Free, Professional)

1. **Sign up** at [netlify.com](https://netlify.com)
2. **Drag & drop** the `website` folder
3. **Get instant URL:** `https://[random-name].netlify.app`
4. **Optional:** Add custom domain

**Privacy Policy URL:**
```
https://[your-site].netlify.app/privacy.html
```

### Option 3: Vercel (Free, Fast)

1. **Sign up** at [vercel.com](https://vercel.com)
2. **Import** GitHub repo or upload folder
3. **Deploy** automatically
4. **Get URL:** `https://[project-name].vercel.app`

### Option 4: Custom Domain

If you own `itori.app` (or similar):

1. Use any hosting above
2. **Add custom domain** in hosting settings
3. **Update DNS** records (hosting provides instructions)
4. **Privacy Policy URL:** `https://itori.app/privacy.html`

## Quick Start: GitHub Pages

```bash
# 1. Navigate to your repo
cd /Users/clevelandlewis/Desktop/Itori

# 2. Copy website files to docs folder (for GitHub Pages)
mkdir -p docs
cp website/* docs/

# 3. Commit and push
git add docs/
git commit -m "Add website for App Store submission"
git push origin main

# 4. Enable GitHub Pages in repo settings
# Settings → Pages → Source: main branch → /docs folder
```

## What to Put in App Store Connect

Once deployed, enter your privacy policy URL in App Store Connect:

**Privacy Policy URL:**
```
[Your deployed website URL]/privacy.html
```

Examples:
- `https://yourusername.github.io/Itori/privacy.html`
- `https://itori.netlify.app/privacy.html`
- `https://itori.app/privacy.html`

## Customization

### Update Contact Email

Replace `support@itori.app` with your actual email in:
- `index.html` (Support section)
- `privacy.html` (Contact section)

### Update App Store Link

Once your app is live, replace:
```html
<a href="https://apps.apple.com/app/itori">
```

With your actual App Store URL:
```html
<a href="https://apps.apple.com/app/itori/id[YOUR_APP_ID]">
```

### Add Screenshots

Consider adding app screenshots to make the website more appealing:
1. Take screenshots from Xcode simulator
2. Add to `website/images/` folder
3. Reference in `index.html`

## Features

✅ Fully responsive (mobile, tablet, desktop)
✅ Modern, clean design
✅ Privacy-focused messaging
✅ App Store compliant privacy policy
✅ Fast loading, no dependencies
✅ SEO optimized
✅ Accessible

## Testing Locally

```bash
# Navigate to website folder
cd /Users/clevelandlewis/Desktop/Itori/website

# Start a simple server
python3 -m http.server 8000

# Open in browser
# http://localhost:8000
```

## Next Steps

1. ✅ Deploy website to hosting
2. ✅ Get privacy policy URL
3. ✅ Enter URL in App Store Connect
4. ✅ Submit app for review
5. Update App Store link after approval
6. Consider custom domain

---

**Pro Tip:** GitHub Pages is the fastest way to get started. Just enable it in your repo settings and you'll have a URL in minutes!
