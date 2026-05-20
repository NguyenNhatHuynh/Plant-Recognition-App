import 'jsr:@supabase/functions-js/edge-runtime.d.ts'

import { createClient } from '@supabase/supabase-js'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

const prompt = `
Ban la chuyen gia nhan dien thuc vat.
Phan tich anh cay va tra ve CHI JSON hop le theo dung cau truc sau:
{
  "primary": {
    "common_name": "Ten pho thong bang tieng Viet",
    "aliases": ["Ten goi khac 1", "Ten goi khac 2"],
    "english_name": "Ten pho bien bang tieng Anh",
    "scientific_name": "Ten khoa hoc",
    "family": "Ho thuc vat",
    "description": "Mo ta ngan gon, de hieu, tap trung vao dac diem nhan dien cua cay",
    "habitat": "Moi truong song dien hinh",
    "light_requirement": "Yeu cau anh sang",
    "watering_needs": "Nhu cau tuoi nuoc",
    "care_level": "De, Trung binh hoac Kho",
    "suitable_temperature": "Khoang nhiet do thich hop",
    "soil_type": "Loai dat phu hop",
    "fertilizing_tips": "Meo bon phan ngan gon",
    "toxicity_warning": "Canh bao doc tinh voi tre em va thu cung",
    "uses": ["Ung dung 1", "Ung dung 2"],
    "maximum_size": "Kich thuoc toi da khi truong thanh",
    "feng_shui_meaning": "Y nghia phong thuy neu co",
    "origin": "Nguon goc xuat xu",
    "common_issues": "Dau hieu benh hoac van de thuong gap",
    "confidence": 0.0
  },
  "alternatives": [
    {
      "common_name": "Ten pho thong",
      "aliases": ["Ten goi khac"],
      "english_name": "Ten tieng Anh",
      "scientific_name": "Ten khoa hoc",
      "family": "Ho thuc vat",
      "description": "Mo ta ngan",
      "habitat": "Moi truong song",
      "light_requirement": "Yeu cau anh sang",
      "watering_needs": "Nhu cau tuoi nuoc",
      "care_level": "Do kho cham soc",
      "suitable_temperature": "Khoang nhiet do",
      "soil_type": "Loai dat",
      "fertilizing_tips": "Meo bon phan",
      "toxicity_warning": "Canh bao doc tinh",
      "uses": ["Ung dung"],
      "maximum_size": "Kich thuoc toi da",
      "feng_shui_meaning": "Y nghia phong thuy",
      "origin": "Nguon goc",
      "common_issues": "Van de thuong gap",
      "confidence": 0.0
    }
  ],
  "analysis_note": "Nhan xet ngan ve muc do chac chan hoac dau hieu nhan dien"
}

Quy tac:
- Tra ve tieng Viet cho common_name, aliases, description, habitat, light_requirement, watering_needs, care_level, suitable_temperature, soil_type, fertilizing_tips, toxicity_warning, uses, maximum_size, feng_shui_meaning, origin, common_issues, analysis_note.
- english_name la ten pho bien quoc te neu biet, khong thi de chuoi rong.
- scientific_name phai la ten Latin chuan neu biet.
- aliases la cac ten goi dia phuong, ten goi cu, hoac ten thuong mai pho bien; neu khong co thi tra ve [].
- care_level chi nhan mot trong ba gia tri: "De", "Trung binh", "Kho" neu co du lieu.
- confidence nam trong khoang 0.0 den 1.0.
- Neu khong chac chan, van chon loai gan nhat va giam confidence.
- Neu khong nhan ra ro, van tra dung JSON va de confidence thap.
- Khong duoc tra markdown, khong duoc them van ban ngoai JSON.
`.trim()

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY') ?? ''
const supabaseServiceRoleKey =
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
const geminiApiKey = Deno.env.get('GEMINI_API_KEY') ?? ''
const dailyLimit = Number(Deno.env.get('DAILY_RECOGNITION_LIMIT') ?? '15')

function jsonResponse(status: number, body: Record<string, unknown>) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders,
      'Content-Type': 'application/json',
    },
  })
}

function stripCodeFences(input: string) {
  const trimmed = input.trim()
  if (!trimmed.startsWith('```')) {
    return trimmed
  }

  const lines = trimmed.split('\n')
  if (lines.length < 3) {
    return trimmed
  }

  return lines.slice(1, -1).join('\n').trim()
}

