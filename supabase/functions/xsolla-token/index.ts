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

    const { product_id } = await req.json()
    const product = PRODUCTS[product_id]
    if (!product) {
      return new Response('Unknown product', { status: 400, headers: cors })
    }

    // Fetch display name for PayStation UI
    const { data: profile } = await sb.from('profiles')
      .select('display_name').eq('id', user.id).maybeSingle()
    const displayName = profile?.display_name || user.email?.split('@')[0] || 'Player'

    const tokenPayload = {
      user: {
        id:    { value: user.id },
        email: { value: user.email },
        name:  { value: displayName },
      },
      settings: {
        project_id: parseInt(XSOLLA_PROJECT_ID),
        return_url: 'https://whambam.games',
        ui: { theme: 'dark' },
        ...(SANDBOX ? { mode: 'sandbox' } : {}),
      },
      purchase: {
        virtual_items: {
          items: [{ sku: product.sku, amount: 1 }]
        }
      }
    }

    const basicAuth = btoa(`${XSOLLA_MERCHANT_ID}:${XSOLLA_API_KEY}`)
    const xResp = await fetch(
      `https://api.xsolla.com/merchant/v2/merchants/${XSOLLA_MERCHANT_ID}/token`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Basic ${basicAuth}`,
          'Content-Type':  'application/json',
        },
        body: JSON.stringify(tokenPayload)
      }
    )

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
    const { token } = xBody
    if (!token) {
      console.error('Xsolla returned no token:', JSON.stringify(xBody))
      return new Response(
        JSON.stringify({ error: 'No token from Xsolla', detail: xBody }),
        { status: 502, headers: { ...cors, 'Content-Type': 'application/json' } }
      )
    }
    return new Response(
      JSON.stringify({ token }),
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
