import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const XSOLLA_SECRET  = Deno.env.get('XSOLLA_WEBHOOK_SECRET')!
const SB_URL         = Deno.env.get('SUPABASE_URL')!
const SB_SERVICE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!

const YEAR_MS = 365 * 24 * 60 * 60 * 1000

serve(async (req) => {
  if (req.method !== 'POST') return new Response('OK', { status: 200 })

  const body = await req.text()

  // Verify Xsolla signature: SHA1(body + project_secret_key)
  const authHeader  = req.headers.get('Authorization') ?? ''
  const receivedSig = authHeader.replace('Signature ', '').trim().toLowerCase()
  const expectedSig = await sha1hex(body + XSOLLA_SECRET)

  if (!timingSafeEqual(receivedSig, expectedSig)) {
    console.error('Xsolla webhook: signature mismatch — received:', receivedSig)
    return new Response(
      JSON.stringify({ error: { code: 'INVALID_SIGNATURE', message: 'Signature mismatch' } }),
      { status: 401, headers: { 'Content-Type': 'application/json' } }
    )
  }

  const data       = JSON.parse(body)
  const notifType  = data.notification_type as string

  // user_validation: user already verified by Supabase JWT at token generation time
  if (notifType === 'user_validation') {
    return new Response(null, { status: 204 })
  }

  // payment: real purchase completed
  if (notifType === 'payment') {
    // Store API v3 orders and legacy merchant purchases nest the sku differently.
    // Logged (purchase only — no user PII) so the real shape is on record.
    console.log('Xsolla payment purchase:', JSON.stringify(data.purchase))

    const userId = data.user?.id as string | undefined
    const sku    = (
      data.purchase?.virtual_items?.items?.[0]?.sku ??
      data.purchase?.items?.[0]?.sku ??
      data.items?.[0]?.sku
    ) as string | undefined

    if (!userId || !sku) {
      console.error('Xsolla webhook payment: missing user.id or sku', data)
      return new Response(
        JSON.stringify({ error: { code: 'MISSING_DATA', message: 'user.id or sku missing' } }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const subType   = sku === 'allaccess_yearly' ? 'allaccess' : 'standard'
    const expiresAt = new Date(Date.now() + YEAR_MS).toISOString()

    const sb = createClient(SB_URL, SB_SERVICE_KEY)
    const { error } = await sb.from('profiles').update({
      sub_type:       subType,
      sub_expires_at: expiresAt,
      sub_platform:   'xsolla',
      sub_product_id: sku,
    }).eq('id', userId)

    if (error) {
      console.error('Xsolla webhook: profile update failed', error)
      return new Response(
        JSON.stringify({ error: { code: 'DB_ERROR', message: error.message } }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    return new Response(null, { status: 204 })
  }

  // All other notification types — acknowledge and ignore
  return new Response(null, { status: 204 })
})

// Constant-time compare so a rejected caller cannot learn the signature byte by byte.
function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false
  let diff = 0
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i)
  return diff === 0
}

async function sha1hex(str: string): Promise<string> {
  const data   = new TextEncoder().encode(str)
  const buffer = await crypto.subtle.digest('SHA-1', data)
  return Array.from(new Uint8Array(buffer))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('')
}