function extractGeminiText(payload: Record<string, unknown>) {
  const candidates = payload.candidates
  if (!Array.isArray(candidates) || candidates.length === 0) {
    return null
  }

  const first = candidates[0]
  if (!first || typeof first !== 'object') {
    return null
  }

  const content = (first as Record<string, unknown>).content
  if (!content || typeof content !== 'object') {
    return null
  }

  const parts = (content as Record<string, unknown>).parts
  if (!Array.isArray(parts)) {
    return null
  }

  return parts
    .map((part) => {
      if (!part || typeof part !== 'object') {
        return ''
      }
      const text = (part as Record<string, unknown>).text
      return typeof text === 'string' ? text : ''
    })
    .join('')
}

function extractGeminiErrorMessage(payload: unknown) {
  if (!payload || typeof payload !== 'object') {
    return 'Gemini request failed.'
  }

  const error = (payload as Record<string, unknown>).error
  if (!error || typeof error !== 'object') {
    return 'Gemini request failed.'
  }

  const message = (error as Record<string, unknown>).message
  return typeof message === 'string' && message.trim().length > 0
    ? message
    : 'Gemini request failed.'
}

Deno.serve(async (request: Request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  if (request.method !== 'POST') {
    return jsonResponse(405, { error: 'Method not allowed.' })
  }

  if (
    !supabaseUrl ||
    !supabaseAnonKey ||
    !supabaseServiceRoleKey ||
    !geminiApiKey
  ) {
    return jsonResponse(500, {
      error:
        'Missing server configuration. Check SUPABASE_URL, SUPABASE_ANON_KEY, SUPABASE_SERVICE_ROLE_KEY, and GEMINI_API_KEY.',
    })
  }

  const authHeader = request.headers.get('Authorization') ?? ''
  if (!authHeader.startsWith('Bearer ')) {
    return jsonResponse(401, { error: 'Missing bearer token.' })
  }

  const accessToken = authHeader.replace('Bearer ', '').trim()
  if (!accessToken) {
    return jsonResponse(401, { error: 'Invalid bearer token.' })
  }

  const userClient = createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  })

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey)

  const {
    data: { user },
    error: userError,
  } = await userClient.auth.getUser(accessToken)

  if (userError || !user) {
    return jsonResponse(401, { error: 'User session is invalid or expired.' })
  }

  let requestBody: Record<string, unknown>
  try {
    requestBody = await request.json()
  } catch (_) {
    return jsonResponse(400, { error: 'Request body must be valid JSON.' })
  }

  const mimeType = String(requestBody.mime_type ?? '').trim()
  const imageBase64 = String(requestBody.image_base64 ?? '').trim()

  if (!mimeType || !imageBase64) {
    return jsonResponse(400, {
      error: 'mime_type and image_base64 are required.',
    })
  }

  const { data: quotaData, error: quotaError } = await userClient.rpc(
    'consume_recognition_daily_quota',
    {
      p_user_id: user.id,
      p_daily_limit: dailyLimit,
    },
  )

  if (quotaError) {
    return jsonResponse(500, {
      error: 'Could not validate daily quota.',
      details: quotaError.message,
    })
  }

  const quotaRow = Array.isArray(quotaData) ? quotaData[0] : quotaData
  const allowed = Boolean(quotaRow?.allowed)
  const usedCount = Number(quotaRow?.used_count ?? 0)
  const remainingCount = Number(quotaRow?.remaining_count ?? 0)

  if (!allowed) {
    return jsonResponse(429, {
      error: `Daily recognition limit reached (${usedCount}/${dailyLimit}).`,
      code: 'daily_quota_exceeded',
      quota: {
        limit: dailyLimit,
        used: usedCount,
        remaining: remainingCount,
      },
    })
  }

  const geminiUrl =
    `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${encodeURIComponent(geminiApiKey)}`

  const geminiResponse = await fetch(geminiUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [
            {
              inline_data: {
                mime_type: mimeType,
                data: imageBase64,
              },
            },
            { text: prompt },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.2,
        max_output_tokens: 5000,
        response_mime_type: 'application/json',
      },
    }),
  })

  const geminiPayload = await geminiResponse.json().catch(() => null)

  if (!geminiResponse.ok || !geminiPayload) {
    return jsonResponse(geminiResponse.status || 502, {
      error: extractGeminiErrorMessage(geminiPayload),
    })
  }

  const rawText = extractGeminiText(geminiPayload)
  if (!rawText) {
    return jsonResponse(502, {
      error: 'Gemini response did not contain text content.',
    })
  }

  let result: Record<string, unknown>
  try {
    result = JSON.parse(stripCodeFences(rawText))
  } catch (_) {
    return jsonResponse(502, {
      error: 'Gemini response was not valid JSON.',
      raw_text: rawText,
    })
  }

  return jsonResponse(200, {
    result,
    quota: {
      limit: dailyLimit,
      used: usedCount,
      remaining: remainingCount,
    },
  })
})
