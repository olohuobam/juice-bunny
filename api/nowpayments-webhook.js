// /api/nowpayments-webhook.js — receives the NOWPayments IPN, verifies it, and
// activates the subscription in Supabase. This is the ONLY place a payment is trusted.
import crypto from 'crypto';

function sortObject(obj) {
  return Object.keys(obj).sort().reduce((acc, key) => {
    const v = obj[key];
    acc[key] = (v && typeof v === 'object' && !Array.isArray(v)) ? sortObject(v) : v;
    return acc;
  }, {});
}

export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'Method not allowed' });

  const payload = req.body || {};
  const sig = req.headers['x-nowpayments-sig'];
  const ipnSecret = process.env.NOWPAYMENTS_IPN_SECRET;

  // Verify the HMAC-SHA512 signature so forged "paid" calls are rejected.
  try {
    const hmac = crypto.createHmac('sha512', ipnSecret);
    hmac.update(JSON.stringify(sortObject(payload)));
    if (!sig || hmac.digest('hex') !== sig) return res.status(401).json({ error: 'Invalid signature' });
  } catch (e) {
    return res.status(401).json({ error: 'Signature check failed' });
  }

  const status = payload.payment_status;
  if (!['finished', 'confirmed'].includes(status)) {
    return res.status(200).json({ ok: true, ignored: status });
  }

  // order_id format: jb:<userId>:<plan>:<timestamp>
  const parts = String(payload.order_id || '').split(':');
  if (parts[0] !== 'jb' || !parts[1] || !parts[2]) {
    return res.status(200).json({ ok: true, note: 'unrecognized order' });
  }
  const userId = parts[1];
  const plan = parts[2];
  const days = plan === 'sub_monthly' ? 30 : 7;
  const expires = new Date(Date.now() + days * 86400000).toISOString();

  try {
    const r = await fetch(`${process.env.SUPABASE_URL}/rest/v1/profiles?id=eq.${userId}`, {
      method: 'PATCH',
      headers: {
        apikey: process.env.SUPABASE_SERVICE_ROLE_KEY,
        Authorization: `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
        'Content-Type': 'application/json',
        Prefer: 'return=minimal',
      },
      body: JSON.stringify({
        plan,
        status: 'active',
        plan_expires_at: expires,
        last_payment_id: payload.payment_id ? String(payload.payment_id) : null,
      }),
    });
    if (!r.ok) {
      console.error('Supabase activation failed:', await r.text());
      return res.status(500).json({ error: 'Activation failed' });
    }
    return res.status(200).json({ ok: true });
  } catch (e) {
    console.error('webhook error:', e);
    return res.status(500).json({ error: 'Activation error' });
  }
}
