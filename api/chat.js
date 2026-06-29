export default async function handler(req, res) {
  // Only allow POST
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  const { messages } = req.body;

  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'Invalid messages' });
  }

  const SYSTEM = `You are Bunny — the friendly AI support assistant for Juice Bunny, a premium adult entertainment platform. You are helpful, warm and knowledgeable about the platform.

PLATFORM INFO:
- Juice Bunny is a premium adult streaming platform at juicebunnytv.com
- Plans: Free (SD video, no model access), Weekly ($9.99/week, all features), Monthly ($24.99/month, save 37%)
- Live calls with models: $3/minute, billed per session — subscribers only
- Payment: Credit card via CCBill, crypto via NOWPayments (BTC, ETH, USDT TRC20, LTC, XRP)
- Models are real verified females added by Juice Bunny — not user-generated
- New models can apply at juicebunnytv.com/model-apply
- Models earn 20% of live call revenue ($0.60/min), Juice Bunny keeps 80% ($2.40/min)
- Chat: fans can message each other and models
- All content is 18+ only — strictly enforced
- Fully private — no tracking, no ads, no data selling

RULES:
- Keep responses SHORT and friendly (2-4 sentences max)
- Use 🐰 occasionally — stay on brand
- For billing/account issues say: "Email support@juicebunnytv.com — we reply within 24 hours"
- Never discuss competitor platforms by name
- If asked about explicit content details, redirect to browsing the platform
- Always encourage sign-up if they mention wanting more content
- Be professional but warm`;

  try {
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': process.env.ANTHROPIC_API_KEY,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-haiku-4-5-20251001', // Fast + cheap for support chat
        max_tokens: 300,
        system: SYSTEM,
        messages: messages.slice(-8), // Last 8 messages for context
      }),
    });

    const data = await response.json();

    if (data.content && data.content[0]) {
      return res.status(200).json({ reply: data.content[0].text });
    } else {
      return res.status(500).json({ error: 'No response from AI' });
    }
  } catch (err) {
    console.error('Claude API error:', err);
    return res.status(500).json({ error: 'AI service unavailable' });
  }
}