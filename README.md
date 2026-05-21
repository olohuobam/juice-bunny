# 🐰 Juice Bunny — Premium Adult Entertainment Platform

A full-stack frontend for a premium adult video streaming platform with subscription tiers, crypto & credit card payments, admin broadcasting, and a retention system.

---

## 🚀 Live Demo
> Coming soon — deploying to Netlify

---

## 📁 Project Structure

```
JUICE_BUNNY/
├── index.html              # Main landing page (rename from juice-bunny-complete.html)
├── juice-bunny-logo.png    # Official Juice Bunny logo (transparent background)
├── login.html              # Login page
├── signup.html             # 3-step signup with age verification
├── player.html             # Video player with quality selector & paywall
└── README.md               # This file
```

---

## ✅ Features Built

### Phase 1 — Landing Page
- Dark retro theme with pink neon accents
- Spinning Juice Bunny logo with glow effect
- Hero section with floating mascot
- Live ticker strip
- Trending Now with filter tabs (Action, Romance, Anime, Originals)
- Free Content section
- Premium Content section with lock overlay
- Features grid (6 cards)
- Available on all devices section
- 3-tier pricing (Free / Premium $3.99 / VIP $10)
- Testimonials
- FAQ accordion
- CTA banner
- Footer with newsletter, payment badges, 2257 compliance link
- Scroll reveal animations throughout

### Phase 2 — Authentication
- **Signup** — 3-step flow:
  - Step 1: Name, email, password with strength meter
  - Step 2: Age verification (DOB check, 18+ checkbox, country, terms)
  - Step 3: Plan selection (Free / Premium / VIP)
- **Login** — Email/password, Google/Facebook social buttons, forgot password flow
- Demo credentials: `demo@juicebunny.com` / `password123`

### Phase 3 — Video Player
- Custom HTML5-style video player UI
- Play/pause, skip ±10s, volume, mute, fullscreen
- Keyboard shortcuts (Space, ←→, M, F)
- Quality selector: 480p SD (free) / 720p, 1080p, 4K (premium locked)
- 30-second free preview for premium content → paywall triggers
- Paywall modal with pricing and CCBill/Bitcoin payment badges
- Up Next sidebar
- Stream info card (current quality, bitrate, plan)
- Details / Cast / Comments tabs
- Live comment system

### Phase 4 — Payments
- **Credit Card via CCBill** — full checkout form (name, email, card, expiry, CVV, country)
- **Bitcoin via NOWPayments** — wallet address, copy button, 30-min countdown timer, BTC amount auto-calculated per plan
- Order summary sidebar with 7-day free trial display
- Payment success page with transaction receipt
- All subscribe CTAs wired to correct plan

### Client Features
- **Broadcast Tool** — Email & SMS announcements to all/premium/VIP/free members
- **Unsubscribe Retention** — 3-step cancellation flow with 4 counter-offers (pause, 50% off, downgrade, VIP trial)
- **3 Subscription Tiers** — Free ($0), Premium ($3.99/mo), VIP ($10/mo + model photos)

---

## ⏳ Pending — Phase 5

- [ ] Admin panel (upload/delete videos, set free/paid, manage users)
- [ ] Real CCBill FlexForms integration (awaiting client CCBill account)
- [ ] Real NOWPayments API integration (awaiting account approval)
- [ ] Backend (Node.js / Supabase for user auth & video management)

---

## 🔑 API Keys (Add when ready)

### NOWPayments (Bitcoin)
```js
// In juice-bunny-complete.html → processBtcPayment()
const NOWPAYMENTS_API_KEY = 'YOUR_API_KEY_HERE';

fetch('https://api.nowpayments.io/v1/payment', {
  method: 'POST',
  headers: {
    'x-api-key': NOWPAYMENTS_API_KEY,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    price_amount: 3.99,
    price_currency: 'usd',
    pay_currency: 'btc',
    order_id: 'JB-' + Date.now()
  })
})
```

### CCBill (Credit Card)
```js
// In juice-bunny-complete.html → processCardPayment()
// Replace the setTimeout with:
window.location.href = `https://api.ccbill.com/wap-frontflex/flexforms/YOUR_FLEXFORM_ID
  ?clientAccnum=YOUR_ACCOUNT_NUM
  &clientSubacc=YOUR_SUBACCOUNT
  &currencyCode=840
  &formPrice=3.99
  &formPeriod=30`;
```

---

## 🌐 Deployment

### Netlify (Recommended)
1. Go to [netlify.com](https://netlify.com)
2. Drag & drop the `JUICE_BUNNY` folder
3. Or connect GitHub repo → auto-deploy on every push

### Important
- Rename `juice-bunny-complete.html` → `index.html` before deploying
- Keep `juice-bunny-logo.png` in the same folder as `index.html`

---

## ⚖️ Legal & Compliance

This platform contains **adult content (18+)**. The following are required before going live:

- [ ] 18 U.S.C. § 2257 Records Custodian statement on site
- [ ] Age verification on signup (✅ built in)
- [ ] Privacy Policy page
- [ ] Terms of Service page
- [ ] DMCA policy page
- [ ] CCBill account approval (adult content merchant)
- [ ] NOWPayments account approval

---

## 💳 Payment Info

| Method | Provider | Status |
|--------|----------|--------|
| Credit Card | CCBill | ⏳ Awaiting account setup |
| Bitcoin | NOWPayments | ⏳ Awaiting account approval |
| Currency | USD | ✅ Confirmed |

---

## 👨‍💻 Development Notes

- Pure HTML/CSS/JavaScript — no framework dependencies
- Single-file SPA routing via JS page switching
- All pages in one file (`juice-bunny-complete.html`) for easy deployment
- Separate files (`login.html`, `signup.html`, `player.html`) also available
- Fonts: Dancing Script (logo), Inter (body), Bebas Neue (headings)

---

## 👨‍💻 Developer

**Olohu Obam**
Full Stack Developer
📧 olohuobam@gmail.com

For questions or support regarding this project, reach out directly.

---

*© 2025 Juice Bunny. All rights reserved. 18+ Only.*