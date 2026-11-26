// /api/create-invoice.js — creates a NOWPayments invoice server-side.
// The API key lives only in Vercel env vars and never reaches the browser.
export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const { plan, userId, email, payCurrency } = req.body || {};

  // Prices are set server-side — never trust an amount sent by the client.
  const PRICES = { sub_weekly: 3.99, sub_monthly: 9.99 };
  if (!PRICES[plan]) return res.status(400).json({ error: 'Invalid plan' });
  if (!userId) return res.status(400).json({ error: 'You must be signed in to subscribe' });

  const SITE_URL = process.env.SITE_URL || 'https://juicebunnytv.com';
  const orderId = `jb:${userId}:${plan}:${Date.now()}`;

  try {
    const r = await fetch('https://api.nowpayments.io/v1/invoice', {
      method: 'POST',
      headers: { 'x-api-key': process.env.NOWPAYMENTS_API_KEY, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        price_amount: PRICES[plan],
        price_currency: 'usd',
        pay_currency: payCurrency || undefined,
        order_id: orderId,
        order_description: `Juice Bunny ${plan} subscription`,
        success_url: `${SITE_URL}?payment=success`,
        cancel_url: `${SITE_URL}?payment=cancelled`,
        ipn_callback_url: `${SITE_URL}/api/nowpayments-webhook`,
      }),
    });
    const data = await r.json();
    if (data && data.invoice_url) return res.status(200).json({ invoice_url: data.invoice_url });
    return res.status(502).json({ error: (data && data.message) || 'Could not create invoice' });
  } catch (e) {
    console.error('create-invoice error:', e);
    return res.status(500).json({ error: 'Payment service unavailable' });
  }
}
