import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const XSOLLA_MERCHANT_ID = Deno.env.get('XSOLLA_MERCHANT_ID')!
const XSOLLA_API_KEY     = Deno.env.get('XSOLLA_API_KEY')!
const XSOLLA_PROJECT_ID  = Deno.env.get('XSOLLA_PROJECT_ID')!
const SB_URL             = Deno.env.get('SUPABASE_URL')!
const SB_ANON            = Deno.env.get('SUPABASE_ANON_KEY')!
const SANDBOX            = Deno.env.get('XSOLLA_SANDBOX') === 'true'

const PRODUCTS: Record<string, { sku: string; name: string }> = {
  standard_yearly:  { sku: 'standard_yearly',  name: 'Standard – 1 Year' },
  allaccess_yearly: { sku: 'allaccess_yearly',  name: 'All Access – 1 Year' },
}

const cors = {
  'Access-Control-Allow-Origin':  '*',
  'Access-Control-Allow-Headers': 'Authorization, Content-Type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: cors })

  try {
    // Verify caller is an authenticated Supabase user
    const sb = createClient(SB_URL, SB_ANON, {
      global: { headers: { Authorization: req.headers.get('Authorization') ?? '' } }
    })
    const { data: { user }, error: authErr } = await sb.auth.getUser()
    if (authErr || !user) {
      return new Response('Unauthorized', { status: 401, headers: cors })
    }

    const { product_id, country } = await req.json()
    const product = PRODUCTS[product_id]
    if (!product) {
      return new Response('Unknown product', { status: 400, headers: cors })
    }

    // PayStation resolves the billing-method list from the buyer's country. If it
    // cannot resolve one it renders an empty list ("billing method is not available"),
    // so always send a country and let the buyer correct it in the UI. A code Xsolla
    // does not know is a hard 422, so the request below retries without it.
    const buyerCountry = /^[A-Za-z]{2}$/.test(country ?? '')
      ? String(country).toUpperCase()
      : 'US'

    // Fetch display name for PayStation UI
    const { data: profile } = await sb.from('profiles')
      .select('display_name').eq('id', user.id).maybeSingle()
    const displayName = profile?.display_name || user.email?.split('@')[0] || 'Player'

    // v3 demands user.country.value OR an X-User-Ip header — with neither it 422s.
    const clientIp = (req.headers.get('x-forwarded-for') ?? '').split(',')[0].trim()

    const buyer = (country: string | null) => ({
      id:      { value: user.id },
      email:   { value: user.email },
      name:    { value: displayName },
      ...(country
        ? { country: { value: country, allow_modify: true } }
        : {}),
    })

    // Store API v3. Xsolla support confirmed this is the endpoint to use: unlike the
    // legacy merchant token API it registers a real order, without which PayStation
    // renders the method list and then rejects every method with error 2002.
    // Note v3 has no settings.mode — sandbox goes through the legacy API below.
    const storeRequest = (country: string | null) => ({
      url: `https://store.xsolla.com/api/v3/project/${XSOLLA_PROJECT_ID}/admin/payment/token`,
      body: {
        user: buyer(country),
        settings: {
          return_url: 'https://whambam.games',
          currency: 'USD',
          ui: { theme: 'dark' },
        },
        purchase: {
          items: [{ sku: product.sku, quantity: 1 }]
        }
      }
    })

    // Legacy merchant API — kept only because it is the one that accepts
    // settings.mode:'sandbox', which the setup doc's test flow relies on.
    const legacyRequest = (country: string | null) => ({
      url: `https://api.xsolla.com/merchant/v2/merchants/${XSOLLA_MERCHANT_ID}/token`,
      body: {
        user: buyer(country),
        settings: {
          project_id: parseInt(XSOLLA_PROJECT_ID),
          return_url: 'https://whambam.games',
          currency: 'USD',
          ui: { theme: 'dark' },
          mode: 'sandbox',
        },
        purchase: {
          virtual_items: {
            items: [{ sku: product.sku, amount: 1 }]
          }
        }
      }
    })

    const basicAuth = btoa(`${XSOLLA_MERCHANT_ID}:${XSOLLA_API_KEY}`)
    const mintToken = (country: string | null) => {
      const { url, body } = SANDBOX ? legacyRequest(country) : storeRequest(country)
      return fetch(url, {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${basicAuth}`,
          'Content-Type':  'application/json',
          ...(clientIp ? { 'X-User-Ip': clientIp } : {}),
        },
        body: JSON.stringify(body)
      })
    }

    // Prefer Xsolla's own IP geolocation over the browser's locale: a locale says what
    // language the buyer reads, not where they can pay from, and sending country wins
    // over X-User-Ip — which is what pinned every checkout to the US. Country is the
    // fallback for when the edge runtime hands us no client IP.
    console.log('xsolla-token: clientIp', clientIp || '(none)', 'locale country', buyerCountry)
    let xResp = await mintToken(clientIp ? null : buyerCountry)

    // A country code Xsolla does not recognise is a 422 — on v3 an opaque PayStation
    // exception naming no field. v3 also 422s when given neither country nor IP, so
    // the retry always supplies a country rather than dropping both.
    if (xResp.status === 422) {
      const retryCountry = clientIp ? buyerCountry : (buyerCountry === 'US' ? null : 'US')
      if (retryCountry) {
        console.warn('Xsolla 422 — retrying with country', retryCountry, ':', await xResp.text())
        xResp = await mintToken(retryCountry)
      }
    }

    if (!xResp.ok) {
      const errText = await xResp.text()
      console.error('Xsolla token API error:', errText)
      return new Response(
        JSON.stringify({ error: 'Payment service unavailable' }),
        { status: 502, headers: { ...cors, 'Content-Type': 'application/json' } }
      )
    }

    const xBody = await xResp.json()
    console.log('Xsolla token response body:', JSON.stringify(xBody))
    const { token, order_id } = xBody
    if (!token) {
      console.error('Xsolla returned no token:', JSON.stringify(xBody))
      return new Response(
        JSON.stringify({ error: 'No token from Xsolla', detail: xBody }),
        { status: 502, headers: { ...cors, 'Content-Type': 'application/json' } }
      )
    }
    return new Response(
      JSON.stringify({ token, order_id }),
      { headers: { ...cors, 'Content-Type': 'application/json' } }
    )

  } catch (e) {
    console.error('xsolla-token unhandled error:', e)
    return new Response(
      JSON.stringify({ error: 'Internal error' }),
      { status: 500, headers: { ...cors, 'Content-Type': 'application/json' } }
    )
  }
})
